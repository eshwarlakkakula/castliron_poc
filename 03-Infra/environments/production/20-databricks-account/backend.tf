terraform {
  backend "s3" {
    bucket         = "castiron-lakehouse-shared-terraform-state"
    key            = "production/20-databricks-account/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "castiron-lakehouse-shared-terraform-lock"
    kms_key_id     = "alias/castiron-lakehouse-shared-terraform-state"
    encrypt        = true
  }
}

# Reads L1's outputs (VPC, subnets, security group, IAM role, bucket) so
# this layer never redeclares them - a classic remote-state read, not a
# hardcoded copy of L1's values.
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "castiron-lakehouse-shared-terraform-state"
    key    = "production/10-foundation/terraform.tfstate"
    region = "us-east-1"
  }
}
