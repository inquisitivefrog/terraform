# modules/networking/main.tf

resource "aws_security_group" "cluster" {
  name   = "${var.cluster_name}-cluster"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.cluster_name}-cluster"
  }
}

resource "aws_security_group_rule" "app_ingress_http" {
  type              = "ingress"
  from_port         = var.app_port
  to_port           = var.app_port
  protocol          = "tcp"
  security_group_id = var.cluster_security_group_id
  cidr_blocks       = var.cluster_endpoint_public_access_cidrs
}

resource "aws_security_group_rule" "eks_control_plane_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.cluster_security_group_id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = {
    Name = "${var.cluster_name}-s3-endpoint"
  }
}
