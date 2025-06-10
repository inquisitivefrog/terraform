# modules/networking/main.tf
resource "aws_security_group_rule" "eks_control_plane_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.cluster_endpoint_public_access_cidrs
  security_group_id = var.cluster_security_group_id
  description       = "Allow ingress to EKS control plane from specified CIDRs"
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

resource "aws_security_group" "app" {
  name        = "${var.cluster_name}-app"
  description = "Security group for e-commerce application"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.cluster_endpoint_public_access_cidrs
    description = "Allow app traffic from specified CIDRs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-app"
  }
}
