import argparse
import logging

import apache_beam as beam
from apache_beam.metrics import Metrics
from apache_beam.options.pipeline_options import PipelineOptions, StandardOptions
from apache_beam.io.gcp.pubsub import ReadFromPubSub
from apache_beam.io.gcp.bigquery import WriteToBigQuery, BigQueryDisposition

from transformations.parse import ParseJsonMessage
from transformations.validate import ValidateEventSchema
from transformations.conform import FlattenStreamEvent
from transformations.deadletter import FormatDeadLetter


# Event types this job handles, and their target BQ tables.
# Passed in via --event_group; resolved here at startup.
EVENT_GROUP_MAP = {
    "browse": {
        "page_view":     "stg_page_views",
        "product_view":  "stg_product_views",
    },
    "cart": {
        "add_to_cart":      "stg_cart_events",
        "remove_from_cart": "stg_cart_events",
    },
    "commerce": {
        "checkout_started":   "stg_checkout_events",
        "purchase_completed": "stg_purchases",
    },
    "returns": {
        "return_initiated": "stg_returns",
    },
    "inventory": {
        "inventory_adjustment": "stg_inventory_adjustments",
    },
}

NAMESPACE = "stream_ingestion"


class CountMessages(beam.DoFn):
    """Passthrough DoFn that increments a named Beam counter per element."""

    def __init__(self, metric_name: str, event_group: str):
        self._counter = Metrics.counter(NAMESPACE, f"{event_group}.{metric_name}")

    def process(self, element):
        self._counter.inc()
        yield element


def run(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--project",          required=True)
    parser.add_argument("--subscription",     required=True,
                        help="PubSub subscription ID (not full path)")
    parser.add_argument("--event_group",      required=True,
                        help=f"Event group to process. One of: {sorted(EVENT_GROUP_MAP)}")
    parser.add_argument("--bq_dataset",       default="retail_staging")
    parser.add_argument("--deadletter_table", required=True)
    known_args, pipeline_args = parser.parse_known_args(argv)

    event_group = known_args.event_group.strip()

    if event_group not in EVENT_GROUP_MAP:
        raise ValueError(
            f"Unknown event_group '{event_group}'. "
            f"Valid options: {sorted(EVENT_GROUP_MAP)}"
        )

    event_tables = EVENT_GROUP_MAP[event_group]
    subscription_path = (
        f"projects/{known_args.project}"
        f"/subscriptions/{known_args.subscription}"
    )
    deadletter_table = f"{known_args.project}:{known_args.deadletter_table}"

    options = PipelineOptions(pipeline_args)
    options.view_as(StandardOptions).streaming = True

    with beam.Pipeline(options=options) as p:

        raw = (
            p
            | "ReadPubSub" >> ReadFromPubSub(
                subscription=subscription_path,
                with_attributes=True,
            )
            | "CountRead" >> beam.ParDo(CountMessages("messages_read", event_group))
        )

        parsed, dead_parse = (
            raw
            | "ParseJSON" >> beam.ParDo(
                ParseJsonMessage()
            ).with_outputs("dead", main="parsed")
        )

        validated, dead_validate = (
            parsed
            | "ValidateSchema" >> beam.ParDo(
                ValidateEventSchema(valid_event_types=set(event_tables.keys()))
            ).with_outputs("dead", main="validated")
        )

        conformed = (
            validated
            | "ConformSchema" >> beam.ParDo(FlattenStreamEvent())
        )

        for event_type, table_name in event_tables.items():
            bq_table = (
                f"{known_args.project}"
                f":{known_args.bq_dataset}"
                f".{table_name}"
            )
            (
                conformed
                | f"Filter_{event_type}" >> beam.Filter(
                    lambda r, et=event_type: r.get("event_type") == et
                )
                | f"CountWritten_{event_type}" >> beam.ParDo(
                    CountMessages(f"rows_written.{event_type}", event_group)
                )
                | f"WriteBQ_{event_type}" >> WriteToBigQuery(
                    table=bq_table,
                    create_disposition=BigQueryDisposition.CREATE_NEVER,
                    write_disposition=BigQueryDisposition.WRITE_APPEND,
                )
            )

        (
            (dead_parse, dead_validate)
            | "MergeDeadLetter"  >> beam.Flatten()
            | "FormatDeadLetter" >> beam.ParDo(FormatDeadLetter())
            | "CountDead"        >> beam.ParDo(CountMessages("deadletter_written", event_group))
            | "WriteDeadLetter"  >> WriteToBigQuery(
                table=deadletter_table,
                create_disposition=BigQueryDisposition.CREATE_NEVER,
                write_disposition=BigQueryDisposition.WRITE_APPEND,
            )
        )


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()