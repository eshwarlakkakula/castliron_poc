output "streaming_pipeline_policy_id" {
  description = "Cluster policy ID for the streaming pipeline, referenced by the Lakeflow pipeline's Asset Bundle definition"
  value       = databricks_cluster_policy.streaming_pipeline_policy.id
}

output "batch_job_policy_id" {
  description = "Cluster policy ID for batch jobs, referenced by each job's Asset Bundle definition"
  value       = databricks_cluster_policy.batch_job_policy.id
}

output "batch_job_spot_pool_id" {
  description = "Instance pool ID backing batch job clusters"
  value       = databricks_instance_pool.batch_job_spot_pool.id
}
