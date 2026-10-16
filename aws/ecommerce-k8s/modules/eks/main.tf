resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }
  enabled_cluster_log_types = var.cluster_enabled_log_types
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }
  tags = {
    "terraform-aws-modules" = "eks"
  }
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "aws_eks_node_group" "default" {
  for_each        = var.node_groups
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }
  instance_types = each.value.instance_types
  ami_type       = "AL2023_x86_64_STANDARD" # AL2 is not supported on EKS 1.33+
  disk_size      = 20
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
