import json
import logging
import apache_beam as beam


class ParseJsonMessage(beam.DoFn):
    """Streaming: decode PubSub message bytes and merge attributes onto the dict."""

    def process(self, message):
        try:
            record = json.loads(message.data.decode("utf-8"))
            # Merge PubSub attributes — event_type, brand, schema_version, source
            record["_attributes"] = dict(message.attributes)
            yield record
        except Exception as e:
            logging.error("ParseJsonMessage failed: %s", e)
            yield beam.pvalue.TaggedOutput("dead", {
                "raw": message.data.decode("utf-8", errors="replace"),
                "error": str(e),
                "stage": "parse",
            })


class ParseJsonLine(beam.DoFn):
    """Batch: parse a raw JSONL text line."""

    def __init__(self, dataset: str):
        self.dataset = dataset

    def process(self, line):
        line = line.strip()
        if not line:
            return
        try:
            record = json.loads(line)
            record["_dataset"] = self.dataset
            yield record
        except Exception as e:
            logging.error("ParseJsonLine failed [%s]: %s", self.dataset, e)
            yield beam.pvalue.TaggedOutput("dead", {
                "raw": line,
                "error": str(e),
                "stage": "parse",
                "dataset": self.dataset,
            })