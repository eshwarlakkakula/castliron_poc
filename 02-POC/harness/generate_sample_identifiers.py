#!/usr/bin/env python3
"""Synthetic identifier table generator for POC Objective 2 (identity
join behavior at representative scale).

Generates a Parquet dataset standing in for the licensed third-party
device graph (Technical Approach, Section 3: 8M probes/day against a
3.2B-row identifier table) at the POC's documented reduced scale
(10-20M rows, 02-POC document Section 3.1/4). This is synthetic data with
no relationship to any real licensor's graph - the licensor has not been
selected yet (Technical Approach Section 9 open item), so there is
nothing real to sample from.

Also generates a matching daily probe file, sized proportionally to the
identifier table the same way the real 8M-vs-3.2B ratio is proportional
(~0.25%), so the join's selectivity is representative even though the
absolute scale is not.

Usage:
    pip install pyarrow
    python generate_sample_identifiers.py \
        --identifier-rows 15000000 \
        --output-dir ./poc_data \
        --overlap-fraction 0.6

--overlap-fraction controls what fraction of probe device_ids actually
exist in the identifier table - tune this to see how join runtime and
output size change with match rate, since match rate is one of the
unknowns a resident-graph join's cost depends on (Technical Approach
Section 3: "join-bound, not ingest-bound").
"""
from __future__ import annotations

import argparse
import random
import uuid
from pathlib import Path

try:
    import pyarrow as pa
    import pyarrow.parquet as pq
except ImportError as exc:  # pragma: no cover
    raise SystemExit("This script requires pyarrow: pip install pyarrow") from exc


def generate_identifier_table(path: Path, row_count: int, batch_size: int = 1_000_000) -> list[str]:
    """Writes the identifier table in batches (so an 10-20M row run doesn't
    hold everything in memory at once) and returns a sample of generated
    device_ids for the probe file to optionally overlap with."""
    schema = pa.schema([
        ("device_id", pa.string()),
        ("household_id", pa.string()),
        ("confidence_score", pa.float32()),
        # TODO(real-schema): the actual licensed graph's schema depends on
        # the selected licensor (Acxiom / Experian / TruSet) - this is a
        # plausible placeholder shape, not a confirmed contract.
    ])
    writer = pq.ParquetWriter(path, schema)
    sample_ids: list[str] = []
    remaining = row_count
    while remaining > 0:
        n = min(batch_size, remaining)
        device_ids = [str(uuid.uuid4()) for _ in range(n)]
        household_ids = [str(uuid.uuid4()) for _ in range(n)]
        scores = [round(random.uniform(0.5, 0.99), 3) for _ in range(n)]
        batch = pa.record_batch(
            [pa.array(device_ids), pa.array(household_ids), pa.array(scores, type=pa.float32())],
            schema=schema,
        )
        writer.write_batch(batch)
        if len(sample_ids) < 200_000:
            sample_ids.extend(device_ids[: max(0, 200_000 - len(sample_ids))])
        remaining -= n
        print(f"  identifier table: {row_count - remaining:,} / {row_count:,} rows written")
    writer.close()
    return sample_ids


def generate_probe_file(path: Path, probe_count: int, known_device_ids: list[str], overlap_fraction: float) -> None:
    schema = pa.schema([
        ("device_id", pa.string()),
        ("probe_timestamp", pa.string()),
    ])
    overlap_count = int(probe_count * overlap_fraction)
    fresh_count = probe_count - overlap_count
    device_ids = (
        random.choices(known_device_ids, k=overlap_count)
        + [str(uuid.uuid4()) for _ in range(fresh_count)]
    )
    random.shuffle(device_ids)
    timestamps = ["2026-10-19T00:00:00Z"] * len(device_ids)
    table = pa.table({"device_id": device_ids, "probe_timestamp": timestamps}, schema=schema)
    pq.write_table(table, path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--identifier-rows", type=int, default=15_000_000,
                         help="Identifier table row count (POC target: 10-20M)")
    parser.add_argument("--probe-ratio", type=float, default=0.0025,
                         help="Probe count as a fraction of identifier rows (default 0.0025, matching the real 8M/3.2B ratio)")
    parser.add_argument("--overlap-fraction", type=float, default=0.6,
                         help="Fraction of probes that match an identifier row (default 0.6)")
    parser.add_argument("--output-dir", default="./poc_data")
    args = parser.parse_args()

    out = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)
    identifiers_path = out / "identifiers.parquet"
    probes_path = out / "probes.parquet"

    print(f"Generating {args.identifier_rows:,}-row identifier table -> {identifiers_path}")
    sample_ids = generate_identifier_table(identifiers_path, args.identifier_rows)

    probe_count = int(args.identifier_rows * args.probe_ratio)
    print(f"Generating {probe_count:,} probes ({args.overlap_fraction:.0%} expected match rate) -> {probes_path}")
    generate_probe_file(probes_path, probe_count, sample_ids, args.overlap_fraction)

    print("Done. Pass criterion reference (02-POC Section 5): join completes without manual "
          "tuning; record the measured runtime and extrapolate to the full 3.2B-row table.")


if __name__ == "__main__":
    main()
