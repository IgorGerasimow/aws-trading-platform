
dependency "vpc" { config_path = "../vpc" }
terraform { source = "../../../modules//nlb" }
inputs = {
  name       = "nlb-bff-euc1"
  subnet_ids = dependency.vpc.outputs.public_subnet_ids
  tags       = { cell="euc1", env="prod" }
}
