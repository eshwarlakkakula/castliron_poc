import argparse
import json
import time
from datetime import datetime, timezone
from urllib.parse import urlparse

import boto3


def parse_s3_url(url: str) -> tuple[str, str]:
    parsed = urlparse(url)
    return parsed.netloc, parsed.path.lstrip("/")


def main() -> None:
    parser = argparse.ArgumentParser(description="Bridge records from a Kinesis stream into an S3 landing path as NDJSON")
    parser.add_argument("--stream-name", required=True)
    parser.add_argument("--landing-path", required=True, help="s3://bucket/prefix the pipeline's Auto Loader reads from")
    parser.add_argument("--region", default="ap-south-1")
    parser.add_argument("--max-empty-polls", type=int, default=3, help="Stop after this many consecutive empty GetRecords calls")
    parser.add_argument("--poll-interval-seconds", type=float, default=2.0)
    args = parser.parse_args()

    bucket, prefix = parse_s3_url(args.landing_path)
    kinesis = boto3.client("kinesis", region_name=args.region)
    s3 = boto3.client("s3", region_name=args.region)

    shards = kinesis.describe_stream(StreamName=args.stream_name)["StreamDescription"]["Shards"]
    collected = []

    for shard in shards:
        shard_iterator = kinesis.get_shard_iterator(
            StreamName=args.stream_name,
            ShardId=shard["ShardId"],
            ShardIteratorType="TRIM_HORIZON",
        )["ShardIterator"]

        empty_polls = 0
        while shard_iterator and empty_polls < args.max_empty_polls:
            response = kinesis.get_records(ShardIterator=shard_iterator, Limit=500)
            records = response["Records"]
            if records:
                empty_polls = 0
                for record in records:
                    collected.append(json.loads(record["Data"]))
            else:
                empty_polls += 1
            shard_iterator = response.get("NextShardIterator")
            time.sleep(args.poll_interval_seconds)

    if not collected:
        print("no records found on the stream")
        return

    batch_key = f"{prefix.rstrip('/')}/batch-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S')}.json"
    body = "\n".join(json.dumps(event) for event in collected)
    s3.put_object(Bucket=bucket, Key=batch_key, Body=body.encode("utf-8"))
    print(f"wrote {len(collected)} records to s3://{bucket}/{batch_key}")


if __name__ == "__main__":
    main()
