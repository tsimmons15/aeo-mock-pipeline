import argparse
import logging

import apache_beam as beam
from apache_beam.metrics import Metrics
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.io import ReadFromText
from apache_beam.io.gcp.bigquery import WriteToBigQuery, BigQueryDisposition

from transformations.parse import ParseJsonLine
from transformations.validate import ValidateBatchRecord
from transformations.conform import ConformBatchRecord
from transformations.deadletter import FormatDeadLetter


DATASET_TABLE_MAP = {
    "orders":              "stg_orders",
    "returns":             "stg_returns",
    "inventory_snapshots": "stg_inventory_snapshots",
    "product":             "stg_product"
}

NAMESPACE = "batch_ingestion"


class CountRows(beam.DoFn):
    """Passthrough DoFn that increments a named Beam counter for each element."""

    def __init__(self, metric_name: str, dataset: str):
        self._counter = Metrics.counter(NAMESPACE, f"{dataset}.{metric_name}")

    def process(self, element):
        self._counter.inc()
        yield element


def run(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--project",          required=True)
    parser.add_argument("--input_prefix",     required=True,
                        help="GCS prefix, e.g. gs://aeo-raw-landing-data/raw/aeo")
    parser.add_argument("--dataset",          required=True,
                        help="Single dataset name, e.g. orders")
    parser.add_argument("--bq_dataset",       default="retail")
    parser.add_argument("--deadletter_table", required=True)
    known_args, pipeline_args = parser.parse_known_args(argv)

    dataset = known_args.dataset.strip()

    if dataset not in DATASET_TABLE_MAP:
        raise ValueError(
            f"Unknown dataset '{dataset}'. "
            f"Valid options: {sorted(DATASET_TABLE_MAP)}"
        )

    options = PipelineOptions(pipeline_args)

    gcs_glob = (
        f"{known_args.input_prefix.rstrip('/')}"
        f"/dataset={dataset}/**/*.jsonl"
    )
    bq_table = (
        f"{known_args.project}"
        f":{known_args.bq_dataset}"
        f".{DATASET_TABLE_MAP[dataset]}"
    )
    deadletter_table = f"{known_args.project}:{known_args.deadletter_table}"

    with beam.Pipeline(options=options) as p:

        raw_lines = (
            p
            | "Read" >> ReadFromText(gcs_glob)
            | "CountRead" >> beam.ParDo(CountRows("rows_read", dataset))
        )

        parsed, dead_parse = (
            raw_lines
            | "Parse" >> beam.ParDo(
                ParseJsonLine(dataset=dataset)
            ).with_outputs("dead", main="parsed")
        )

        validated, dead_validate = (
            parsed
            | "Validate" >> beam.ParDo(
                ValidateBatchRecord(dataset=dataset)
            ).with_outputs("dead", main="validated")
        )

        conformed = (
            validated
            | "Conform" >> beam.ParDo(ConformBatchRecord(dataset=dataset))
        )

        (
            (dead_parse, dead_validate)
            | "MergeDead"  >> beam.Flatten()
            | "FormatDead" >> beam.ParDo(FormatDeadLetter(pipeline="batch", dataset=dataset))
            | "CountDead"  >> beam.ParDo(CountRows("deadletter_written", dataset))
            | "WriteDead"  >> WriteToBigQuery(
                table=deadletter_table,
                create_disposition=BigQueryDisposition.CREATE_NEVER,
                write_disposition=BigQueryDisposition.WRITE_APPEND,
            )
        )

        (
            conformed
            | "CountWritten" >> beam.ParDo(CountRows("rows_written", dataset))
            | "WriteBQ"      >> WriteToBigQuery(
                table=bq_table,
                create_disposition=BigQueryDisposition.CREATE_NEVER,
                write_disposition=BigQueryDisposition.WRITE_APPEND,
            )
        )


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()