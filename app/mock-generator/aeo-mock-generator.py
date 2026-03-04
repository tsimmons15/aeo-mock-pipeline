#!/usr/bin/env python3

import argparse, base64, dataclasses, gzip, io, json, os, random, string, sys, time
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple

from google.cloud import pubsub_v1
from google.cloud import storage


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
CURRENCIES = ["USD"]
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

def utc_now() -> datetime:
    return datetime.now(timezone.utc)

def iso_z(dt: datetime) -> str:
    s = dt.astimezone(timezone.utc).isoformat()
    return s.replace("+00:00", "Z")

def rand_id(prefix: str, n: int = 12) -> str:
    alphabet = string.ascii_lowercase + string.digits
    return f"{prefix}_{''.join(random.choice(alphabet) for _ in range(n))}"

def pick_city_state() -> Tuple[str, str]:
    st = random.choice(US_STATES)
    city = random.choice(CITIES.get(st, ["Unknown"]))
    return city, st

def safe_json_dumps(obj: dict) -> str:
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False)

@dataclasses.dataclass
class Product:
    sku: str
    brand: str
    dept: str
    category: str
    name: str
    base_price: float
    color: str
    size_curve: str  # e.g., "mens", "womens", "unisex"

@dataclasses.dataclass
class Store:
    store_id: str
    city: str
    state: str
    store_type: str  # e.g., "mall", "outlet"
    tz: str

def build_catalog() -> Tuple[List[Product], List[Store]]:
    colors = ["black", "white", "blue", "navy", "red", "green", "pink", "beige", "denim"]
    womens_sizes = ["XS", "S", "M", "L", "XL"]
    mens_sizes = ["S", "M", "L", "XL", "XXL"]
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
        if brand == "AERIE":
            base_price = random.choice([19.95, 24.95, 29.95, 34.95, 39.95, 44.95, 49.95])
        else:
            base_price = random.choice([14.95, 19.95, 24.95, 29.95, 39.95, 49.95, 59.95, 69.95])
        sku = f"{brand[:2]}-{dept[:1].upper()}{category[:2].upper()}-{i:05d}"
        products.append(Product(
            sku=sku,
            brand=brand,
            dept=dept,
            category=category,
            name=f"{name} ({color})",
            base_price=float(base_price),
            color=color,
            size_curve=size_curve,
        ))

    stores: List[Store] = []
    for i in range(40):
        city, state = pick_city_state()
        store_type = random.choice(["mall", "outlet", "street"])
        stores.append(Store(
            store_id=f"store_{state}_{i:03d}",
            city=city,
            state=state,
            store_type=store_type,
            tz="America/New_York" if state in ["GA","FL","AL","TN","NC","SC","PA","VA","NY"] else "America/Chicago",
        ))
    return products, stores

def money(x: float) -> float:
    return float(f"{x:.2f}")

def gen_price_and_discounts(base: float) -> Tuple[float, float]:
    if random.random() < 0.35:
        pct = random.choice([0.10, 0.15, 0.20, 0.25, 0.30])
    else:
        pct = 0.0
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
        "ship_to": {
            "city": city,
            "state": state,
            "country": "US",
            "postal3": str(random.randint(100, 999)),
        },
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
        ctx["store"] = {
            "store_id": store.store_id,
            "city": store.city,
            "state": store.state,
            "store_type": store.store_type,
        }
    return ctx

def gen_stream_event(products: List[Product], stores: List[Store], max_event_lag_seconds: int) -> dict:
    now = utc_now()
    event_time = now - timedelta(seconds=random.randint(0, max_event_lag_seconds))
    ingest_time = now
    et = random.choices(
        EVENT_TYPES,
        weights=[18, 14, 10, 4, 6, 4, 2, 3],
        k=1
    )[0]

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
        base["product"] = {
            "sku": prod.sku,
            "dept": prod.dept,
            "category": prod.category,
            "price": prod.base_price,
            "currency": "USD",
        }
    if et in ["checkout_started", "purchase_completed", "return_initiated"]:
        cust = gen_customer()
        base["customer"] = cust

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

