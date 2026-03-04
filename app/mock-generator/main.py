import logging, traceback, base64,dataclasses,gzip,io,json,os,random,string,time
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple

import functions_framework
from flask import jsonify

from google.cloud import pubsub_v1
from google.cloud import storage


logger = logging.getLogger("aeo_mock")
if not logger.handlers:
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

# ----------------------------
# Helpers (env + parsing)
# ----------------------------
def _env(name: str, default: Optional[str] = None) -> Optional[str]:
    v = os.getenv(name)
    return v if v is not None and v != "" else default

def _env_int(name: str, default: int) -> int:
    v = _env(name)
    return int(v) if v is not None else default

def _env_float(name: str, default: float) -> float:
    v = _env(name)
    return float(v) if v is not None else default

def _env_bool(name: str, default: bool) -> bool:
    v = _env(name)
    if v is None:
        return default
    return v.strip().lower() in ("1", "true", "t", "yes", "y", "on")

def _split_csv(s: str) -> List[str]:
    return [x.strip() for x in (s or "").split(",") if x.strip()]

def _get_req_json(request) -> dict:
    try:
        return request.get_json(silent=True) or {}
    except Exception:
        return {}

def _pick(d: dict, key: str, default=None):
    if d is None:
        return default
    v = d.get(key, None)
    return default if v is None else v

def _pick_qp(request, key: str) -> Optional[str]:
    try:
        return request.args.get(key)
    except Exception:
        return None

def _coalesce(*vals):
    for v in vals:
        if v is not None and v != "":
            return v
    return None

def utc_now() -> datetime:
    return datetime.now(timezone.utc)

def iso_z(dt: datetime) -> str:
    s = dt.astimezone(timezone.utc).isoformat()
    return s.replace("+00:00", "Z")

def iso_filename_ts(dt: datetime) -> str:
    # filesystem-safe ISO-ish (no colons)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")

def safe_json_dumps(obj: dict) -> str:
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False)

def rand_id(prefix: str, n: int = 12) -> str:
    alphabet = string.ascii_lowercase + string.digits
    return f"{prefix}_{''.join(random.choice(alphabet) for _ in range(n))}"

def money(x: float) -> float:
    return float(f"{x:.2f}")


# ----------------------------
# Mock domain constants
# ----------------------------
BRANDS = ["AEO", "AERIE"]
CHANNELS = ["web", "app", "store"]
DEVICE_TYPES = ["mobile", "desktop", "tablet"]
PAYMENT_TYPES = ["visa", "mastercard", "amex", "paypal", "apple_pay", "google_pay"]
SHIP_METHODS = ["standard", "expedited", "overnight", "bopis"]
EVENT_TYPES = [
    "page_view",
    "product_view",
    "add_to_cart",
    "remove_from_cart",
    "checkout_started",
    "purchase_completed",
    "return_initiated",
    "inventory_adjustment",
]
US_STATES = ["GA", "FL", "AL", "TN", "NC", "SC", "TX", "CA", "NY", "IL", "PA", "VA", "WA", "AZ"]
CITIES = {
    "GA": ["Atlanta", "Decatur", "Marietta", "Roswell"],
    "FL": ["Miami", "Orlando", "Tampa", "Jacksonville"],
    "CA": ["Los Angeles", "San Diego", "San Jose", "San Francisco"],
    "NY": ["New York", "Brooklyn", "Queens", "Buffalo"],
    "TX": ["Austin", "Dallas", "Houston", "San Antonio"],
    "IL": ["Chicago", "Aurora", "Naperville"],
    "PA": ["Philadelphia", "Pittsburgh", "Allentown"],
    "VA": ["Arlington", "Alexandria", "Richmond"],
    "WA": ["Seattle", "Bellevue", "Tacoma"],
    "AZ": ["Phoenix", "Tempe", "Mesa"],
    "AL": ["Birmingham", "Huntsville", "Montgomery"],
    "TN": ["Nashville", "Memphis", "Knoxville"],
    "NC": ["Charlotte", "Raleigh", "Durham"],
    "SC": ["Charleston", "Columbia", "Greenville"],
}

def pick_city_state() -> Tuple[str, str]:
    st = random.choice(US_STATES)
    city = random.choice(CITIES.get(st, ["Unknown"]))
    return city, st


# ----------------------------
# Catalog / stores
# ----------------------------
@dataclasses.dataclass
class Product:
    sku: str
    brand: str
    dept: str
    category: str
    name: str
    base_price: float
    color: str
    size_curve: str

