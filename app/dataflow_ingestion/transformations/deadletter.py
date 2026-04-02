import json
import logging
from datetime import datetime, timezone

import apache_beam as beam


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _safe_serialize(val) -> str:
    if isinstance(val, str):
        return val
    try:
        return json.dumps(val, default=str)
    except Exception:
        return str(val)


class FormatDeadLetter(beam.DoFn):
    """
    Formats failed records into a consistent dead letter schema
    for both streaming and batch pipelines.

    BQ dead letter table schema:
        ingest_time     TIMESTAMP
        pipeline        STRING      -- 'streaming' or 'batch'
        stage           STRING      -- 'parse' | 'validate'
        dataset         STRING      -- batch dataset name or streaming event_type (if recoverable)
        error           STRING
        raw_payload     STRING      -- JSON string of the original record or raw line
    """

    def __init__(self, pipeline: str = "streaming", dataset: str = None):
        self.pipeline = pipeline
        self.dataset  = dataset   # batch passes dataset name; streaming leaves None

    def process(self, record):
        raw = record.get("raw", "")
        event_type = None

        # For streaming failures that made it past parse, extract event_type if present
        if isinstance(raw, dict):
            event_type = raw.get("event_type")

        yield {
            "ingest_time": _utc_now_iso(),
            "pipeline":    self.pipeline,
            "stage":       record.get("stage", "unknown"),
            "dataset":     self.dataset or event_type or "unparsable_event",
            "error":       _safe_serialize(record.get("error")),
            "raw_payload": _safe_serialize(raw),
        }