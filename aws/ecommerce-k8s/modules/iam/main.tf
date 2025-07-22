resource "aws_iam_role" "eks" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy" "node_group_elb" {
  name   = "${var.cluster_name}-EKSNodeGroupELBPolicy"
  policy = file("${path.module}/../../files/iam-node-group-elb-policy.json")
}

resource "aws_iam_role_policy_attachment" "node_group_elb" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_group_elb.arn
}

resource "aws_iam_role" "terraform_admin" {
  name               = var.terraform_role_name
  assume_role_policy = file("${path.module}/../../files/iam-role-terraform.json")
}

resource "aws_iam_role_policy_attachment" "terraform_admin_eks_policy" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "terraform_admin_eks_worker_policy" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_policy" "terraform_admin_ec2" {
  name        = "TerraformAdminEC2Policy"
  description = "EC2 policy for terraform-admin role"
  policy      = file("${path.module}/../../files/iam-ec2-policy.json")
}

resource "aws_iam_policy" "terraform_admin_elb_other" {
  name        = "TerraformAdminELBOtherPolicy"
  description = "ELB and other services policy for terraform-admin role"
  policy      = file("${path.module}/../../files/iam-elb-other-policy.json")
}

resource "aws_iam_policy" "terraform_admin_backend" {
  name        = "TerraformAdminBackendPolicy"
  description = "Backend S3 policy for terraform-admin role"
  policy      = file("${path.module}/../../files/iam-backend-policy.json")
}

resource "aws_iam_policy" "terraform_admin_eks" {
  name        = "TerraformAdminEKSPolicy"
  description = "EKS-specific policy for terraform-admin role"
  policy      = file("${path.module}/../../files/iam-eks-policy.json")
}

resource "aws_iam_policy" "terraform_admin_acm" {
  name        = "TerraformAdminACMPolicy"
  description = "ACM policy for terraform-admin role"
  policy      = file("${path.module}/../../files/iam-acm-policy.json")
}

resource "aws_iam_role_policy_attachment" "terraform_admin_ec2_attachment" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = aws_iam_policy.terraform_admin_ec2.arn
}

resource "aws_iam_role_policy_attachment" "terraform_admin_elb_other_attachment" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = aws_iam_policy.terraform_admin_elb_other.arn
}

resource "aws_iam_role_policy_attachment" "terraform_admin_backend_attachment" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = aws_iam_policy.terraform_admin_backend.arn
}

resource "aws_iam_role_policy_attachment" "terraform_admin_eks_attachment" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = aws_iam_policy.terraform_admin_eks.arn
}

resource "aws_iam_role_policy_attachment" "terraform_admin_acm_attachment" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = aws_iam_policy.terraform_admin_acm.arn
}