@dataclasses.dataclass
class Store:
    store_id: str
    city: str
    state: str
    store_type: str
    tz: str

def build_catalog() -> Tuple[List[Product], List[Store]]:
    colors = ["black", "white", "blue", "navy", "red", "green", "pink", "beige", "denim"]
    depts = [
        ("AEO", "mens", "denim", ["Skinny Jeans", "Straight Jeans", "Relaxed Jeans"]),
        ("AEO", "mens", "tops", ["Graphic Tee", "Oxford Shirt", "Hoodie"]),
        ("AEO", "womens", "denim", ["Mom Jeans", "Jegging", "High-Rise Skinny"]),
        ("AEO", "womens", "tops", ["Crop Tee", "Sweater", "Blouse"]),
        ("AERIE", "womens", "intimates", ["Bralette", "Wireless Bra", "Boybrief"]),
        ("AERIE", "womens", "loungewear", ["Jogger", "Crew Sweatshirt", "Legging"]),
    ]

    products: List[Product] = []
    for i in range(250):
        brand, dept, category, names = random.choice(depts)
        name = random.choice(names)
        color = random.choice(colors)
        size_curve = "womens" if dept == "womens" else "mens"
        base_price = random.choice([19.95, 24.95, 29.95, 34.95, 39.95, 44.95, 49.95]) if brand == "AERIE" else \
                     random.choice([14.95, 19.95, 24.95, 29.95, 39.95, 49.95, 59.95, 69.95])
        sku = f"{brand[:2]}-{dept[:1].upper()}{category[:2].upper()}-{i:05d}"
        products.append(Product(
            sku=sku, brand=brand, dept=dept, category=category,
            name=f"{name} ({color})", base_price=float(base_price),
            color=color, size_curve=size_curve
        ))

    stores: List[Store] = []
    for i in range(40):
        city, state = pick_city_state()
        store_type = random.choice(["mall", "outlet", "street"])
        stores.append(Store(
            store_id=f"store_{state}_{i:03d}",
            city=city, state=state,
            store_type=store_type,
            tz="America/New_York" if state in ["GA","FL","AL","TN","NC","SC","PA","VA","NY"] else "America/Chicago",
        ))

    return products, stores


# ----------------------------
# Event generation
# ----------------------------
def gen_price_and_discounts(base: float) -> Tuple[float, float]:
    pct = random.choice([0.10, 0.15, 0.20, 0.25, 0.30]) if random.random() < 0.35 else 0.0
    discounted = base * (1.0 - pct)
    return money(discounted), money(base - discounted)

def gen_line_item(prod: Product) -> dict:
    qty = 1 if random.random() < 0.85 else 2
    unit_price, unit_discount = gen_price_and_discounts(prod.base_price)
    size = random.choice(["XS","S","M","L","XL","XXL"]) if prod.size_curve != "womens" else random.choice(["XS","S","M","L","XL"])
    return {
        "sku": prod.sku,
        "brand": prod.brand,
        "dept": prod.dept,
        "category": prod.category,
        "product_name": prod.name,
        "color": prod.color,
        "size": size,
        "qty": qty,
        "unit_price": unit_price,
        "unit_discount": unit_discount,
        "currency": "USD",
    }

def calc_order_totals(items: List[dict]) -> dict:
    subtotal = sum(it["unit_price"] * it["qty"] for it in items)
    discount = sum(it["unit_discount"] * it["qty"] for it in items)
    tax = subtotal * random.choice([0.00, 0.04, 0.06, 0.07, 0.08])
    shipping = 0.0 if random.random() < 0.25 else random.choice([4.95, 6.95, 9.95])
    total = subtotal + tax + shipping
    return {
        "subtotal": money(subtotal),
        "discount_total": money(discount),
        "tax": money(tax),
        "shipping": money(shipping),
        "total": money(total),
        "currency": "USD",
    }

def gen_customer() -> dict:
    city, state = pick_city_state()
    return {
        "customer_id": rand_id("cust", 16),
        "loyalty_id": rand_id("loy", 10) if random.random() < 0.55 else None,
        "email_hash_b64": base64.b64encode(rand_id("email", 10).encode("utf-8")).decode("utf-8"),
        "ship_to": {"city": city, "state": state, "country": "US", "postal3": str(random.randint(100, 999))},
    }

