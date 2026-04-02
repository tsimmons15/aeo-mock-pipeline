import argparse
import json
import logging

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, StandardOptions
from apache_beam.io.gcp.pubsub import ReadFromPubSub
from apache_beam.io.gcp.bigquery import WriteToBigQuery, BigQueryDisposition

from transformations.parse import ParseJsonMessage
from transformations.validate import ValidateEventSchema
from transformations.conform import FlattenStreamEvent
from transformations.deadletter import FormatDeadLetter

EVENT_TABLES = {
    "page_view":            "page_views",
    "product_view":         "product_views",
    "add_to_cart":          "cart_events",
    "remove_from_cart":     "cart_events",
    "checkout_started":     "checkout_events",
    "purchase_completed":   "purchases",
    "return_initiated":     "returns",
    "inventory_adjustment": "inventory_adjustments",
}

def run(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--project",       required=True)
    parser.add_argument("--subscription",  required=True)
    parser.add_argument("--bq_dataset",    default="events")
    parser.add_argument("--deadletter_table", required=True)
    known_args, pipeline_args = parser.parse_known_args(argv)

    options = PipelineOptions(pipeline_args)
    options.view_as(StandardOptions).streaming = True

    with beam.Pipeline(options=options) as p:

        # Read raw PubSub messages with attributes
        raw = (
            p
            | "ReadPubSub" >> ReadFromPubSub(
                subscription=f"projects/{known_args.project}/subscriptions/{known_args.subscription}",
                with_attributes=True         # gives us .attributes dict + .data bytes
            )
        )

        # Parse JSON, tag failures to dead letter
        parsed, dead_parse = (
            raw
            | "ParseJSON" >> beam.ParDo(ParseJsonMessage()).with_outputs("dead", main="parsed")
        )

        # Validate required fields per event_type, tag schema violations
        validated, dead_validate = (
            parsed
            | "ValidateSchema" >> beam.ParDo(ValidateEventSchema()).with_outputs("dead", main="validated")
        )

        # Flatten nested sub-objects into BQ-friendly structs per event type
        conformed = (
            validated
            | "ConformSchema" >> beam.ParDo(FlattenStreamEvent())
        )

        # Fan out to per-event-type BigQuery tables
        for event_type, table_dest in EVENT_TABLES.items():
            (
                conformed
                | f"Filter_{event_type}" >> beam.Filter(lambda r, et=event_type: r.get("event_type") == et)
                | f"WriteBQ_{event_type}" >> WriteToBigQuery(
                    table=f"{known_args.project}:{known_args.bq_dataset}.{table_dest}",
                    create_disposition=BigQueryDisposition.CREATE_NEVER,
                    write_disposition=BigQueryDisposition.WRITE_APPEND,
                )
            )

        # Dead letter sink — union both failure branches
        (
            (dead_parse, dead_validate)
            | "MergeDeadLetter" >> beam.Flatten()
            | "FormatDeadLetter" >> beam.ParDo(FormatDeadLetter())
            | "WriteDeadLetter" >> WriteToBigQuery(
                table=f"{known_args.project}:{known_args.deadletter_table}",
                create_disposition=BigQueryDisposition.CREATE_NEVER,
                write_disposition=BigQueryDisposition.WRITE_APPEND,
            )
        )

if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()