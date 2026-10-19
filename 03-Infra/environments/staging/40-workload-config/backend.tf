terraform {
  backend "s3" {
    bucket         = "castiron-lakehouse-shared-terraform-state"
    key            = "staging/40-workload-config/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "castiron-lakehouse-shared-terraform-lock"
    kms_key_id     = "alias/castiron-lakehouse-shared-terraform-state"
    encrypt        = true
  }
}

data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "castiron-lakehouse-shared-terraform-state"
    key    = "staging/10-foundation/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "databricks_account" {
  backend = "s3"
  config = {
    bucket = "castiron-lakehouse-shared-terraform-state"
    key    = "staging/20-databricks-account/terraform.tfstate"
    region = "us-east-1"
  }
}
