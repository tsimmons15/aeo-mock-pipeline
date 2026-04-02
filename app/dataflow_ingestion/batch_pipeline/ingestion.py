import argparse
import json
import logging

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.io import ReadFromText
from apache_beam.io.gcp.bigquery import WriteToBigQuery, BigQueryDisposition

from transformations.parse import ParseJsonLine
from transformations.validate import ValidateBatchRecord
from transformations.conform import ConformBatchRecord
from transformations.deadletter import FormatDeadLetter

DATASET_TABLE_MAP = {
    "orders":               "orders",
    "returns":              "returns",
    "inventory_snapshots":  "inventory_snapshots",
    "product_dim":          "product_dim",
}

def run(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--project",          required=True)
    parser.add_argument("--input_prefix",     required=True,
                        help="GCS prefix, e.g. gs://aeo-raw-landing-data/raw/aeo")
    parser.add_argument("--bq_dataset",       default="retail")
    parser.add_argument("--deadletter_table", required=True)
    parser.add_argument("--datasets",         default="orders,returns,inventory_snapshots,product_dim")
    known_args, pipeline_args = parser.parse_known_args(argv)

    datasets = [d.strip() for d in known_args.datasets.split(",")]
    options = PipelineOptions(pipeline_args)

    with beam.Pipeline(options=options) as p:

        for dataset in datasets:
            # Glob only .jsonl files — skips .manifest.json files written by the mock
            gcs_glob = f"{known_args.input_prefix.rstrip('/')}/dataset={dataset}/**/*.jsonl"

            raw_lines = (
                p
                | f"Read_{dataset}" >> ReadFromText(gcs_glob)
            )

            parsed, dead_parse = (
                raw_lines
                | f"Parse_{dataset}" >> beam.ParDo(
                    ParseJsonLine(dataset=dataset)
                ).with_outputs("dead", main="parsed")
            )

            validated, dead_validate = (
                parsed
                | f"Validate_{dataset}" >> beam.ParDo(
                    ValidateBatchRecord(dataset=dataset)
                ).with_outputs("dead", main="validated")
            )

            conformed = (
                validated
                | f"Conform_{dataset}" >> beam.ParDo(ConformBatchRecord(dataset=dataset))
            )

            (
                (dead_parse, dead_validate)
                | f"MergeDead_{dataset}"   >> beam.Flatten()
                | f"FormatDead_{dataset}"  >> beam.ParDo(FormatDeadLetter(dataset=dataset))
                | f"WriteDead_{dataset}"   >> WriteToBigQuery(
                    table=f"{known_args.project}:{known_args.deadletter_table}",
                    create_disposition=BigQueryDisposition.CREATE_NEVER,
                    write_disposition=BigQueryDisposition.WRITE_APPEND,
                )
            )

            table = DATASET_TABLE_MAP[dataset]
            (
                conformed
                | f"WriteBQ_{dataset}" >> WriteToBigQuery(
                    table=f"{known_args.project}:{known_args.bq_dataset}.{table}",
                    create_disposition=BigQueryDisposition.CREATE_NEVER,
                    write_disposition=BigQueryDisposition.WRITE_APPEND,
                )
            )

            if dataset not in DATASET_TABLE_MAP:
                logging.warning("Unknown dataset %s, skipping", dataset)
                continue

if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()