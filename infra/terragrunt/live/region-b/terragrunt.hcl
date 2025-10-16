
locals {
  tags = {
    project = "trading-platform"
    owner   = "infra"
  }
}
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
  terraform {
    required_version = ">= 1.6.0"
    required_providers { aws = { source="hashicorp/aws", version="~> 5.60" } }
  }
  provider "aws" { region = "${local.region}" }
  EOF
}

locals {
  region = "us-east-1"
  azs    = ["us-east-1a","us-east-1b","us-east-1c"]
}
terraform { source = "../../modules//providers" }
