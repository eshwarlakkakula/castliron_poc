# CastIron Media Phase 1 — Terraform

Reusable, version-tagged modules plus one root configuration per layer per
environment, matching the layered delivery model in the Technical Approach
document (Section 7): each layer keeps its own state, so a change in one
layer cannot affect another, and a clean-room (L5) failure cannot touch the
core lakehouse (L2/L3).

## Layout

```
bootstrap/                  L0 - state backend, lock table, CI OIDC role (apply once, manually)
modules/                    Reusable modules - no environment-specific values
  aws-network/
  aws-kms/
  aws-storage/
  aws-iam-databricks/
  aws-kinesis-consumer/
  databricks-workspace/
  databricks-unity-catalog/
  databricks-external-sharing/
  databricks-compute-policies/
  snowflake-clean-room/
environments/
  dev/
    10-foundation/           L1 - network, KMS, storage, IAM, Kinesis consumer
    20-databricks-account/   L2 - Databricks workspace
    30-governance/           L3 - Unity Catalog, external sharing (Iceberg REST)
    40-workload-config/      L4 - cluster policies, instance pools
    50-interoperability/     L5 - Snowflake clean-room provider objects
  staging/                   Same 5 layers - see staging/README.md
  production/                Same 5 layers - see production/README.md
scripts/
  register_clean_room_offering.sql   Run by the deploy-clean-room-offering pipeline, not applied by hand
```

L5 Workloads (the actual Lakeflow pipelines and jobs) are intentionally
**not** here - they deploy through Databricks Asset Bundles, driven by
`04-Pipelines/deploy-asset-bundles.yml`, not Terraform.

## Naming convention

Every resource is named for what it is - `aws_s3_bucket.lakehouse_data_bucket`,
`databricks_catalog.lakehouse_catalogs`, `snowflake_warehouse.dcr_application_warehouse`
- never the generic `"this"` Terraform tutorials default to when there's
only one resource of a type. When you `grep` for a resource in a plan or
state file, the resource label should already tell you what it is.

## Apply order

Within one environment, layers must be applied in order - each reads the
previous layer's outputs via `terraform_remote_state`:

```
bootstrap (once, manually) -> 10-foundation -> 20-databricks-account -> 30-governance -> 40-workload-config -> 50-interoperability
```

`04-Pipelines/terraform-apply.yml` enforces this order as sequential jobs,
not a matrix - a later layer's job does not start until the one before it
succeeds.

## Before the first real apply

1. Databricks must already be subscribed through AWS Marketplace with this
   AWS account linked as the payment method (Technical Approach, Section 7)
   - `20-databricks-account` will fail without this.
2. Apply `bootstrap/` once, manually, with your own AWS credentials (not
   through CI - nothing exists yet for CI to assume into). Record its
   outputs; `environments/*/*/backend.tf` and `providers.tf` assume those
   exact bucket/table/role names.
3. Run `terraform providers schema -json` against each layer after any
   provider version bump, before trusting a plan - the databricks and
   snowflake providers both move fast enough that an attribute or resource
   name can change between minor versions. Every resource in this repo was
   checked against a live schema pull as of the versions pinned in each
   module's `required_providers` block; re-check before upgrading.
4. First `terraform init` in CI will generate `.terraform.lock.hcl` for the
   runner's platform (linux_amd64) - commit it after that first run so
   later runs don't re-resolve provider versions. It is not pre-generated
   in this delivery because a lock file generated on a developer's laptop
   platform would not match the CI runner's platform hashes.
5. `scripts/register_clean_room_offering.sql` has its own "verify before
   running" note - the Clean Rooms native app's exact SQL procedure names
   should be confirmed against the installed app version before the
   pipeline that runs it is trusted beyond a dry run.

## Capability limit

This repository was generated and validated (`terraform fmt`, `terraform
validate`, and live provider-schema checks) without ever running `terraform
apply` - there are no AWS, Databricks, or Snowflake credentials available
in the environment that generated it. Every resource type, attribute name,
and provider requirement has been checked against the real provider schemas;
what has not been checked is an actual deploy. Run `terraform plan` against
a real sandbox account before the first apply, same as you would for any
infrastructure code you did not personally watch deploy before.
