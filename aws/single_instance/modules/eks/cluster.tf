# File 32: modules/eks/cluster.tf

# EKS Cluster
resource "aws_eks_cluster" "this" {
  for_each = { for idx, name in var.cluster_names : name => idx }
  name     = "eks-${each.key}-${var.random_suffix}"
  role_arn = var.eks_cluster_role_arn
  version  = var.eks_version
  vpc_config {
    subnet_ids              = var.vpc_subnet_private_ids
    security_group_ids      = [var.eks_cluster_sg_id]
    endpoint_public_access  = false
    endpoint_private_access = true
    public_access_cidrs     = []
  }
  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }
  depends_on = [var.eks_cluster_policy_attachments]
}
