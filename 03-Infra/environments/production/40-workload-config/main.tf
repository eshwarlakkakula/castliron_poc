# Environment: dev | Layer: L4 Workload config
# Cluster policies and instance pools the Asset Bundle pipelines/jobs
# reference by ID - this layer never deploys pipelines or jobs itself
# (those are L5 Workloads, delivered via Databricks Asset Bundles, not
# Terraform - see 04-Pipelines/deploy-asset-bundles.yml).

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "compute_policies" {
  source = "../../../modules/databricks-compute-policies"

  providers = {
    databricks.workspace = databricks.workspace
  }

  name_prefix                = local.name_prefix
  instance_profile_arn       = data.terraform_remote_state.foundation.outputs.databricks_compute_instance_profile_arn
  streaming_max_workers      = var.streaming_max_workers
  batch_max_workers          = var.batch_max_workers
  databricks_runtime_version = var.databricks_runtime_version
  tags                       = var.tags
}
