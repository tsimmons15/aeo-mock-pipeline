import logging
import apache_beam as beam


def _safe_str(val) -> str:
    return str(val).strip() if val is not None else None


class FlattenStreamEvent(beam.DoFn):

    def process(self, record):
        out = {
            "event_id":      record.get("event_id"),
            "event_type":    record.get("event_type"),
            "brand":         record.get("brand"),
            "schema_version": record.get("schema_version"),
            "event_time":    record.get("event_time"),
            "ingest_time":   record.get("ingest_time"),
            "session_id":    record.get("session_id"),
            "request_id":    record.get("request_id"),
        }

        # context — flatten geo and store sub-objects
        ctx = record.get("context") or {}
        geo = ctx.get("geo") or {}
        store = ctx.get("store") or {}
        out["channel"]          = ctx.get("channel")
        out["device_type"]      = ctx.get("device_type")
        out["marketing_source"] = ctx.get("marketing_source")
        out["geo_city"]         = geo.get("city")
        out["geo_state"]        = geo.get("state")
        out["geo_country"]      = geo.get("country")
        out["store_id"]         = store.get("store_id")
        out["store_city"]       = store.get("city")
        out["store_state"]      = store.get("state")
        out["store_type"]       = store.get("store_type")

        # page (page_view, product_view)
        page = record.get("page") or {}
        out["page_url_path"] = page.get("url_path")
        out["page_referrer"] = page.get("referrer")

        # product (product_view, add_to_cart, remove_from_cart)
        product = record.get("product") or {}
        out["product_sku"]      = product.get("sku")
        out["product_dept"]     = product.get("dept")
        out["product_category"] = product.get("category")
        out["product_price"]    = product.get("price")

        # customer (checkout_started, purchase_completed, return_initiated)
        customer = record.get("customer") or {}
        ship_to  = customer.get("ship_to") or {}
        out["customer_id"]       = customer.get("customer_id")
        out["loyalty_id"]        = customer.get("loyalty_id")    # nullable per mock
        out["email_hash_b64"]    = customer.get("email_hash_b64")
        out["ship_city"]         = ship_to.get("city")
        out["ship_state"]        = ship_to.get("state")
        out["ship_country"]      = ship_to.get("country")
        out["ship_postal3"]      = ship_to.get("postal3")

        # order (purchase_completed)
        order  = record.get("order") or {}
        totals = order.get("totals") or {}
        out["order_id"]       = order.get("order_id")
        out["ship_method"]    = order.get("ship_method")
        out["payment_type"]   = order.get("payment_type")
        out["is_bopis"]       = order.get("is_bopis")
        out["order_subtotal"] = totals.get("subtotal")
        out["order_discount"] = totals.get("discount_total")
        out["order_tax"]      = totals.get("tax")
        out["order_shipping"] = totals.get("shipping")
        out["order_total"]    = totals.get("total")
        # line items written as a repeated RECORD in BQ
        out["items"] = order.get("items") or []

        # return (return_initiated)
        ret = record.get("return") or {}
        out["return_id"]          = ret.get("return_id")
        out["return_order_id"]    = ret.get("original_order_id")
        out["return_reason"]      = ret.get("reason")
        out["return_resolution"]  = ret.get("resolution")

        # inventory (inventory_adjustment)
        inv = record.get("inventory") or {}
        out["inv_store_id"] = inv.get("store_id")
        out["inv_sku"]      = inv.get("sku")
        out["inv_delta"]    = inv.get("delta")
        out["inv_reason"]   = inv.get("reason")

        yield out


class ConformBatchRecord(beam.DoFn):

    def __init__(self, dataset: str):
        self.dataset = dataset

    def process(self, record):
        out = dict(record)

        # Normalize loyalty_id null — present in orders via customer sub-object
        customer = out.get("customer") or {}
        if customer:
            ship_to = customer.get("ship_to") or {}
            out["customer_id"]    = customer.get("customer_id")
            out["loyalty_id"]     = customer.get("loyalty_id")   # nullable
            out["email_hash_b64"] = customer.get("email_hash_b64")
            out["ship_city"]      = ship_to.get("city")
            out["ship_state"]     = ship_to.get("state")
            out["ship_country"]   = ship_to.get("country")
            out["ship_postal3"]   = ship_to.get("postal3")
            del out["customer"]

        # store_id is nullable in orders and returns per mock
        if "store_id" not in out:
            out["store_id"] = None

        # Remove internal routing key before BQ write
        out.pop("_dataset", None)

        yield out