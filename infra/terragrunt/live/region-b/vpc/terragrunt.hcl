
terraform { source = "../../../modules//vpc" }
locals { azs = ["us-east-1a","us-east-1b","us-east-1c"] }
inputs = {
  name            = "cell-use1"
  cidr            = "10.20.0.0/16"
  azs             = local.azs
  public_subnets  = ["10.20.0.0/24","10.20.1.0/24","10.20.2.0/24"]
  private_subnets = ["10.20.10.0/24","10.20.11.0/24","10.20.12.0/24"]
  tags = { cell="use1", env="prod" }
}