def gen_context(store: Optional[Store]) -> dict:
    channel = random.choice(CHANNELS)
    device = random.choice(DEVICE_TYPES) if channel in ["web", "app"] else None
    city, state = pick_city_state()
    ctx = {
        "channel": channel,
        "device_type": device,
        "marketing_source": random.choice(["direct", "paid_search", "organic_search", "email", "social", "affiliate"]),
        "geo": {"city": city, "state": state, "country": "US"},
    }
    if store and channel == "store":
        ctx["store"] = {"store_id": store.store_id, "city": store.city, "state": store.state, "store_type": store.store_type}
    return ctx

def gen_stream_event(products: List[Product], stores: List[Store], max_event_lag_seconds: int) -> dict:
    now = utc_now()
    event_time = now - timedelta(seconds=random.randint(0, max_event_lag_seconds))
    ingest_time = now

    et = random.choices(EVENT_TYPES, weights=[18, 14, 10, 4, 6, 4, 2, 3], k=1)[0]
    store = random.choice(stores) if random.random() < 0.30 else None
    prod = random.choice(products)
    brand = prod.brand if et in ["product_view", "add_to_cart", "remove_from_cart", "purchase_completed"] else random.choice(BRANDS)

    base = {
        "schema_version": "1.0",
        "event_id": rand_id("evt", 20),
        "event_type": et,
        "brand": brand,
        "event_time": iso_z(event_time),
        "ingest_time": iso_z(ingest_time),
        "session_id": rand_id("sess", 18),
        "request_id": rand_id("req", 18),
        "context": gen_context(store),
    }

    if et in ["page_view", "product_view"]:
        base["page"] = {
            "url_path": random.choice(["/", "/women", "/men", "/aerie", "/sale", f"/p/{prod.sku}"]),
            "referrer": random.choice(["", "https://google.com", "https://instagram.com", "https://t.co", "https://email.example"]),
        }
    if et in ["product_view", "add_to_cart", "remove_from_cart"]:
        base["product"] = {"sku": prod.sku, "dept": prod.dept, "category": prod.category, "price": prod.base_price, "currency": "USD"}
    if et in ["checkout_started", "purchase_completed", "return_initiated"]:
        base["customer"] = gen_customer()

    if et == "purchase_completed":
        items = [gen_line_item(random.choice(products)) for _ in range(1 if random.random() < 0.6 else 2)]
        totals = calc_order_totals(items)
        base["order"] = {
            "order_id": rand_id("ord", 18),
            "items": items,
            "totals": totals,
            "ship_method": random.choice(SHIP_METHODS),
            "payment_type": random.choice(PAYMENT_TYPES),
            "is_bopis": True if random.random() < 0.12 else False,
        }
    if et == "return_initiated":
        base["return"] = {
            "return_id": rand_id("rtn", 18),
            "original_order_id": rand_id("ord", 18),
            "reason": random.choice(["size", "defective", "changed_mind", "late_delivery", "other"]),
            "resolution": random.choice(["refund", "store_credit", "exchange"]),
        }
    if et == "inventory_adjustment":
        base["inventory"] = {
            "store_id": (store.store_id if store else random.choice(stores).store_id),
            "sku": prod.sku,
            "delta": random.choice([-3, -2, -1, 1, 2, 5, 10]),
            "reason": random.choice(["sale", "return", "cycle_count", "transfer", "damage"]),
        }
    return base


