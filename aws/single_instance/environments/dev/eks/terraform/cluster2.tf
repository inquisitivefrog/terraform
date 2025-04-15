module "eks_cluster2" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "eks-cluster2"
  cluster_version = "1.29"
  vpc_id          = "YOUR_VPC_ID"
  subnet_ids      = ["SUBNET_ID1", "SUBNET_ID2"]
  enable_irsa     = true

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 2
      instance_types = ["t3.medium"]
    }
  }
}

# Output kubeconfig
output "cluster2_kubeconfig" {
  value = module.eks_cluster2.kubeconfig
}
