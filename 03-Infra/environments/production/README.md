# Production environment

Production uses the exact same 5-layer pattern as `../dev/` - see
`../staging/README.md` for the copy procedure, which is identical for
production except for the values below.

Production-specific values that differ from dev/staging:

- `environment = "production"`
- `single_nat_gateway = false` - one NAT gateway per AZ, no single point
  of failure on the egress path
- `create_kinesis_stream = false`, `existing_stream_name = "<the real
  production stream name>"` - production does **not** create a new Kinesis
  stream; the current-state event stream already exists (Technical
  Approach, Section 2) and `10-foundation` only registers the enhanced
  fan-out consumer against it
- `kinesis_shard_count` - still an open item (Technical Approach, Section
  9): 12 shards were assumed but only support ~12K records/s against a
  ~25K/s burst target. Confirm the real shard count (or move to
  `stream_mode = "ON_DEMAND"`) before applying this layer in production,
  not after
- `streaming_max_workers` / `batch_max_workers` - full production sizing,
  not the ~20% non-production allowance used for dev/staging (Technical
  Approach, Section 4.3)
- `dcr_application_warehouse_size` / `dcr_analysis_warehouse_size` /
  `monthly_credit_quota` - production clean-room sizing (Technical
  Approach, Section 6 / Section 10.2), not the POC's X-Small/25-credit
  planning values

Apply order is the same as every environment: `10-foundation` through
`50-interoperability`, never out of order, and only after `30-governance`
and `50-interoperability` have already been proven in dev and staging.
