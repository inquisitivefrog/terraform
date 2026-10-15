module "vpc" {
  source             = "../modules/vpc"
  vpc_name           = "ecommerce-vpc"
  vpc_cidr           = "10.0.0.0/16"
  azs                = ["us-east-1a", "us-east-1b"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  cluster_name       = var.cluster_name
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

module "iam" {
  source              = "../modules/iam"
  cluster_name        = var.cluster_name
  terraform_role_name = "terraform-admin"
}

module "s3" {
  source       = "../modules/s3"
  bucket_name  = "blued-ecommerce-app-us-east-1-prod"
  cluster_name = var.cluster_name
}

module "eks" {
  source                               = "../modules/eks"
  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  vpc_id                               = module.vpc.vpc_id
  subnet_ids                           = module.vpc.private_subnets
  control_plane_subnet_ids             = module.vpc.public_subnets # Use public subnets for control plane
  cluster_role_arn                     = module.iam.eks_cluster_role_arn
  node_role_arn                        = module.iam.node_role_arn
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types            = var.cluster_enabled_log_types
  node_groups                          = var.node_groups
  depends_on                           = [module.vpc, module.iam]
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller"
  assume_role_policy = templatefile("${path.module}/../files/iam-alb-controller-role.json", {
    oidc_provider_arn = module.eks.oidc_provider_arn
    oidc_issuer_id    = replace(module.eks.cluster.identity[0].oidc[0].issuer, "https://", "")
  })
}

resource "aws_iam_policy" "alb_controller_policy" {
  name   = "${var.cluster_name}-AWSLoadBalancerControllerPolicy"
  policy = file("${path.module}/../files/iam-alb-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller_policy" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

module "cluster_access" {
  source             = "../modules/cluster-config"
  cluster_name       = var.cluster_name
  admin_user_arn     = var.admin_user_arn
  admin_user_name    = var.admin_user_name
  terraform_role_arn = module.iam.terraform_role_arn
  eks_cluster        = module.eks.cluster
  depends_on         = [module.eks]
}

module "networking" {
  source                               = "../modules/networking"
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_name                         = var.cluster_name
  cluster_security_group_id            = module.eks.cluster_security_group_id
  region                               = var.region
  private_route_table_ids              = module.vpc.private_route_table_ids
  vpc_id                               = module.vpc.vpc_id
  app_port                             = 80
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "node_role_arn" {
  value = module.iam.node_role_arn
}

output "terraform_role_arn" {
  value = module.iam.terraform_role_arn
}

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller.arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
