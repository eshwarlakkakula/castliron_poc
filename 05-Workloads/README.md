# Phase 1 Workloads — Databricks Asset Bundle

This is a **scaffold**, not working pipelines. Every resource definition
(`resources/*.yml`) is correctly shaped against `03-Infra`'s cluster
policies and instance pool outputs and will pass `databricks bundle
validate`; every source file under `src/` sets up the right structure
(DLT table declarations, job entry points, the correct up/downstream
dependencies) with a `TODO` at every point that needs a real decision this
repository doesn't have the authority to make on CastIron's behalf.

| Resource | Status |
|---|---|
| `streaming_pipeline.yml` / `bronze_silver_gold_pipeline.py` | Structural - schema contract, enrichment source, dedup key, and watermark are placeholders |
| `identity_resolution_job.yml` / `resolve_identity.py` | Structural - blocked on licensor selection and the Profile Agents capability question |
| `measurement_job.yml` / `compute_measurement.py`, `ingest_validation_files.py` | `compute_measurement.py` deliberately raises `NotImplementedError` - no certified reach/frequency/equivalization definition exists to implement against |
| `clean_room_contribution_job.yml` / `write_contribution_tables.py` | Structural - table schema and tokenization scheme are placeholders |
| `reverse_etl_job.yml` / `upsert_to_aurora.py` | Idempotent MERGE pattern (staging table + `INSERT ... ON DUPLICATE KEY UPDATE`), not naive append - generated SQL verified standalone. Real Aurora schema, write volume/SLO, and the natural key are still placeholders - do not deploy past that placeholder |
| `parity_reconciliation_job.yml` / `redshift_parity_check.py` | Comparison engine (`compare_metric`, `reconcile_report`) is real, generic logic - **12/12 unit tests pass** (`test_redshift_parity_check.py`). The list of the real ~15 packaged reports and their Redshift/gold queries is a 2-entry illustrative placeholder, and the reconciliation tolerance defaults to 0% pending a certified number |

None of this has been run against a cluster. `databricks bundle validate`
checks the bundle's shape, not whether the notebooks execute correctly -
treat a clean `validate` as "the scaffold is wired together correctly,"
not as "the pipelines work."

## What unblocks each TODO

See the top-level `README.md`'s "Inputs needed from CastIron" list, which
maps directly to the TODOs above - this directory doesn't duplicate that
list, it implements against it once it's answered.