# ----------------------------
# Pub/Sub: bounded burst publisher
# ----------------------------
def publish_stream_burst(
    project_id: str,
    topic_id: str,
    events: int,
    rate_per_sec: float,
    max_event_lag_seconds: int,
    ordering_key: Optional[str],
    dry_run: bool,
) -> Dict[str, int]:
    logger.info(
        "stream_start project_id=%s topic_id=%s events=%s rate_per_sec=%s max_event_lag_seconds=%s ordering_key=%s dry_run=%s",
        project_id, topic_id, events, rate_per_sec, max_event_lag_seconds, ordering_key, dry_run
    )

    products, stores = build_catalog()

    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)
    logger.info("pubsub_topic_path=%s", topic_path)

    sleep_s = 1.0 / max(rate_per_sec, 0.001) if rate_per_sec > 0 else 0.0

    requested = int(events)
    attempted = 0
    succeeded = 0
    failed = 0

    # Keep a small sample of failures to return in the HTTP response
    failure_samples: List[str] = []

    publish_futures = []

    for i in range(requested):
        attempted += 1

        evt = gen_stream_event(products, stores, max_event_lag_seconds=max_event_lag_seconds)
        payload = safe_json_dumps(evt).encode("utf-8")

        attrs = {
            "event_type": evt["event_type"],
            "brand": evt["brand"],
            "schema_version": evt["schema_version"],
            "source": "aeo_mock_generator",
        }

        if dry_run:
            succeeded += 1
        else:
            try:
                if ordering_key:
                    fut = publisher.publish(topic_path, payload, ordering_key=ordering_key, **attrs)
                else:
                    fut = publisher.publish(topic_path, payload, **attrs)
                publish_futures.append((i, evt["event_id"], fut))
            except Exception as e:
                failed += 1
                msg = f"publish_submit_failed idx={i} event_id={evt.get('event_id')} err={type(e).__name__}:{e}"
                logger.error(msg)
                if len(failure_samples) < 10:
                    failure_samples.append(msg)

        if sleep_s > 0:
            time.sleep(sleep_s)

        if (i + 1) % 250 == 0:
            logger.info("stream_progress attempted=%s pending_futures=%s succeeded=%s failed=%s",
                        attempted, len(publish_futures), succeeded, failed)

    if not dry_run:
        # IMPORTANT: actually wait for futures and count success/failure
        for (i, event_id, fut) in publish_futures:
            try:
                msg_id = fut.result(timeout=30)
                succeeded += 1
                if succeeded <= 5:
                    logger.info("publish_ok idx=%s event_id=%s message_id=%s", i, event_id, msg_id)
            except Exception as e:
                failed += 1
                msg = f"publish_result_failed idx={i} event_id={event_id} err={type(e).__name__}:{e}"
                logger.error(msg)
                logger.debug("traceback=%s", traceback.format_exc())
                if len(failure_samples) < 10:
                    failure_samples.append(msg)

        logger.info("stream_done attempted=%s succeeded=%s failed=%s", attempted, succeeded, failed)

    result = {
        "events_requested": requested,
        "events_attempted": attempted,
        "events_succeeded": succeeded,
        "events_failed": failed,
    }
    # include samples only if failures happened (keeps response small)
    if failed > 0:
        result["failure_samples"] = failure_samples

    return result


# ----------------------------
# GCS: batch writer using <source_type>_<ISO>_<seq>.jsonl[.gz]
# ----------------------------
def _gzip_bytes(s: str) -> bytes:
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb") as gz:
        gz.write(s.encode("utf-8"))
    return buf.getvalue()

def upload_to_gcs(bucket_name: str, object_name: str, content: bytes, content_type: str, dry_run: bool):
    if dry_run:
        return
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(object_name)
    blob.upload_from_string(content, content_type=content_type)

def gen_batch_records(
    products: List[Product],
    stores: List[Store],
    source_type: str,
    window_start: datetime,
    window_end: datetime,
    record_count: int,
    late_arrival_frac: float,
    max_late_minutes: int,
) -> Tuple[List[dict], dict]:
    records = []
    min_event = None
    max_event = None

    for _ in range(record_count):
        t = window_start + timedelta(seconds=random.randint(0, int((window_end - window_start).total_seconds())))
        if random.random() < late_arrival_frac:
            t = t - timedelta(minutes=random.randint(1, max_late_minutes))

        min_event = t if (min_event is None or t < min_event) else min_event
        max_event = t if (max_event is None or t > max_event) else max_event

        prod = random.choice(products)
        store = random.choice(stores)

        if source_type == "orders":
            items = [gen_line_item(random.choice(products)) for _ in range(1 if random.random() < 0.62 else 2)]
            totals = calc_order_totals(items)
            rec = {
                "schema_version": "1.0",
                "source_type": "orders",
                "order_id": rand_id("ord", 18),
                "brand": prod.brand,
                "event_time": iso_z(t),      # recommended watermark field
                "order_time": iso_z(t),
                "ingest_time": iso_z(utc_now()),
                "channel": random.choice(CHANNELS),
                "store_id": store.store_id if random.random() < 0.25 else None,
                "customer": gen_customer(),
                "ship_method": random.choice(SHIP_METHODS),
                "payment_type": random.choice(PAYMENT_TYPES),
                "items": items,
                "totals": totals,
            }
        elif source_type == "returns":
            rec = {
                "schema_version": "1.0",
                "source_type": "returns",
                "return_id": rand_id("rtn", 18),
                "original_order_id": rand_id("ord", 18),
                "brand": random.choice(BRANDS),
                "event_time": iso_z(t),
                "return_time": iso_z(t),
                "ingest_time": iso_z(utc_now()),
                "store_id": store.store_id if random.random() < 0.55 else None,
                "reason": random.choice(["size", "defective", "changed_mind", "late_delivery", "other"]),
                "resolution": random.choice(["refund", "store_credit", "exchange"]),
                "sku": prod.sku,
                "qty": 1,
                "refund_amount": money(random.choice([14.95, 19.95, 24.95, 29.95, 39.95, 49.95])),
                "currency": "USD",
            }
        elif source_type == "inventory_snapshots":
            rec = {
                "schema_version": "1.0",
                "source_type": "inventory_snapshots",
                "event_time": iso_z(t),
                "snapshot_time": iso_z(t),
                "ingest_time": iso_z(utc_now()),
                "store_id": store.store_id,
                "sku": prod.sku,
                "on_hand": random.randint(0, 60),
                "on_order": random.randint(0, 25),
                "reserved": random.randint(0, 10),
            }
        elif source_type == "product_dim":
            rec = dataclasses.asdict(prod)
            rec.update({
                "schema_version": "1.0",
                "source_type": "product_dim",
                "event_time": iso_z(t),
                "effective_time": iso_z(t),
                "ingest_time": iso_z(utc_now()),
            })
        else:
            raise ValueError(f"Unknown source_type: {source_type}")

        records.append(rec)

    manifest = {
        "source_type": source_type,
        "record_count": len(records),
        "data_window_start": iso_z(window_start),
        "data_window_end": iso_z(window_end),
        "min_event_time": iso_z(min_event) if min_event else None,
        "max_event_time": iso_z(max_event) if max_event else None,
        "generated_at": iso_z(utc_now()),
    }
    return records, manifest

