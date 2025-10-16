
terraform { source = "../../../modules//vpc" }
locals {
  azs = ["eu-central-1a","eu-central-1b","eu-central-1c"]
}
inputs = {
  name            = "cell-euc1"
  cidr            = "10.10.0.0/16"
  azs             = local.azs
  public_subnets  = ["10.10.0.0/24","10.10.1.0/24","10.10.2.0/24"]
  private_subnets = ["10.10.10.0/24","10.10.11.0/24","10.10.12.0/24"]
  tags = { cell="euc1", env="prod" }
}
