# Mock Data generator
Mocks data used in the demo pipeline.

## The Data
The data mocked looks like:
```jsonl
#Streamed:
{
    "schema_version": "1.0",
    "event_id": "evt_0ihx5ubmmbjqlnebk4r7",
    "event_type": "page_view",
    "brand": "AEO",
    "event_time": "2026-03-04T14:01:28.058243Z",
    "ingest_time": "2026-03-04T14:13:42.058243Z",
    "session_id": "sess_4gaq6x0dztyz4nf78h",
    "request_id": "req_fj1liaqwjqwnjtrthc",
    "context": {
        "channel": "store",
        "device_type": null,
        "marketing_source": "email",
        "geo": {
            "city": "Tacoma",
            "state": "WA",
            "country": "US"
        }
    },
    "page": {
        "url_path": "/men",
        "referrer": "https://t.co"
    }
}
# Batched:
# Return:
{
  "schema_version": "1.0",
  "source_type": "returns",
  "return_id": "rtn_g458j25in7ig7o5yty",
  "original_order_id": "ord_omwjvrrndl17r4pd5t",
  "brand": "AEO",
  "event_time": "2026-03-03T18:29:03.557129Z",
  "return_time": "2026-03-03T18:29:03.557129Z",
  "ingest_time": "2026-03-03T18:47:19.934784Z",
  "store_id": "store_SC_022",
  "reason": "changed_mind",
  "resolution": "exchange",
  "sku": "AE-WIN-00031",
  "qty": 1,
  "refund_amount": 29.95,
  "currency": "USD"
}
# Inventory snapshot:
{
  "schema_version": "1.0",
  "source_type": "inventory_snapshots",
  "event_time": "2026-03-03T18:27:57.557129Z",
  "snapshot_time": "2026-03-03T18:27:57.557129Z",
  "ingest_time": "2026-03-03T18:47:20.439547Z",
  "store_id": "store_TN_026",
  "sku": "AE-MDE-00211",
  "on_hand": 25,
  "on_order": 12,
  "reserved": 8
}
# Order:
{
  "schema_version": "1.0",
  "source_type": "orders",
  "order_id": "ord_tbcudswx1jp70lklfy",
  "brand": "AERIE",
  "event_time": "2026-03-03T18:13:11.557129Z",
  "order_time": "2026-03-03T18:13:11.557129Z",
  "ingest_time": "2026-03-03T18:47:15.558885Z",
  "channel": "store",
  "store_id": null,
  "customer": {
    "customer_id": "cust_o3q3qa3s8ke2wt1q",
    "loyalty_id": "loy_tmy4gpywss",
    "email_hash_b64": "ZW1haWxfYnpyYWQ1c293bw==",
    "ship_to": {
      "city": "San Diego",
      "state": "CA",
      "country": "US",
      "postal3": "751"
    }
  },
  "ship_method": "expedited",
  "payment_type": "apple_pay",
  "items": [
    {
      "sku": "AE-MDE-00009",
      "brand": "AEO",
      "dept": "mens",
      "category": "denim",
      "product_name": "Skinny Jeans (pink)",
      "color": "pink",
      "size": "S",
      "qty": 1,
      "unit_price": 15.96,
      "unit_discount": 3.99,
      "currency": "USD"
    },
    {
      "sku": "AE-WTO-00191",
      "brand": "AEO",
      "dept": "womens",
      "category": "tops",
      "product_name": "Crop Tee (green)",
      "color": "green",
      "size": "XS",
      "qty": 1,
      "unit_price": 39.95,
      "unit_discount": 0,
      "currency": "USD"
    }
  ],
  "totals": {
    "subtotal": 55.91,
    "discount_total": 3.99,
    "tax": 3.91,
    "shipping": 0,
    "total": 59.82,
    "currency": "USD"
  }
}
# product:
{
  "sku": "AE-WDE-00115",
  "brand": "AEO",
  "dept": "womens",
  "category": "denim",
  "name": "High-Rise Skinny (denim)",
  "base_price": 59.95,
  "color": "denim",
  "size_curve": "womens",
  "schema_version": "1.0",
  "source_type": "product_dim",
  "event_time": "2026-03-03T18:00:28.557129Z",
  "effective_time": "2026-03-03T18:00:28.557129Z",
  "ingest_time": "2026-03-03T18:47:20.789313Z"
}
```

## Files in this Terraform module:
- main.py
    - The script entry point, entry function defined as aeo_mock currently.
- aeo-mock-generator.py
    - The local version of the mock generator. Can be executed individually

## Running
### Streamed
#### Local
To call the streaming mock, run using:
```python
python aeo_mock_data.py stream --project YOUR_PROJECT --topic <PubSub topic> --minutes 10 --rate 25 --max-event-lag-seconds 1200
```
#### Cloud Run
```json
{
  "project_id": "aeo-234are-demo-dev",
  "mode": "stream",
  "stream": {
    "events": 10,
    "rate_per_sec": 25,
    "max_event_lag_seconds": 900,
    "ordering_key": "event_time"
  },
  "dry_run": false,
  "seed": 42
}
```

### Batch
#### Local
To call the batch mock, run using:
```python
python aeo_mock_data.py batch --bucket YOUR_RAW_BUCKET --prefix <file prefix> --days 3 --files-per-day 6 --records-per-file 5000 --late-arrival-frac 0.15 --max-late-minutes 360 --gzip
```
#### Cloud Run
```json
{
  "mode": "batch",
  "batch": {
    "window_minutes": 60,
    "records_per_file": 2000,
    "source_types": ["orders", "returns", "inventory_snapshots", "product_dim"],
    "late_arrival_frac": 0.10,
    "max_late_minutes": 180,
    "gzip": true,
    "seq_start": 0
  },
  "dry_run": false,
  "seed": 42
}
```