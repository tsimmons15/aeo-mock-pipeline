import logging
import apache_beam as beam

# Required top-level fields every streaming event must have
_STREAM_BASE_REQUIRED = {
    "event_id", "event_type", "brand", "event_time",
    "ingest_time", "session_id", "schema_version", "context",
}

# Additional required fields per event_type
_STREAM_EVENT_REQUIRED = {
    "purchase_completed":   {"order", "customer"},
    "return_initiated":     {"return", "customer"},
    "checkout_started":     {"customer"},
    "inventory_adjustment": {"inventory"},
    "product_view":         {"product"},
    "add_to_cart":          {"product"},
    "remove_from_cart":     {"product"},
    "page_view":            {"page"},
}

# Required fields per batch dataset
_BATCH_REQUIRED = {
    "orders": {
        "order_id", "brand", "order_time", "ingest_time",
        "channel", "customer", "items", "totals", "schema_version",
    },
    "returns": {
        "return_id", "original_order_id", "brand", "return_time",
        "ingest_time", "reason", "resolution", "sku", "qty",
        "refund_amount", "currency", "schema_version",
    },
    "inventory_snapshots": {
        "snapshot_time", "ingest_time", "store_id", "sku",
        "on_hand", "on_order", "reserved", "schema_version",
    },
    "product_dim": {
        "sku", "brand", "dept", "category", "name",
        "base_price", "effective_time", "ingest_time", "schema_version",
    },
}


class ValidateEventSchema(beam.DoFn):
    """Streaming: validate base fields and event-type-conditional fields.

    Args:
        valid_event_types: If provided, events whose event_type is not in this
                           set are routed to dead letter. Allows each per-group
                           job to reject events that leaked past the PubSub
                           subscription filter.
    """

    def __init__(self, valid_event_types: set = None):
        self._valid_event_types = valid_event_types

    def process(self, record):
        missing = _STREAM_BASE_REQUIRED - record.keys()
        if missing:
            yield beam.pvalue.TaggedOutput("dead", {
                "raw":   record,
                "error": f"Missing base fields: {missing}",
                "stage": "validate",
            })
            return

        event_type = record.get("event_type")

        if self._valid_event_types and event_type not in self._valid_event_types:
            yield beam.pvalue.TaggedOutput("dead", {
                "raw":   record,
                "error": f"Unexpected event_type '{event_type}' for this job",
                "stage": "validate",
            })
            return

        extra_required = _STREAM_EVENT_REQUIRED.get(event_type, set())
        missing_extra = extra_required - record.keys()
        if missing_extra:
            yield beam.pvalue.TaggedOutput("dead", {
                "raw":   record,
                "error": f"Missing fields for {event_type}: {missing_extra}",
                "stage": "validate",
            })
            return

        yield record


class ValidateBatchRecord(beam.DoFn):
    """Batch: validate required fields for a specific dataset."""

    def __init__(self, dataset: str):
        self.dataset = dataset
        self._required = _BATCH_REQUIRED.get(dataset, set())

    def process(self, record):
        missing = self._required - record.keys()
        if missing:
            yield beam.pvalue.TaggedOutput("dead", {
                "raw": record,
                "error": f"Missing fields for {self.dataset}: {missing}",
                "stage": "validate",
                "dataset": self.dataset,
            })
            return
        yield record