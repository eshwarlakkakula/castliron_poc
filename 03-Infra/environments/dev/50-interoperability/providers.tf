terraform {
  required_version = ">= 1.7.0"
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.95"
    }
  }
}

# Credentials come from SNOWFLAKE_ACCOUNT / SNOWFLAKE_USER /
# SNOWFLAKE_PRIVATE_KEY (key-pair auth, no password) set by the GitHub
# Actions workflow from repository secrets - never hardcoded here.
provider "snowflake" {
  role = "SYSADMIN"
}