def publish_stream(
    project: str,
    topic: str,
    minutes: int,
    rate_per_sec: float,
    max_event_lag_seconds: int,
    ordering_key: Optional[str],
    dry_run: bool,
    seed: Optional[int],
):
    if seed is not None:
        random.seed(seed)

    products, stores = build_catalog()
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project, topic)

    end_time = time.time() + minutes * 60
    sleep_s = 1.0 / max(rate_per_sec, 0.001)
    outstanding = []

    while time.time() < end_time:
        evt = gen_stream_event(products, stores, max_event_lag_seconds=max_event_lag_seconds)
        payload = safe_json_dumps(evt).encode("utf-8")

        attrs = {
            "event_type": evt["event_type"],
            "brand": evt["brand"],
            "schema_version": evt["schema_version"],
            "source": "aeo_mock_generator",
        }

        if dry_run:
            sys.stdout.write(payload.decode("utf-8") + "\n")
            sys.stdout.flush()
        else:
            if ordering_key:
                fut = publisher.publish(topic_path, payload, ordering_key=ordering_key, **attrs)
            else:
                fut = publisher.publish(topic_path, payload, **attrs)
            outstanding.append(fut)

        time.sleep(sleep_s)

    if not dry_run:
        for fut in outstanding[-5000:]:
            try:
                fut.result(timeout=30)
            except Exception:
                pass

def _gzip_bytes(s: str) -> bytes:
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb") as gz:
        gz.write(s.encode("utf-8"))
    return buf.getvalue()

def write_batch_to_gcs(
    bucket_name: str,
    object_name: str,
    content: bytes,
    content_type: str,
    dry_run: bool,
):
    if dry_run:
        sys.stderr.write(f"[dry-run] would upload gs://{bucket_name}/{object_name} ({len(content)} bytes)\n")
        return
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(object_name)
    blob.upload_from_string(content, content_type=content_type)

