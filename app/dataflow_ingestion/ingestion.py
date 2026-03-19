import json
import logging
from typing import Iterable

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions


class DemoOptions(PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_value_provider_argument(
            "--input",
            help="Input path, for example gs://my-bucket/input/events.jsonl or local file path"
        )
        parser.add_value_provider_argument(
            "--output",
            help="Output prefix, for example gs://my-bucket/output/event_counts"
        )
        parser.add_argument("--min_amount", type=float, default=0.0)

def is_valid_purchase(record: dict, min_amount: float) -> bool:
    return (
        record.get("event_type") == "purchase"
        and "amount" in record
        and float(record["amount"]) >= min_amount
    )


def to_event_kv(record: dict):
    country = record.get("country", "UNKNOWN")
    return country, 1


def format_output(kv):
    country, count = kv
    return json.dumps({"country": country, "purchase_count": count})

from apache_beam.metrics import Metrics

class LogRawLinesDoFn(beam.DoFn):
    def __init__(self):
        self.lines = Metrics.counter(self.__class__, "raw_lines")
        self.bad_json = Metrics.counter(self.__class__, "bad_json")

    def setup(self):
        logging.info("LogRawLinesDoFn started")

    def process(self, element):
        self.lines.inc()
        logging.info("RAW LINE: %s", element[:300])
        yield element

class ParseJsonDoFn(beam.DoFn):
    def __init__(self):
        self.parsed = Metrics.counter(self.__class__, "parsed_json")
        self.bad_json = Metrics.counter(self.__class__, "bad_json")

    def process(self, element: str) -> Iterable[dict]:
        try:
            record = json.loads(element)
            self.parsed.inc()
            yield record
        except Exception:
            self.bad_json.inc()
            logging.warning("Skipping bad JSON line: %s", element[:200])


def run():
    options = DemoOptions()
    custom = options.view_as(DemoOptions)

    logging.info("""Running pipeline with options:
    \tInput: %s
    \tOutput: %s
    \tMinimum amount: %f""", 
        custom.input, 
        custom.output, 
        custom.min_amount
    )

    with beam.Pipeline(options=options) as p:
        formatted_output = (
            p
            | "ReadInput" >> beam.io.ReadFromText(custom.input)
            | "LogRawLines" >> beam.ParDo(LogRawLinesDoFn())
            | "ParseJson" >> beam.ParDo(ParseJsonDoFn())
            | "FilterPurchases" >> beam.Filter(is_valid_purchase, custom.min_amount)
            | "ToCountryKV" >> beam.Map(to_event_kv)
            | "CountPerCountry" >> beam.CombinePerKey(sum)
            | "FormatOutput" >> beam.Map(format_output)
        )

        output_count = (
            formatted_output
            | "CountFormattedRows" >> beam.combiners.Count.Globally()
        )

        fallback_output = (
            output_count
            | "EmitFallbackIfEmpty" >> beam.FlatMap(
                lambda n: [format_empty_output(None)] if n == 0 else []
            )
        )

        final_output = (
            (formatted_output, fallback_output)
            | "MergeRealAndFallbackOutput" >> beam.Flatten()
        )

        final_output | "WriteOutput" >> beam.io.WriteToText(
            custom.output,
            file_name_suffix=".jsonl",
            shard_name_template="-SSSSS-of-NNNNN",
        )



if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()
