# File 32: modules/eks/cluster.tf

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = "eks-${var.env}-${var.random_suffix}"
  role_arn = var.eks_cluster_role_arn
  version  = var.eks_version
  vpc_config {
    subnet_ids         = var.vpc_subnet_private_ids
    security_group_ids = [var.eks_cluster_sg_id]
    # Public endpoint limited to public_access_cidrs (your laptop) so Terraform
    # and kubectl can run from outside the VPC; nodes use the private endpoint.
    # trivy:ignore:AWS-0040 public endpoint is limited to public_access_cidrs (laptop /32)
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = var.public_access_cidrs
  }
  # aws-auth ConfigMap controls access; the IAM identity that creates the
  # cluster (the one running terraform apply) is also a cluster admin.
  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }
  depends_on = [var.eks_cluster_policy_attachments]
}
