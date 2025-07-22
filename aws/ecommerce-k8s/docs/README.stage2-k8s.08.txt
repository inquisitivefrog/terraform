
tim@Tims-MacBook-Pro stage2-k8s % helm repo list eks https://aws.github.io/eks-charts
Error: "helm repo list" accepts no arguments

Usage:  helm repo list [flags]
tim@Tims-MacBook-Pro stage2-k8s % helm repo list                                     
NAME	URL                             
eks 	https://aws.github.io/eks-charts


tim@Tims-MacBook-Pro stage1-infra % terraform state list | grep alb
module.iam.aws_iam_policy.alb_controller_policy
module.iam.aws_iam_role.alb_controller
module.iam.aws_iam_role_policy_attachment.alb_controller_policy
tim@Tims-MacBook-Pro stage1-infra % terraform state show module.iam.aws_iam_policy.alb_controller_policy
# module.iam.aws_iam_policy.alb_controller_policy:
resource "aws_iam_policy" "alb_controller_policy" {
    arn              = "arn:aws:iam::084375569056:policy/ecommerce-cluster-AWSLoadBalancerControllerPolicy"
    attachment_count = 0
    description      = null
    id               = "arn:aws:iam::084375569056:policy/ecommerce-cluster-AWSLoadBalancerControllerPolicy"
    name             = "ecommerce-cluster-AWSLoadBalancerControllerPolicy"
    name_prefix      = null
    path             = "/"
    policy           = jsonencode(
        {
            Statement = [
                {
                    Action   = [
                        "elasticloadbalancing:*",
                        "ec2:Describe*",
                        "iam:CreateServiceLinkedRole",
                        "iam:GetRole",
                        "iam:ListRoles",
                        "waf-regional:*",
                        "wafv2:*",
                        "acm:DescribeCertificate",
                        "acm:ListCertificates",
                        "shield:GetSubscriptionState",
                        "shield:DescribeProtection",
                        "shield:CreateProtection",
                        "shield:DeleteProtection",
                    ]
                    Effect   = "Allow"
                    Resource = "*"
                },
                {
                    Action    = "iam:PassRole"
                    Condition = {
                        StringEquals = {
                            "iam:PassedToService" = "elasticloadbalancing.amazonaws.com"
                        }
                    }
                    Effect    = "Allow"
                    Resource  = "arn:aws:iam::084375569056:role/ecommerce-cluster-alb-controller"
                },
            ]
            Version   = "2012-10-17"
        }
    )
    policy_id        = "ANPARHJJNAKQF5CSBXXCR"
    tags_all         = {}
}
tim@Tims-MacBook-Pro stage1-infra % terraform state show module.iam.aws_iam_role_policy_attachment.alb_controller_policy
# module.iam.aws_iam_role_policy_attachment.alb_controller_policy:
resource "aws_iam_role_policy_attachment" "alb_controller_policy" {
    id         = "ecommerce-cluster-alb-controller-20250623003417836800000018"
    policy_arn = "arn:aws:iam::084375569056:policy/ecommerce-cluster-AWSLoadBalancerControllerPolicy"
    role       = "ecommerce-cluster-alb-controller"
}
tim@Tims-MacBook-Pro stage1-infra % terraform state show module.iam.aws_iam_role.alb_controller                         
# module.iam.aws_iam_role.alb_controller:
resource "aws_iam_role" "alb_controller" {
    arn                   = "arn:aws:iam::084375569056:role/ecommerce-cluster-alb-controller"
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRoleWithWebIdentity"
                    Condition = {
                        StringEquals = {
                            "arn:aws:iam::084375569056:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/E06C1583EBB1BBE865A7024A0381FD48:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
                        }
                    }
                    Effect    = "Allow"
                    Principal = {
                        Federated = "arn:aws:iam::084375569056:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/E06C1583EBB1BBE865A7024A0381FD48"
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
    create_date           = "2025-06-23T00:34:17Z"
    description           = null
    force_detach_policies = false
    id                    = "ecommerce-cluster-alb-controller"
    managed_policy_arns   = []
    max_session_duration  = 3600
    name                  = "ecommerce-cluster-alb-controller"
    name_prefix           = null
    path                  = "/"
    permissions_boundary  = null
    tags_all              = {}
    unique_id             = "AROARHJJNAKQDNC5JSC7L"
}

tim@Tims-MacBook-Pro stage2-k8s % helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "eks" chart repository
Update Complete. ⎈Happy Helming!⎈

tim@Tims-MacBook-Pro stage2-k8s % helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ecommerce-cluster \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::084375569056:role/ecommerce-cluster-alb-controller \
  --set region=us-east-1
NAME: aws-load-balancer-controller
LAST DEPLOYED: Mon Jun 23 11:37:36 2025
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!


