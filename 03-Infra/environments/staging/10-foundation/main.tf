# Environment: dev | Layer: L1 AWS foundation
# Wires the aws-network, aws-kms, aws-storage, aws-kinesis-consumer, and
# aws-iam-databricks modules together for this environment. This is the
# pattern staging and production copy - only backend.tf's state key and
# this file's terraform.tfvars differ between environments.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "network" {
  source = "../../../modules/aws-network"

  name_prefix                = local.name_prefix
  vpc_cidr_block             = var.vpc_cidr_block
  availability_zones         = var.availability_zones
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
  public_subnet_cidr_blocks  = var.public_subnet_cidr_blocks
  single_nat_gateway         = var.single_nat_gateway
  tags                       = var.tags
}

module "kms" {
  source = "../../../modules/aws-kms"

  name_prefix            = local.name_prefix
  key_administrator_arns = var.key_administrator_arns
  key_user_arns          = var.key_user_arns
  tags                   = var.tags
}

module "storage" {
  source = "../../../modules/aws-storage"

  name_prefix           = local.name_prefix
  lakehouse_kms_key_arn = module.kms.lakehouse_data_key_arn
  tags                  = var.tags
}

module "kinesis_consumer" {
  source = "../../../modules/aws-kinesis-consumer"

  name_prefix   = local.name_prefix
  create_stream = var.create_kinesis_stream
  shard_count   = var.kinesis_shard_count
  tags          = var.tags
}

module "iam_databricks" {
  source = "../../../modules/aws-iam-databricks"

  name_prefix               = local.name_prefix
  databricks_account_id     = var.databricks_account_id
  lakehouse_data_bucket_arn = module.storage.lakehouse_data_bucket_arn
  lakehouse_kms_key_arn     = module.kms.lakehouse_data_key_arn
  kinesis_stream_arn        = module.kinesis_consumer.stream_arn
  tags                      = var.tags
}
