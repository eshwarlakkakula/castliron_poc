import argparse
import json
import random
import time
import uuid
from datetime import datetime, timezone

import boto3

EVENT_TYPES = ["impression", "click", "conversion", "viewability"]
USER_AGENTS = [
    "Mozilla/5.0 (SMART-TV; Linux; Tizen) AppleWebKit/537.36",
    "Mozilla/5.0 (PlayStation; PlayStation 5/5.00) AppleWebKit/605.1.15",
    "Roku/DVP-14.0",
    "Mozilla/5.0 (Linux; Android 13; Chromecast)",
]


def build_event() -> dict:
    return {
        "request_id": str(uuid.uuid4()),
        "event_type": random.choice(EVENT_TYPES),
        "event_timestamp": datetime.now(timezone.utc).isoformat(),
        "device_id": f"device-{random.randint(1, 5000)}",
        "ip_address": f"203.0.113.{random.randint(1, 254)}",
        "user_agent": random.choice(USER_AGENTS),
        "_synthetic": True,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Push synthetic ad-server events onto the CastIron POC Kinesis stream")
    parser.add_argument("--stream-name", required=True)
    parser.add_argument("--region", default="ap-south-1")
    parser.add_argument("--count", type=int, default=200)
    parser.add_argument("--batch-size", type=int, default=25)
    args = parser.parse_args()

    client = boto3.client("kinesis", region_name=args.region)
    sent = 0
    while sent < args.count:
        batch = [build_event() for _ in range(min(args.batch_size, args.count - sent))]
        records = [
            {"Data": json.dumps(event).encode("utf-8"), "PartitionKey": event["device_id"]}
            for event in batch
        ]
        response = client.put_records(StreamName=args.stream_name, Records=records)
        sent += len(batch)
        print(f"sent={sent}/{args.count} failed_record_count={response['FailedRecordCount']}")
        time.sleep(0.2)


if __name__ == "__main__":
    main()
