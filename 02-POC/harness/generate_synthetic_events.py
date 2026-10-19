#!/usr/bin/env python3
"""Synthetic ad-server event generator for POC Objective 1 (streaming
end-to-end). Pushes events to the POC Kinesis stream at a configurable
rate so bronze_silver_gold_pipeline.py has real traffic to process.

This generates STRUCTURALLY plausible events (the field names match the
EVENT_SCHEMA_PLACEHOLDER in 05-Workloads/src/streaming/
bronze_silver_gold_pipeline.py), not a copy of CastIron's real event
schema - that schema was never supplied (Technical Approach, Section 9
open items). Swap EVENT_SCHEMA_PLACEHOLDER for the real contract once
it's confirmed, and this generator's `build_event()` function along with
it.

Usage:
    pip install boto3
    export AWS_REGION=us-east-1
    python generate_synthetic_events.py \
        --stream-name castiron-lakehouse-dev-ad-server-events \
        --rate 175 \
        --duration-seconds 1800

Rate defaults to 175 events/s, the midpoint of the POC's documented
~150-200 events/s target (02-POC document, Section 4).
"""
from __future__ import annotations

import argparse
import json
import random
import time
import uuid
from datetime import datetime, timezone

try:
    import boto3
except ImportError as exc:  # pragma: no cover
    raise SystemExit("This script requires boto3: pip install boto3") from exc


DEVICE_OS = ["Roku", "FireTV", "AppleTV", "AndroidTV", "SamsungTV", "iOS", "Android"]
EVENT_TYPES = ["impression", "quartile_25", "quartile_50", "quartile_75", "complete", "click"]

# A fixed pool of synthetic device IDs, reused across the run, so the
# downstream identity-resolution and reach/frequency logic has repeat
# viewers to de-duplicate against - a single-use device ID per event
# would make every reach/frequency test trivially "1 impression per
# household" and prove nothing.
_DEVICE_POOL = [str(uuid.uuid4()) for _ in range(20_000)]


def build_event() -> dict:
    now = datetime.now(timezone.utc)
    return {
        "request_id": str(uuid.uuid4()),
        "event_type": random.choice(EVENT_TYPES),
        "event_timestamp": now.isoformat(),
        "device_id": random.choice(_DEVICE_POOL),
        "ip_address": f"{random.randint(1,223)}.{random.randint(0,255)}.{random.randint(0,255)}.{random.randint(1,254)}",
        "user_agent": random.choice(DEVICE_OS),
        "_synthetic": True,  # lets downstream queries exclude POC traffic from any real-data comparisons
    }


def run(stream_name: str, rate_per_second: float, duration_seconds: int, region: str) -> None:
    client = boto3.client("kinesis", region_name=region)
    interval = 1.0 / rate_per_second
    sent = 0
    start = time.monotonic()
    deadline = start + duration_seconds

    print(f"Sending to '{stream_name}' at ~{rate_per_second}/s for {duration_seconds}s "
          f"(~{int(rate_per_second * duration_seconds):,} events total)")

    while time.monotonic() < deadline:
        batch = []
        for _ in range(min(500, max(1, int(rate_per_second)))):  # Kinesis PutRecords caps at 500/call
            event = build_event()
            batch.append({
                "Data": json.dumps(event).encode("utf-8"),
                "PartitionKey": event["device_id"],
            })
        resp = client.put_records(StreamName=stream_name, Records=batch)
        sent += len(batch) - resp.get("FailedRecordCount", 0)
        if resp.get("FailedRecordCount"):
            print(f"  warning: {resp['FailedRecordCount']} records failed in this batch")
        time.sleep(interval * len(batch))

    elapsed = time.monotonic() - start
    print(f"Done. Sent {sent:,} events in {elapsed:.1f}s (~{sent/elapsed:.1f}/s actual).")
    print(f"Pass criterion reference (02-POC Section 5): confirm these events reach the gold "
          f"table within the measured latency band, with zero loss across a forced worker restart.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--stream-name", required=True, help="Target Kinesis stream name")
    parser.add_argument("--rate", type=float, default=175.0, help="Events per second (default 175, POC target is 150-200)")
    parser.add_argument("--duration-seconds", type=int, default=1800, help="How long to run (default 30 minutes)")
    parser.add_argument("--region", default="us-east-1", help="AWS region")
    args = parser.parse_args()
    run(args.stream_name, args.rate, args.duration_seconds, args.region)


if __name__ == "__main__":
    main()
