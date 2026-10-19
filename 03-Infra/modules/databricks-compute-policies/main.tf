# L4 Workload config - cluster policies, instance pools, observability
# Two policies matching Approach 01 from the Technical Approach document:
# an always-on classic+Photon policy for the streaming pipeline, and a
# spot-backed policy for batch jobs (identity resolution, measurement,
# clean-room contribution, reverse-ETL). Both pin the instance profile from
# L1 and the approved node types/runtime so workspace users cannot launch
# unscoped compute.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      version               = "~> 1.50"
      configuration_aliases = [databricks.workspace]
    }
  }
}

resource "databricks_instance_pool" "batch_job_spot_pool" {
  provider           = databricks.workspace
  instance_pool_name = "${var.name_prefix}-batch-job-spot-pool"
  node_type_id       = var.batch_node_type
  min_idle_instances = 0
  max_capacity       = var.batch_max_workers + 1

  aws_attributes {
    availability           = "SPOT_WITH_FALLBACK"
    spot_bid_price_percent = var.spot_bid_price_percent
    zone_id                = "auto"
  }

  idle_instance_autotermination_minutes = 15

  custom_tags = var.tags
}

resource "databricks_cluster_policy" "streaming_pipeline_policy" {
  provider    = databricks.workspace
  name        = "${var.name_prefix}-streaming-pipeline-policy"
  description = "Always-on classic + Photon compute for the Lakeflow streaming pipeline"

  definition = jsonencode({
    "spark_version" = {
      type   = "fixed"
      value  = var.databricks_runtime_version
      hidden = true
    }
    "node_type_id" = {
      type  = "fixed"
      value = var.streaming_driver_node_type
    }
    "driver_node_type_id" = {
      type  = "fixed"
      value = var.streaming_driver_node_type
    }
    "autoscale.min_workers" = {
      type  = "fixed"
      value = 1
    }
    "autoscale.max_workers" = {
      type     = "range"
      maxValue = var.streaming_max_workers
    }
    "aws_attributes.instance_profile_arn" = {
      type   = "fixed"
      value  = var.instance_profile_arn
      hidden = true
    }
    "aws_attributes.availability" = {
      type  = "fixed"
      value = "ON_DEMAND"
    }
    "custom_tags.Workload" = {
      type  = "fixed"
      value = "streaming-pipeline"
    }
  })
}

resource "databricks_cluster_policy" "batch_job_policy" {
  provider    = databricks.workspace
  name        = "${var.name_prefix}-batch-job-policy"
  description = "Spot-backed compute for identity resolution, measurement, clean-room contribution, and reverse-ETL jobs"

  definition = jsonencode({
    "spark_version" = {
      type   = "fixed"
      value  = var.databricks_runtime_version
      hidden = true
    }
    "instance_pool_id" = {
      type  = "fixed"
      value = databricks_instance_pool.batch_job_spot_pool.id
    }
    "autoscale.min_workers" = {
      type  = "fixed"
      value = 1
    }
    "autoscale.max_workers" = {
      type     = "range"
      maxValue = var.batch_max_workers
    }
    "custom_tags.Workload" = {
      type         = "unlimited"
      defaultValue = "batch-job"
    }
  })
}
