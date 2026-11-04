module "networking" {
  source = "../../modules/aws-networking-poc"

  name_prefix = var.name_prefix
  tags        = var.tags

  ingress_rules = [
    {
      description = "Aurora MySQL from allowed CIDR blocks"
      from_port   = 3306
      to_port     = 3306
      cidr_blocks = var.aurora_allowed_cidr_blocks
    }
  ]
}

module "s3_storage" {
  source = "../../modules/aws-s3-poc-storage"

  name_prefix = var.name_prefix
  tags        = var.tags
}

module "aurora_mysql" {
  source = "../../modules/aws-aurora-mysql-poc"

  name_prefix            = var.name_prefix
  db_subnet_group_name   = module.networking.db_subnet_group_name
  vpc_security_group_ids = [module.networking.security_group_id]
  min_capacity           = var.aurora_min_capacity
  max_capacity           = var.aurora_max_capacity
  tags                   = var.tags
}

module "kinesis_consumer" {
  source = "../../modules/aws-kinesis-consumer"

  name_prefix   = var.name_prefix
  create_stream = true
  shard_count   = var.kinesis_shard_count
  tags          = var.tags
}

module "databricks_access" {
  source = "../../modules/aws-databricks-poc-access"

  name_prefix        = var.name_prefix
  kinesis_stream_arn = module.kinesis_consumer.stream_arn
  tags               = var.tags

  unity_catalog_storage_bucket_arn       = module.s3_storage.bucket_arn
  databricks_unity_catalog_principal_arn = var.databricks_unity_catalog_principal_arn
  databricks_external_id                 = var.databricks_external_id
}