def run_batch_once(
    bucket: str,
    prefix: str,
    source_types: List[str],
    window_start: datetime,
    window_end: datetime,
    records_per_file: int,
    late_arrival_frac: float,
    max_late_minutes: int,
    gzip_output: bool,
    seq_start: int,
    dry_run: bool,
) -> Dict[str, int]:
    products, stores = build_catalog()
    ingest_ts = utc_now()
    ingest_ts_str = iso_filename_ts(ingest_ts)

    created_files = 0
    created_records = 0

    for i, stype in enumerate(source_types):
        seq = seq_start + i
        records, manifest = gen_batch_records(
            products, stores, stype,
            window_start=window_start,
            window_end=window_end,
            record_count=records_per_file,
            late_arrival_frac=late_arrival_frac,
            max_late_minutes=max_late_minutes,
        )

        body = "\n".join(safe_json_dumps(r) for r in records) + "\n"
        if gzip_output:
            content = _gzip_bytes(body)
            ext = ".jsonl.gz"
            ctype = "application/gzip"
        else:
            content = body.encode("utf-8")
            ext = ".jsonl"
            ctype = "application/x-ndjson"

        obj_name = f"{prefix.rstrip('/')}/{stype}/{stype}_{ingest_ts_str}_{seq:05d}{ext}"
        upload_to_gcs(bucket, obj_name, content, ctype, dry_run=dry_run)

        manifest_name = obj_name + ".manifest.json"
        upload_to_gcs(
            bucket,
            manifest_name,
            safe_json_dumps(manifest).encode("utf-8"),
            "application/json",
            dry_run=dry_run,
        )

        created_files += 1
        created_records += len(records)

    return {"files_created": created_files, "records_created": created_records}