def gen_batch_records(
    products: List[Product],
    stores: List[Store],
    dataset: str,
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

        if dataset == "orders":
            items = [gen_line_item(random.choice(products)) for _ in range(1 if random.random() < 0.62 else 2)]
            totals = calc_order_totals(items)
            rec = {
                "schema_version": "1.0",
                "order_id": rand_id("ord", 18),
                "brand": prod.brand,
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
        elif dataset == "returns":
            rec = {
                "schema_version": "1.0",
                "return_id": rand_id("rtn", 18),
                "original_order_id": rand_id("ord", 18),
                "brand": random.choice(BRANDS),
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
        elif dataset == "inventory_snapshots":
            rec = {
                "schema_version": "1.0",
                "snapshot_time": iso_z(t),
                "ingest_time": iso_z(utc_now()),
                "store_id": store.store_id,
                "sku": prod.sku,
                "on_hand": random.randint(0, 60),
                "on_order": random.randint(0, 25),
                "reserved": random.randint(0, 10),
            }
        elif dataset == "product_dim":
            rec = dataclasses.asdict(prod)
            rec["schema_version"] = "1.0"
            rec["effective_time"] = iso_z(t)
            rec["ingest_time"] = iso_z(utc_now())
        else:
            raise ValueError(f"Unknown dataset: {dataset}")

        records.append(rec)

    manifest = {
        "dataset": dataset,
        "record_count": len(records),
        "data_window_start": iso_z(window_start),
        "data_window_end": iso_z(window_end),
        "min_event_time": iso_z(min_event) if min_event else None,
        "max_event_time": iso_z(max_event) if max_event else None,
        "generated_at": iso_z(utc_now()),
    }
    return records, manifest

def run_batch(
    bucket: str,
    prefix: str,
    days: int,
    files_per_day: int,
    records_per_file: int,
    datasets: List[str],
    late_arrival_frac: float,
    max_late_minutes: int,
    gzip_output: bool,
    dry_run: bool,
    seed: Optional[int],
):
    if seed is not None:
        random.seed(seed)

    products, stores = build_catalog()
    now = utc_now()
    start_day = (now.date() - timedelta(days=days - 1))

    for d in range(days):
        day = start_day + timedelta(days=d)
        for f in range(files_per_day):
            window_start = datetime(day.year, day.month, day.day, 0, 0, 0, tzinfo=timezone.utc) + timedelta(hours=int(24 * f / files_per_day))
            window_end = window_start + timedelta(hours=int(24 / files_per_day))

            for dataset in datasets:
                records, manifest = gen_batch_records(
                    products, stores, dataset,
                    window_start=window_start,
                    window_end=window_end,
                    record_count=records_per_file,
                    late_arrival_frac=late_arrival_frac,
                    max_late_minutes=max_late_minutes,
                )

                ingest_date = iso_z(now)[:10]
                obj_base = (
                    f"{prefix.rstrip('/')}/"
                    f"dataset={dataset}/"
                    f"ingest_date={ingest_date}/"
                    f"window_start={iso_z(window_start)}/"
                    f"window_end={iso_z(window_end)}/"
                    f"part-{f:05d}.jsonl"
                )

                body = "\n".join(safe_json_dumps(r) for r in records) + "\n"
                if gzip_output:
                    content = _gzip_bytes(body)
                    obj_name = obj_base + ".gz"
                    ctype = "application/gzip"
                else:
                    content = body.encode("utf-8")
                    obj_name = obj_base
                    ctype = "application/x-ndjson"

                write_batch_to_gcs(bucket, obj_name, content, ctype, dry_run=dry_run)

                manifest_name = obj_name + ".manifest.json"
                write_batch_to_gcs(
                    bucket,
                    manifest_name,
                    safe_json_dumps(manifest).encode("utf-8"),
                    "application/json",
                    dry_run=dry_run,
                )

def parse_args():
    p = argparse.ArgumentParser(description="Mock data generator for an AEO-like retail pipeline (Pub/Sub + GCS raw).")
    p.add_argument("--seed", type=int, default=None, help="Random seed for reproducibility.")
    p.add_argument("--dry-run", action="store_true", help="Do not publish/upload; stream prints to stdout, batch logs to stderr.")

    sub = p.add_subparsers(dest="cmd", required=True)

    ps = sub.add_parser("stream", help="Publish real-time events to Pub/Sub.")
    ps.add_argument("--project", default=os.getenv("GOOGLE_CLOUD_PROJECT"), required=False, help="GCP project id.")
    ps.add_argument("--topic", required=True, help="Pub/Sub topic id (not full path).")
    ps.add_argument("--minutes", type=int, default=5, help="How long to run.")
    ps.add_argument("--rate", type=float, default=10.0, help="Events per second.")
    ps.add_argument("--max-event-lag-seconds", type=int, default=900, help="Max lateness of event_time vs ingest_time.")
    ps.add_argument("--ordering-key", default=None, help="Optional Pub/Sub ordering key.")

    pb = sub.add_parser("batch", help="Write batch jsonl files into a raw GCS bucket.")
    pb.add_argument("--bucket", required=True, help="Raw GCS bucket name.")
    pb.add_argument("--prefix", default="raw/aeo", help="Object prefix in the raw bucket.")
    pb.add_argument("--days", type=int, default=2, help="How many days of data windows to generate.")
    pb.add_argument("--files-per-day", type=int, default=4, help="How many window files per dataset per day.")
    pb.add_argument("--records-per-file", type=int, default=2000, help="Records per file per dataset.")
    pb.add_argument("--datasets", default="orders,returns,inventory_snapshots,product_dim",
                    help="Comma-separated datasets to generate.")
    pb.add_argument("--late-arrival-frac", type=float, default=0.10,
                    help="Fraction of records whose event time is pushed earlier to mimic late arrival.")
    pb.add_argument("--max-late-minutes", type=int, default=180,
                    help="Max minutes to push late records back in time.")
    pb.add_argument("--gzip", action="store_true", help="Write .jsonl.gz instead of .jsonl.")

    return p.parse_args()

def main():
    args = parse_args()

    if args.cmd == "stream":
        if not args.project:
            raise SystemExit("Missing --project and GOOGLE_CLOUD_PROJECT is not set.")
        publish_stream(
            project=args.project,
            topic=args.topic,
            minutes=args.minutes,
            rate_per_sec=args.rate,
            max_event_lag_seconds=args.max_event_lag_seconds,
            ordering_key=args.ordering_key,
            dry_run=args.dry_run,
            seed=args.seed,
        )
    elif args.cmd == "batch":
        datasets = [x.strip() for x in args.datasets.split(",") if x.strip()]
        run_batch(
            bucket=args.bucket,
            prefix=args.prefix,
            days=args.days,
            files_per_day=args.files_per_day,
            records_per_file=args.records_per_file,
            datasets=datasets,
            late_arrival_frac=args.late_arrival_frac,
            max_late_minutes=args.max_late_minutes,
            gzip_output=args.gzip,
            dry_run=args.dry_run,
            seed=args.seed,
        )
    else:
        raise SystemExit(f"Unknown cmd: {args.cmd}")

if __name__ == "__main__":
    main()
