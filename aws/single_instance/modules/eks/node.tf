# File 32: modules/eks/node.tf

resource "aws_launch_template" "eks_nodes" {
  for_each      = { for idx, name in var.cluster_names : name => idx }
  name_prefix   = "eks-ng-${each.key}-${var.random_suffix}"
  image_id      = "ami-08113a8b76e84a784"
  instance_type = var.instance_type
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -ex
    /etc/eks/bootstrap.sh eks-${each.key}-${var.random_suffix} --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup-image=ami-08113a8b76e84a784,eks.amazonaws.com/capacityType=ON_DEMAND,eks.amazonaws.com/nodegroup=ng-${each.key}-${var.random_suffix} --max-pods=17'
    EOF
  )
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
  for_each        = { for idx, name in var.cluster_names : name => idx }
  cluster_name    = aws_eks_cluster.this[each.key].name
  node_group_name = "ng-${each.key}-${var.random_suffix}"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.vpc_subnet_private_ids
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
  launch_template {
    id      = aws_launch_template.eks_nodes[each.key].id
    version = "$Latest"
  }
  depends_on = [var.eks_node_policy_attachments]
}