# ----------------------------
# Cloud Run function entrypoint
# ----------------------------
@functions_framework.http
def aeo_mock(request):
    body = _get_req_json(request)

    # Global overrides
    dry_run = _env_bool("AEO_DRY_RUN", False)
    dry_run = bool(_pick(body, "dry_run", dry_run))

    seed_env = _env("AEO_SEED", "")
    seed = _pick(body, "seed", int(seed_env) if seed_env not in (None, "") else None)
    if seed is not None:
        random.seed(int(seed))

    mode = _coalesce(_pick_qp(request, "mode"), _pick(body, "mode", None), "batch").lower()

    # Defaults from env
    project_id = _coalesce(_pick_qp(request, "project_id"), _pick(body, "project_id", None),
                           _env("AEO_PROJECT_ID"), _env("GOOGLE_CLOUD_PROJECT"))
    topic_id = _coalesce(_pick_qp(request, "topic_id"), _pick(body, "topic_id", None),
                         _env("AEO_PUBSUB_TOPIC_ID"))
    bucket = _coalesce(_pick_qp(request, "bucket"), _pick(body, "bucket", None),
                       _env("AEO_RAW_GCS_BUCKET"))
    prefix = _coalesce(_pick_qp(request, "prefix"), _pick(body, "prefix", None),
                       _env("AEO_RAW_GCS_PREFIX", "raw/aeo"))

    if mode == "stream":
        if not project_id or not topic_id:
            return jsonify({"ok": False, "error": "Missing project_id/topic_id (set AEO_PROJECT_ID and AEO_PUBSUB_TOPIC_ID)."}), 400

        stream_cfg = _pick(body, "stream", {}) or {}
        events = int(_coalesce(_pick_qp(request, "events"), _pick(stream_cfg, "events", None), 1000))
        rate_per_sec = float(_coalesce(_pick_qp(request, "rate_per_sec"), _pick(stream_cfg, "rate_per_sec", None),
                                       _env_float("AEO_STREAM_RATE_PER_SEC", 10.0)))
        max_lag = int(_coalesce(_pick_qp(request, "max_event_lag_seconds"), _pick(stream_cfg, "max_event_lag_seconds", None),
                                _env_int("AEO_STREAM_MAX_EVENT_LAG_SECONDS", 900)))
        ordering_key = _coalesce(_pick_qp(request, "ordering_key"), _pick(stream_cfg, "ordering_key", None),
                                 _env("AEO_STREAM_ORDERING_KEY", ""))
        ordering_key = ordering_key if ordering_key else None

        stats = publish_stream_burst(
            project_id=project_id,
            topic_id=topic_id,
            events=events,
            rate_per_sec=rate_per_sec,
            max_event_lag_seconds=max_lag,
            ordering_key=ordering_key,
            dry_run=dry_run,
        )
        return jsonify({"ok": True, "mode": "stream", "dry_run": dry_run, "stats": stats}), 200

    if mode == "batch":
        if not bucket:
            return jsonify({"ok": False, "error": "Missing bucket (set AEO_RAW_GCS_BUCKET)."}), 400

        batch_cfg = _pick(body, "batch", {}) or {}

        # default: one “window” per invocation (easiest for Scheduler)
        minutes_back = int(_coalesce(_pick_qp(request, "window_minutes"), _pick(batch_cfg, "window_minutes", None), 60))
        window_end = utc_now()
        window_start = window_end - timedelta(minutes=minutes_back)

        source_types = _coalesce(_pick_qp(request, "source_types"), None)
        if source_types is not None:
            source_types = _split_csv(source_types)
        else:
            source_types = _pick(batch_cfg, "source_types", None)
            if source_types is None:
                source_types = _split_csv(_env("AEO_BATCH_DATASETS", "orders,returns,inventory_snapshots,product_dim"))

        records_per_file = int(_coalesce(_pick_qp(request, "records_per_file"), _pick(batch_cfg, "records_per_file", None),
                                         _env_int("AEO_BATCH_RECORDS_PER_FILE", 2000)))
        late_frac = float(_coalesce(_pick_qp(request, "late_arrival_frac"), _pick(batch_cfg, "late_arrival_frac", None),
                                    _env_float("AEO_BATCH_LATE_ARRIVAL_FRAC", 0.10)))
        max_late = int(_coalesce(_pick_qp(request, "max_late_minutes"), _pick(batch_cfg, "max_late_minutes", None),
                                 _env_int("AEO_BATCH_MAX_LATE_MINUTES", 180)))
        gzip_out = _env_bool("AEO_BATCH_GZIP", True)
        gzip_out = bool(_pick(batch_cfg, "gzip", gzip_out))

        seq_start = int(_coalesce(_pick_qp(request, "seq_start"), _pick(batch_cfg, "seq_start", None), 0))

        stats = run_batch_once(
            bucket=bucket,
            prefix=prefix,
            source_types=source_types,
            window_start=window_start,
            window_end=window_end,
            records_per_file=records_per_file,
            late_arrival_frac=late_frac,
            max_late_minutes=max_late,
            gzip_output=gzip_out,
            seq_start=seq_start,
            dry_run=dry_run,
        )
        return jsonify({
            "ok": True,
            "mode": "batch",
            "dry_run": dry_run,
            "bucket": bucket,
            "prefix": prefix,
            "window_start": iso_z(window_start),
            "window_end": iso_z(window_end),
            "stats": stats,
        }), 200

    return jsonify({"ok": False, "error": f"Unknown mode '{mode}'. Use 'batch' or 'stream'."}), 400