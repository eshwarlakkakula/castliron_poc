import argparse
import random
import uuid

import pandas as pd


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate synthetic device identifier and probe tables for the identity resolution POC job")
    parser.add_argument("--device-count", type=int, default=5000)
    parser.add_argument("--household-count", type=int, default=1500)
    parser.add_argument("--probe-count", type=int, default=3000)
    parser.add_argument("--match-rate", type=float, default=0.7, help="Fraction of devices that resolve to a household")
    parser.add_argument("--out-dir", required=True)
    args = parser.parse_args()

    household_ids = [str(uuid.uuid4()) for _ in range(args.household_count)]
    device_ids = [f"device-{i}" for i in range(1, args.device_count + 1)]
    matched_devices = set(random.sample(device_ids, int(args.device_count * args.match_rate)))

    identifiers = pd.DataFrame(
        {
            "device_id": list(matched_devices),
            "household_id": [random.choice(household_ids) for _ in matched_devices],
        }
    )

    probe_device_ids = [random.choice(device_ids) for _ in range(args.probe_count)]
    probes = pd.DataFrame(
        {
            "probe_id": [str(uuid.uuid4()) for _ in range(args.probe_count)],
            "device_id": probe_device_ids,
        }
    )

    identifiers.to_parquet(f"{args.out_dir}/identifiers.parquet", index=False)
    probes.to_parquet(f"{args.out_dir}/probes.parquet", index=False)
    print(f"wrote {len(identifiers)} identifiers and {len(probes)} probes to {args.out_dir}")


if __name__ == "__main__":
    main()
