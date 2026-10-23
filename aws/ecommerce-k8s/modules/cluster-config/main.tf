resource "aws_eks_access_entry" "admin_user" {
  cluster_name  = var.cluster_name
  principal_arn = var.admin_user_arn
  user_name     = var.admin_user_name
  type          = "STANDARD"
  timeouts {
    create = "5m"
    delete = "5m"
  }
}

resource "aws_eks_access_entry" "terraform_role" {
  cluster_name  = var.cluster_name
  principal_arn = var.terraform_role_arn
  user_name     = "terraform-admin"
  type          = "STANDARD"
  timeouts {
    create = "5m"
    delete = "5m"
  }
}

# One policy per principal: cluster admin. (AdminPolicy and AdminViewPolicy
# were also associated; both are subsets of it.)
resource "aws_eks_access_policy_association" "admin_user_cluster_admin_policy" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.admin_user.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
  timeouts {
    create = "5m"
    delete = "5m"
  }
}

resource "aws_eks_access_policy_association" "terraform_role_cluster_admin_policy" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.terraform_role.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
  timeouts {
    create = "5m"
    delete = "5m"
  }
}
