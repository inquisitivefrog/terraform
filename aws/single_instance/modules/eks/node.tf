# File 32: modules/eks/node.tf

# No image_id or user_data: EKS supplies the Amazon Linux 2023 image for the
# cluster version (ami_type below) and bootstraps nodes with nodeadm.
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "eks-ng-${var.env}-${var.random_suffix}"
  instance_type = var.instance_type
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = length(var.node_security_group_ids) > 0 ? var.node_security_group_ids : [var.eks_cluster_sg_id]
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "ng-${var.env}-${var.random_suffix}"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.vpc_subnet_private_ids
  ami_type        = "AL2023_x86_64_STANDARD"
  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = 1
  }
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }
  depends_on = [var.eks_node_policy_attachments]
}
