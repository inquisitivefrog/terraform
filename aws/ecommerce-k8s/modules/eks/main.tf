# EKS writes control-plane logs here. Created first so Terraform owns it and
# deletes it on destroy; otherwise EKS creates it and it outlives the cluster.
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    # trivy:ignore:AWS-0040 kubectl and Terraform run from the laptop; public_access_cidrs limits the API to its /32
    endpoint_public_access = true
    public_access_cidrs    = var.cluster_endpoint_public_access_cidrs
  }
  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }
  enabled_cluster_log_types = var.cluster_enabled_log_types
  depends_on                = [aws_cloudwatch_log_group.cluster]
  access_config {
    # Access entries only: no aws-auth ConfigMap, whose system:masters
    # mappings can't be audited or revoked through the EKS API. One-way: EKS
    # can't switch back to CONFIG_MAP. Managed node groups get their access
    # entry automatically.
    authentication_mode                         = "API"
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

# Pods get IAM roles through EKS Pod Identity, not IRSA: the account's
# organization SCP denies iam:CreateOpenIDConnectProvider. The agent is a
# DaemonSet, so it needs nodes before it can go ACTIVE.
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"
  depends_on   = [aws_eks_node_group.default]
}
