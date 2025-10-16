
dependency "vpc" { config_path = "../vpc" }
terraform { source = "../../../modules//eks" }
inputs = {
  cluster_name = "eks-cell-use1"
  vpc_id       = dependency.vpc.outputs.vpc_id
  subnet_ids   = concat(dependency.vpc.outputs.public_subnet_ids, dependency.vpc.outputs.private_subnet_ids)
  tags         = { cell="use1", env="prod" }
}
