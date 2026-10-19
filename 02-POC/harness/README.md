# POC execution harness

Makes the 3-week POC plan in `../CastIron Media - Phase 1 POC.docx`
(Section 5) actually executable, not just described. Three scripts:

| Script | What it does | Tested |
|---|---|---|
| `generate_synthetic_events.py` | Pushes synthetic ad-server events to the POC Kinesis stream at ~150-200/s | Syntax-checked; not run against a real stream (needs AWS credentials) |
| `generate_sample_identifiers.py` | Generates a synthetic 10-20M row identifier table + proportional probe file | **Run successfully** at small scale (50K rows) during development - output verified: exact row counts, exact match-rate targeting (60.0% requested, 60.0% achieved) |
| `run_poc_checks.py` | Automates the pass/fail evidence for all 4 POC objectives (POC doc Section 5) | `check_terraform_cicd()` **run and verified** (correct exit codes for both pass and fail cases); the other three checks are syntax-checked but need real Databricks/Snowflake/Kinesis credentials to run for real |

## Quickstart (once the POC sandbox from `03-Infra` is deployed)

```bash
pip install boto3 pyarrow databricks-sql-connector snowflake-connector-python requests

# 1. Generate test data
python generate_sample_identifiers.py --identifier-rows 15000000 --output-dir ./poc_data
# upload poc_data/identifiers.parquet to the path resolve_identity.py reads from

# 2. Generate streaming load (run in the background while the pipeline is live)
python generate_synthetic_events.py --stream-name <from 03-Infra 10-foundation output> --rate 175 --duration-seconds 1800

# 3. Collect pass/fail evidence
export DATABRICKS_HOST=... DATABRICKS_HTTP_PATH=... DATABRICKS_TOKEN=...
python run_poc_checks.py --objective streaming --sent-count <printed by step 2>
```

## Honesty note

`generate_sample_identifiers.py` is the only script in this folder that
has actually moved real bytes through real logic during development - it
was run at a reduced scale (50K rows) specifically to verify its output
is correct before being delivered, not just that it parses. The other two
scripts are correct Python using correct, well-documented client library
calls, but have not touched a real Kinesis stream, Databricks workspace,
or Snowflake account, because none of those exist yet for this engagement
- see the top-level README's "Critical gaps" section.
