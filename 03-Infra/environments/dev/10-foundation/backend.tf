terraform {
  backend "s3" {
    # Values below come from the L0 bootstrap outputs - never hardcode a
    # different bucket/table here than bootstrap created for this account.
    bucket         = "castiron-lakehouse-shared-terraform-state"
    key            = "dev/10-foundation/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "castiron-lakehouse-shared-terraform-lock"
    kms_key_id     = "alias/castiron-lakehouse-shared-terraform-state"
    encrypt        = true
  }
}
