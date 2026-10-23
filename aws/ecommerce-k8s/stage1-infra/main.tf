module "vpc" {
  source             = "../modules/vpc"
  vpc_name           = "ecommerce-vpc"
  vpc_cidr           = "10.0.0.0/16"
  azs                = ["us-east-2a", "us-east-2b"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  cluster_name       = var.cluster_name
  # Subnet tags for the ALB controller are set inside modules/vpc
}

module "iam" {
  source              = "../modules/iam"
  cluster_name        = var.cluster_name
  terraform_role_name = "terraform-admin"
}

# Encrypts Kubernetes secrets (envelope encryption) and the app bucket.
resource "aws_kms_key" "ecommerce" {
  description             = "${var.cluster_name}: EKS secrets and app bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "ecommerce" {
  name          = "alias/${var.cluster_name}"
  target_key_id = aws_kms_key.ecommerce.key_id
}

module "s3" {
  source       = "../modules/s3"
  bucket_name  = "blue-elephant-ecommerce-app-us-east-2-prod"
  cluster_name = var.cluster_name
  kms_key_arn  = aws_kms_key.ecommerce.arn
}

module "eks" {
  source                               = "../modules/eks"
  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  subnet_ids                           = module.vpc.private_subnets
  cluster_role_arn                     = module.iam.eks_cluster_role_arn
  node_role_arn                        = module.iam.node_role_arn
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types            = var.cluster_enabled_log_types
  node_groups                          = var.node_groups
  kms_key_arn                          = aws_kms_key.ecommerce.arn
  depends_on                           = [module.vpc, module.iam]
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.cluster_name}-alb-controller"
  assume_role_policy = file("${path.module}/../files/iam-alb-controller-role.json") # EKS Pod Identity
}

# Binds the role to the controller's service account (created by stage2's
# Helm release); the Pod Identity agent hands the pod its credentials.
resource "aws_eks_pod_identity_association" "alb_controller" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.alb_controller.arn
}

# Upstream's policy, unmodified: kubernetes-sigs/aws-load-balancer-controller
# docs/install/iam_policy.json at tag v3.6.1, the controller version stage2
# installs (identical to main c250dc4 on 2026-10-23). The v2.9.1 copy lacked
# ec2:GetSecurityGroupsForVpc, which ELB now checks on CreateLoadBalancer.
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
