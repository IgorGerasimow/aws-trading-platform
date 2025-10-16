
variable "cluster_name" { type = string }
variable "vpc_id"       { type = string }
variable "subnet_ids"   { type = list(string) }
variable "tags"         { type = map(string) }

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.24"
  cluster_name    = var.cluster_name
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  enable_irsa     = true
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    core = {
      desired_size = 3
      min_size     = 2
      max_size     = 6
      instance_types = ["m7g.large"]
      labels = { role = "core" }
      tags   = var.tags
    }
    nats_ssd = {
      desired_size = 3
      min_size     = 3
      max_size     = 6
      instance_types = ["m7i.large"]
      labels = { role = "nats-jetstream" }
      taints = [{ key="storage", value="nvme", effect="NO_SCHEDULE" }]
      tags   = var.tags
    }
  }
  tags = var.tags
}

output "cluster_name" { value = module.eks.cluster_name }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_security_group_id" { value = module.eks.cluster_security_group_id }
