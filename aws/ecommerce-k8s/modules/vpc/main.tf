module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "~> 5.8.0"
  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = var.azs
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  # Rejected traffic only, kept a week: enough to debug security groups, for
  # very little CloudWatch cost. The module creates the log group and role,
  # so destroy removes them.
  enable_flow_log                                 = true
  flow_log_traffic_type                           = "REJECT"
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_retention_in_days = 7
  tags                                            = { Name = var.vpc_name }
}
