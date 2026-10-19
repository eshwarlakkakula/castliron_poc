terraform {
  backend "s3" {
    bucket         = "castiron-lakehouse-shared-terraform-state"
    key            = "production/50-interoperability/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "castiron-lakehouse-shared-terraform-lock"
    kms_key_id     = "alias/castiron-lakehouse-shared-terraform-state"
    encrypt        = true
  }
}

data "terraform_remote_state" "databricks_account" {
  backend = "s3"
  config = {
    bucket = "castiron-lakehouse-shared-terraform-state"
    key    = "production/20-databricks-account/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "governance" {
  backend = "s3"
  config = {
    bucket = "castiron-lakehouse-shared-terraform-state"
    key    = "production/30-governance/terraform.tfstate"
    region = "us-east-1"
  }
}
