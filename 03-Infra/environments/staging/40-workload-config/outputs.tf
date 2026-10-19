output "streaming_pipeline_policy_id" {
  value = module.compute_policies.streaming_pipeline_policy_id
}

output "batch_job_policy_id" {
  value = module.compute_policies.batch_job_policy_id
}

output "batch_job_spot_pool_id" {
  value = module.compute_policies.batch_job_spot_pool_id
}
