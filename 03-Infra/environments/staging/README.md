# Staging environment

Staging uses the exact same 5-layer pattern as `../dev/` -
`backend.tf`, `providers.tf`, `main.tf`, `variables.tf`, and `outputs.tf`
are identical in shape across every environment; only the state key, the
`terraform.tfvars` values, and (for 10-foundation) the NAT gateway and
shard-count sizing actually differ.

To stand up this environment:

1. Copy each layer folder from `../dev/` (`10-foundation` through
   `50-interoperability`), including `backend.tf`, `providers.tf`,
   `main.tf`, `variables.tf`, and `outputs.tf` unchanged except for the
   backend `key` (change `dev/` to `staging/` in every `key =` line and
   every `terraform_remote_state` data source's `key =` line).
2. Copy `terraform.tfvars.example` to `terraform.tfvars` in each layer and
   set staging-specific values - notably:
   - `environment = "staging"`
   - `single_nat_gateway = false` (staging gets one NAT per AZ, matching
     the Technical Approach's non-production sizing more closely than
     dev's cost-minimized single NAT)
   - `kinesis_shard_count` and `batch_max_workers` / `streaming_max_workers`
     sized per the Technical Approach's non-production allowance (~20% of
     production compute, Section 4.3)
   - staging's own `key_administrator_arns`, `databricks_account_id`
     (same account, different workspace), and `monthly_credit_quota`
3. Apply in the same order as dev: `10-foundation` through
   `50-interoperability`, never out of order.

This folder intentionally does not pre-duplicate dev's `.tf` files, so
there is exactly one place (`../dev/`) where the module-wiring pattern is
maintained - copy it fresh each time rather than letting a staging-only
fork of the pattern drift from dev's.
