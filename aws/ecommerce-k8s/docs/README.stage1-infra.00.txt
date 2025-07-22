
tim@Tims-MacBook-Pro ~ % aws iam list-user-policies --user-name bluedragon
{
    "PolicyNames": [
        "BraketSearchJobs",
        "KMS-admin",
        "TerraformStateAccess"
    ]
}
tim@Tims-MacBook-Pro ~ % aws iam list-roles --query "Roles[].RoleName" | grep AWSServiceRoleFor
    "AWSServiceRoleForAmazonBraket",
    "AWSServiceRoleForAmazonEKS",
    "AWSServiceRoleForAmazonEKSNodegroup",
    "AWSServiceRoleForAmazonElasticFileSystem",
    "AWSServiceRoleForAmazonEMRServerless",
    "AWSServiceRoleForAmazonSageMakerNotebooks",
    "AWSServiceRoleForAutoScaling",
    "AWSServiceRoleForECS",
    "AWSServiceRoleForElastiCache",
    "AWSServiceRoleForElasticLoadBalancing",
    "AWSServiceRoleForNetworkFirewall",
    "AWSServiceRoleForOrganizations",
    "AWSServiceRoleForServiceQuotas",
    "AWSServiceRoleForSupport",
    "AWSServiceRoleForTrustedAdvisor"

tim@Tims-MacBook-Pro ~ % aws s3 mb s3://bluedragon-ecommerce-terraform-state --region us-east-1
make_bucket: bluedragon-ecommerce-terraform-state


tim@Tims-MacBook-Pro stage1-infra % aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 --region us-east-1 --profile default
{
    "TableDescription": {
        "AttributeDefinitions": [
            {
                "AttributeName": "LockID",
                "AttributeType": "S"
            }
        ],
        "TableName": "terraform-state-lock",
        "KeySchema": [
            {
                "AttributeName": "LockID",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "CREATING",
        "CreationDateTime": "2025-06-22T17:19:00.291000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 1,
            "WriteCapacityUnits": 1
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-east-1:084375569056:table/terraform-state-lock",
        "TableId": "55e3ea42-b470-4de2-ae30-6c94d2b777d3",
        "DeletionProtectionEnabled": false
    }
}
tim@Tims-MacBook-Pro stage1-infra % aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1 --profile default 
{
    "Table": {
        "AttributeDefinitions": [
            {
                "AttributeName": "LockID",
                "AttributeType": "S"
            }
        ],
        "TableName": "terraform-state-lock",
        "KeySchema": [
            {
                "AttributeName": "LockID",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "ACTIVE",
        "CreationDateTime": "2025-06-22T17:19:00.291000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 1,
            "WriteCapacityUnits": 1
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-east-1:084375569056:table/terraform-state-lock",
        "TableId": "55e3ea42-b470-4de2-ae30-6c94d2b777d3",
        "DeletionProtectionEnabled": false
    }
}

tim@Tims-MacBook-Pro stage1-infra % rm -rf .terraform .terraform.lock.hcl      
tim@Tims-MacBook-Pro stage1-infra % terraform init -backend-config=backend.hcl 
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing modules...
Downloading registry.terraform.io/terraform-aws-modules/eks/aws 20.36.1 for eks...
- eks in .terraform/modules/eks
- eks.eks_managed_node_group in .terraform/modules/eks/modules/eks-managed-node-group
- eks.eks_managed_node_group.user_data in .terraform/modules/eks/modules/_user_data
- eks.fargate_profile in .terraform/modules/eks/modules/fargate-profile
Downloading registry.terraform.io/terraform-aws-modules/kms/aws 2.1.0 for eks.kms...
- eks.kms in .terraform/modules/eks.kms
- eks.self_managed_node_group in .terraform/modules/eks/modules/self-managed-node-group
- eks.self_managed_node_group.user_data in .terraform/modules/eks/modules/_user_data
- iam in ../modules/iam
- networking in ../modules/networking
- s3 in ../modules/s3
Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 5.8.1 for vpc...
- vpc in .terraform/modules/vpc
Initializing provider plugins...
- Finding hashicorp/aws versions matching ">= 4.33.0, >= 5.30.0, >= 5.95.0, ~> 5.95.0"...
- Finding hashicorp/cloudinit versions matching ">= 2.0.0, >= 2.3.7"...
- Finding hashicorp/null versions matching ">= 3.0.0"...
- Finding hashicorp/time versions matching ">= 0.9.0, >= 0.13.1"...
- Finding hashicorp/tls versions matching ">= 3.0.0, >= 4.1.0"...
- Installing hashicorp/cloudinit v2.3.7...
- Installed hashicorp/cloudinit v2.3.7 (signed by HashiCorp)
- Installing hashicorp/null v3.2.4...
- Installed hashicorp/null v3.2.4 (signed by HashiCorp)
- Installing hashicorp/time v0.13.1...
- Installed hashicorp/time v0.13.1 (signed by HashiCorp)
- Installing hashicorp/tls v4.1.0...
- Installed hashicorp/tls v4.1.0 (signed by HashiCorp)
- Installing hashicorp/aws v5.95.0...
- Installed hashicorp/aws v5.95.0 (signed by HashiCorp)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
tim@Tims-MacBook-Pro stage1-infra % terraform validate                         
Success! The configuration is valid.


tim@Tims-MacBook-Pro stage1-infra % aws s3 ls --region us-east-1
2025-06-22 16:45:54 bluedragon-ecommerce-terraform-state

tim@Tims-MacBook-Pro stage1-infra % terraform plan -out=tfplan                                  
module.eks.data.aws_iam_policy_document.assume_role_policy[0]: Reading...
module.eks.module.eks_managed_node_group["default"].data.aws_caller_identity.current: Reading...
module.eks.module.eks_managed_node_group["default"].data.aws_partition.current: Reading...
module.eks.module.kms.data.aws_partition.current[0]: Reading...
module.eks.module.eks_managed_node_group["default"].data.aws_iam_policy_document.assume_role_policy[0]: Reading...
module.eks.data.aws_caller_identity.current[0]: Reading...
module.eks.module.kms.data.aws_partition.current[0]: Read complete after 0s [id=aws]
module.eks.data.aws_iam_policy_document.assume_role_policy[0]: Read complete after 0s [id=2830595799]
module.eks.module.eks_managed_node_group["default"].data.aws_iam_policy_document.assume_role_policy[0]: Read complete after 0s [id=2560088296]
module.eks.module.eks_managed_node_group["default"].data.aws_partition.current: Read complete after 0s [id=aws]
module.eks.data.aws_partition.current[0]: Reading...
module.eks.module.kms.data.aws_caller_identity.current[0]: Reading...
module.eks.data.aws_partition.current[0]: Read complete after 0s [id=aws]
module.eks.data.aws_iam_policy_document.custom[0]: Reading...
module.eks.data.aws_iam_policy_document.custom[0]: Read complete after 0s [id=513122117]
module.eks.module.eks_managed_node_group["default"].data.aws_caller_identity.current: Read complete after 0s [id=084375569056]
module.eks.data.aws_caller_identity.current[0]: Read complete after 0s [id=084375569056]
module.eks.data.aws_iam_session_context.current[0]: Reading...
module.eks.data.aws_iam_session_context.current[0]: Read complete after 0s [id=arn:aws:iam::084375569056:user/bluedragon]
module.eks.module.kms.data.aws_caller_identity.current[0]: Read complete after 0s [id=084375569056]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # module.eks.data.tls_certificate.this[0] will be read during apply
  # (config refers to values not yet known)
 <= data "tls_certificate" "this" {
      + certificates = (known after apply)
      + id           = (known after apply)
      + url          = (known after apply)
    }

  # module.eks.aws_cloudwatch_log_group.this[0] will be created
  + resource "aws_cloudwatch_log_group" "this" {
      + arn               = (known after apply)
      + id                = (known after apply)
      + log_group_class   = (known after apply)
      + name              = "/aws/eks/ecommerce-cluster/cluster"
      + name_prefix       = (known after apply)
      + retention_in_days = 90
      + skip_destroy      = false
      + tags              = {
          + "Name" = "/aws/eks/ecommerce-cluster/cluster"
        }
      + tags_all          = {
          + "Name" = "/aws/eks/ecommerce-cluster/cluster"
        }
    }

  # module.eks.aws_eks_access_entry.this["admin_user"] will be created
  + resource "aws_eks_access_entry" "this" {
      + access_entry_arn  = (known after apply)
      + cluster_name      = (known after apply)
      + created_at        = (known after apply)
      + id                = (known after apply)
      + kubernetes_groups = (known after apply)
      + modified_at       = (known after apply)
      + principal_arn     = "arn:aws:iam::084375569056:user/bluedragon"
      + tags_all          = (known after apply)
      + type              = "STANDARD"
      + user_name         = (known after apply)
    }

  # module.eks.aws_eks_access_entry.this["terraform_role"] will be created
  + resource "aws_eks_access_entry" "this" {
      + access_entry_arn  = (known after apply)
      + cluster_name      = (known after apply)
      + created_at        = (known after apply)
      + id                = (known after apply)
      + kubernetes_groups = (known after apply)
      + modified_at       = (known after apply)
      + principal_arn     = (known after apply)
      + tags_all          = (known after apply)
      + type              = "STANDARD"
      + user_name         = (known after apply)
    }

  # module.eks.aws_eks_access_policy_association.this["admin_user_admin_policy"] will be created
  + resource "aws_eks_access_policy_association" "this" {
      + associated_at = (known after apply)
      + cluster_name  = (known after apply)
      + id            = (known after apply)
      + modified_at   = (known after apply)
      + policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
      + principal_arn = "arn:aws:iam::084375569056:user/bluedragon"

      + access_scope {
          + type = "cluster"
        }
    }

  # module.eks.aws_eks_access_policy_association.this["admin_user_cluster_admin_policy"] will be created
  + resource "aws_eks_access_policy_association" "this" {
      + associated_at = (known after apply)
      + cluster_name  = (known after apply)
      + id            = (known after apply)
      + modified_at   = (known after apply)
      + policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      + principal_arn = "arn:aws:iam::084375569056:user/bluedragon"

      + access_scope {
          + type = "cluster"
        }
    }

  # module.eks.aws_eks_access_policy_association.this["admin_user_view_policy"] will be created
  + resource "aws_eks_access_policy_association" "this" {
      + associated_at = (known after apply)
      + cluster_name  = (known after apply)
      + id            = (known after apply)
      + modified_at   = (known after apply)
      + policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
      + principal_arn = "arn:aws:iam::084375569056:user/bluedragon"

      + access_scope {
          + type = "cluster"
        }
    }

  # module.eks.aws_eks_access_policy_association.this["terraform_role_admin_policy"] will be created
  + resource "aws_eks_access_policy_association" "this" {
      + associated_at = (known after apply)
      + cluster_name  = (known after apply)
      + id            = (known after apply)
      + modified_at   = (known after apply)
      + policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
      + principal_arn = (known after apply)

      + access_scope {
          + type = "cluster"
        }
    }

  # module.eks.aws_eks_access_policy_association.this["terraform_role_cluster_admin_policy"] will be created
  + resource "aws_eks_access_policy_association" "this" {
      + associated_at = (known after apply)
      + cluster_name  = (known after apply)
      + id            = (known after apply)
      + modified_at   = (known after apply)
      + policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      + principal_arn = (known after apply)

      + access_scope {
          + type = "cluster"
        }
    }

  # module.eks.aws_eks_cluster.this[0] will be created
  + resource "aws_eks_cluster" "this" {
      + arn                           = (known after apply)
      + bootstrap_self_managed_addons = true
      + certificate_authority         = (known after apply)
      + cluster_id                    = (known after apply)
      + created_at                    = (known after apply)
      + enabled_cluster_log_types     = [
          + "api",
          + "audit",
          + "authenticator",
          + "controllerManager",
          + "scheduler",
        ]
      + endpoint                      = (known after apply)
      + id                            = (known after apply)
      + identity                      = (known after apply)
      + name                          = "ecommerce-cluster"
      + platform_version              = (known after apply)
      + role_arn                      = (known after apply)
      + status                        = (known after apply)
      + tags                          = {
          + "terraform-aws-modules" = "eks"
        }
      + tags_all                      = {
          + "terraform-aws-modules" = "eks"
        }
      + version                       = "1.29"

      + access_config {
          + authentication_mode                         = "API_AND_CONFIG_MAP"
          + bootstrap_cluster_creator_admin_permissions = false
        }

      + encryption_config {
          + resources = [
              + "secrets",
            ]

          + provider {
              + key_arn = (known after apply)
            }
        }

      + kubernetes_network_config {
          + ip_family         = "ipv4"
          + service_ipv4_cidr = (known after apply)
          + service_ipv6_cidr = (known after apply)

          + elastic_load_balancing (known after apply)
        }

      + timeouts {}

      + upgrade_policy (known after apply)

      + vpc_config {
          + cluster_security_group_id = (known after apply)
          + endpoint_private_access   = true
          + endpoint_public_access    = true
          + public_access_cidrs       = [
              + "23.93.84.244/32",
            ]
          + security_group_ids        = (known after apply)
          + subnet_ids                = (known after apply)
          + vpc_id                    = (known after apply)
        }
    }

  # module.eks.aws_iam_openid_connect_provider.oidc_provider[0] will be created
  + resource "aws_iam_openid_connect_provider" "oidc_provider" {
      + arn             = (known after apply)
      + client_id_list  = [
          + "sts.amazonaws.com",
        ]
      + id              = (known after apply)
      + tags            = {
          + "Name" = "ecommerce-cluster-eks-irsa"
        }
      + tags_all        = {
          + "Name" = "ecommerce-cluster-eks-irsa"
        }
      + thumbprint_list = (known after apply)
      + url             = (known after apply)
    }

  # module.eks.aws_iam_policy.cluster_encryption[0] will be created
  + resource "aws_iam_policy" "cluster_encryption" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "Cluster encryption policy to allow cluster role to utilize CMK provided"
      + id               = (known after apply)
      + name             = (known after apply)
      + name_prefix      = "ecommerce-cluster-cluster-ClusterEncryption"
      + path             = "/"
      + policy           = (known after apply)
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.eks.aws_iam_policy.custom[0] will be created
  + resource "aws_iam_policy" "custom" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + id               = (known after apply)
      + name             = (known after apply)
      + name_prefix      = "ecommerce-cluster-cluster-"
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = [
                          + "ec2:RunInstances",
                          + "ec2:CreateLaunchTemplate",
                          + "ec2:CreateFleet",
                        ]
                      + Condition = {
                          + StringEquals = {
                              + "aws:RequestTag/eks:eks-cluster-name" = "${aws:PrincipalTag/eks:eks-cluster-name}"
                            }
                          + StringLike   = {
                              + "aws:RequestTag/eks:kubernetes-node-class-name" = "*"
                              + "aws:RequestTag/eks:kubernetes-node-pool-name"  = "*"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                      + Sid       = "Compute"
                    },
                  + {
                      + Action    = [
                          + "ec2:CreateVolume",
                          + "ec2:CreateSnapshot",
                        ]
                      + Condition = {
                          + StringEquals = {
                              + "aws:RequestTag/eks:eks-cluster-name" = "${aws:PrincipalTag/eks:eks-cluster-name}"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = [
                          + "arn:aws:ec2:*:*:volume/*",
                          + "arn:aws:ec2:*:*:snapshot/*",
                        ]
                      + Sid       = "Storage"
                    },
                  + {
                      + Action    = "ec2:CreateNetworkInterface"
                      + Condition = {
                          + StringEquals = {
                              + "aws:RequestTag/eks:eks-cluster-name"         = "${aws:PrincipalTag/eks:eks-cluster-name}"
                              + "aws:RequestTag/eks:kubernetes-cni-node-name" = "*"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                      + Sid       = "Networking"
                    },
                  + {
                      + Action    = [
                          + "elasticloadbalancing:CreateTargetGroup",
                          + "elasticloadbalancing:CreateRule",
                          + "elasticloadbalancing:CreateLoadBalancer",
                          + "elasticloadbalancing:CreateListener",
                          + "ec2:CreateSecurityGroup",
                        ]
                      + Condition = {
                          + StringEquals = {
                              + "aws:RequestTag/eks:eks-cluster-name" = "${aws:PrincipalTag/eks:eks-cluster-name}"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                      + Sid       = "LoadBalancer"
                    },
                  + {
                      + Action    = "shield:CreateProtection"
                      + Condition = {
                          + StringEquals = {
                              + "aws:RequestTag/eks:eks-cluster-name" = "${aws:PrincipalTag/eks:eks-cluster-name}"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                      + Sid       = "ShieldProtection"
                    },
                  + {
                      + Action    = "shield:TagResource"
                      + Condition = {
                          + StringEquals = {
                              + "aws:RequestTag/eks:eks-cluster-name" = "${aws:PrincipalTag/eks:eks-cluster-name}"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:shield::*:protection/*"
                      + Sid       = "ShieldTagResource"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.eks.aws_iam_role.this[0] will be created
  + resource "aws_iam_role" "this" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = [
                          + "sts:TagSession",
                          + "sts:AssumeRole",
                        ]
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "eks.amazonaws.com"
                        }
                      + Sid       = "EKSClusterAssumeRole"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = true
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = (known after apply)
      + name_prefix           = "ecommerce-cluster-cluster-"
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.eks.aws_iam_role_policy_attachment.cluster_encryption[0] will be created
  + resource "aws_iam_role_policy_attachment" "cluster_encryption" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = (known after apply)
    }

  # module.eks.aws_iam_role_policy_attachment.custom[0] will be created
  + resource "aws_iam_role_policy_attachment" "custom" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = (known after apply)
    }

  # module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"] will be created
  + resource "aws_iam_role_policy_attachment" "this" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      + role       = (known after apply)
    }

  # module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"] will be created
  + resource "aws_iam_role_policy_attachment" "this" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
      + role       = (known after apply)
    }

  # module.eks.aws_security_group.cluster[0] will be created
  + resource "aws_security_group" "cluster" {
      + arn                    = (known after apply)
      + description            = "EKS cluster security group"
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = (known after apply)
      + name_prefix            = "ecommerce-cluster-cluster-"
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Name" = "ecommerce-cluster-cluster"
        }
      + tags_all               = {
          + "Name" = "ecommerce-cluster-cluster"
        }
      + vpc_id                 = (known after apply)
    }

  # module.eks.aws_security_group.node[0] will be created
  + resource "aws_security_group" "node" {
      + arn                    = (known after apply)
      + description            = "EKS node shared security group"
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = (known after apply)
      + name_prefix            = "ecommerce-cluster-node-"
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Name"                                    = "ecommerce-cluster-node"
          + "kubernetes.io/cluster/ecommerce-cluster" = "owned"
        }
      + tags_all               = {
          + "Name"                                    = "ecommerce-cluster-node"
          + "kubernetes.io/cluster/ecommerce-cluster" = "owned"
        }
      + vpc_id                 = (known after apply)
    }

  # module.eks.aws_security_group_rule.cluster["ingress_nodes_443"] will be created
  + resource "aws_security_group_rule" "cluster" {
      + description              = "Node groups to cluster API"
      + from_port                = 443
      + id                       = (known after apply)
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = false
      + source_security_group_id = (known after apply)
      + to_port                  = 443
      + type                     = "ingress"
    }

  # module.eks.aws_security_group_rule.node["egress_all"] will be created
  + resource "aws_security_group_rule" "node" {
      + cidr_blocks              = [
          + "0.0.0.0/0",
        ]
      + description              = "Allow all egress"
      + from_port                = 0
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "-1"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = false
      + source_security_group_id = (known after apply)
      + to_port                  = 0
      + type                     = "egress"
    }

  # module.eks.aws_security_group_rule.node["ingress_cluster_443"] will be created
  + resource "aws_security_group_rule" "node" {
      + description              = "Cluster API to node groups"
      + from_port                = 443
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = false
      + source_security_group_id = (known after apply)
      + to_port                  = 443
      + type                     = "ingress"
    }

  # module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"] will be created
  + resource "aws_security_group_rule" "node" {
      + description              = "Cluster API to node 4443/tcp webhook"
      + from_port                = 4443
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = false
      + source_security_group_id = (known after apply)
      + to_port                  = 4443
      + type                     = "ingress"
    }

  # module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"] will be created
  + resource "aws_security_group_rule" "node" {
      + description              = "Cluster API to node 6443/tcp webhook"
      + from_port                = 6443
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = false
      + source_security_group_id = (known after apply)
      + to_port                  = 6443
      + type                     = "ingress"
    }

  # module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"] will be created
  + resource "aws_security_group_rule" "node" {
      + description              = "Cluster API to node 8443/tcp webhook"
      + from_port                = 8443
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = false
      + source_security_group_id = (known after apply)
      + to_port                  = 8443
      + type                     = "ingress"
    }

  # module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"] will be created
  + resource "aws_security_group_rule" "node" {
      + description              = "Cluster API to node 9443/tcp webhook"
      + from_port                = 9443
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = false
      + source_security_group_id = (known after apply)
      + to_port                  = 9443
      + type                     = "ingress"
    }

  # module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"] will be created
  + resource "aws_security_group_rule" "node" {
      + description              = "Cluster API to node kubelets"
      + from_port                = 10250
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = false
      + source_security_group_id = (known after apply)
      + to_port                  = 10250
      + type                     = "ingress"
    }

  # module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"] will be created
  + resource "aws_security_group_rule" "node" {
      + description              = "Node to node ingress on ephemeral ports"
      + from_port                = 1025
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = true
      + source_security_group_id = (known after apply)
      + to_port                  = 65535
      + type                     = "ingress"
    }

  # module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"] will be created
  + resource "aws_security_group_rule" "node" {
      + description              = "Node to node CoreDNS"
      + from_port                = 53
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = true
      + source_security_group_id = (known after apply)
      + to_port                  = 53
      + type                     = "ingress"
    }

  # module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"] will be created
  + resource "aws_security_group_rule" "node" {
      + description              = "Node to node CoreDNS UDP"
      + from_port                = 53
      + id                       = (known after apply)
      + prefix_list_ids          = []
      + protocol                 = "udp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = true
      + source_security_group_id = (known after apply)
      + to_port                  = 53
      + type                     = "ingress"
    }

  # module.eks.time_sleep.this[0] will be created
  + resource "time_sleep" "this" {
      + create_duration = "30s"
      + id              = (known after apply)
      + triggers        = {
          + "cluster_certificate_authority_data" = (known after apply)
          + "cluster_endpoint"                   = (known after apply)
          + "cluster_name"                       = (known after apply)
          + "cluster_service_cidr"               = (known after apply)
          + "cluster_version"                    = "1.29"
        }
    }

  # module.iam.aws_iam_policy.alb_controller_policy will be created
  + resource "aws_iam_policy" "alb_controller_policy" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + id               = (known after apply)
      + name             = "ecommerce-cluster-AWSLoadBalancerControllerPolicy"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "elasticloadbalancing:*",
                          + "ec2:Describe*",
                          + "iam:CreateServiceLinkedRole",
                          + "iam:GetRole",
                          + "iam:ListRoles",
                          + "waf-regional:*",
                          + "wafv2:*",
                          + "acm:DescribeCertificate",
                          + "acm:ListCertificates",
                          + "shield:GetSubscriptionState",
                          + "shield:DescribeProtection",
                          + "shield:CreateProtection",
                          + "shield:DeleteProtection",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action    = "iam:PassRole"
                      + Condition = {
                          + StringEquals = {
                              + "iam:PassedToService" = "elasticloadbalancing.amazonaws.com"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:iam::084375569056:role/ecommerce-cluster-alb-controller"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.iam.aws_iam_policy.node_group_elb will be created
  + resource "aws_iam_policy" "node_group_elb" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + id               = (known after apply)
      + name             = "ecommerce-cluster-EKSNodeGroupELBPolicy"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "elasticloadbalancing:DescribeLoadBalancers",
                          + "elasticloadbalancing:DescribeLoadBalancerAttributes",
                          + "elasticloadbalancing:DescribeTargetGroups",
                          + "elasticloadbalancing:DescribeTargetHealth",
                          + "elasticloadbalancing:DescribeTags",
                          + "elasticloadbalancing:DescribeTargetGroupAttributes",
                          + "elasticloadbalancing:ModifyTargetGroupAttributes",
                          + "elasticloadbalancing:CreateLoadBalancer",
                          + "elasticloadbalancing:CreateTargetGroup",
                          + "elasticloadbalancing:DeleteLoadBalancer",
                          + "elasticloadbalancing:DeleteTargetGroup",
                          + "elasticloadbalancing:ModifyLoadBalancerAttributes",
                          + "elasticloadbalancing:ModifyTargetGroup",
                          + "elasticloadbalancing:RegisterTargets",
                          + "elasticloadbalancing:DeregisterTargets",
                          + "elasticloadbalancing:AddTags",
                          + "elasticloadbalancing:RemoveTags",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action   = [
                          + "ec2:DescribeSubnets",
                          + "ec2:DescribeVpcs",
                          + "ec2:DescribeSecurityGroups",
                          + "ec2:DescribeAvailabilityZones",
                          + "ec2:CreateSecurityGroup",
                          + "ec2:AuthorizeSecurityGroupIngress",
                          + "ec2:AuthorizeSecurityGroupEgress",
                          + "ec2:RevokeSecurityGroupIngress",
                          + "ec2:RevokeSecurityGroupEgress",
                          + "ec2:DeleteSecurityGroup",
                          + "ec2:CreateTags",
                          + "ec2:DescribeTags",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action   = "shield:GetSubscriptionState"
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.iam.aws_iam_policy.terraform_admin_backend will be created
  + resource "aws_iam_policy" "terraform_admin_backend" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "Backend S3 policy for terraform-admin role"
      + id               = (known after apply)
      + name             = "TerraformAdminBackendPolicy"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "s3:PutObject",
                          + "s3:GetObject",
                          + "s3:DeleteObject",
                          + "s3:ListBucket",
                        ]
                      + Effect   = "Allow"
                      + Resource = [
                          + "arn:aws:s3:::bluedragon-ecommerce-terraform-state",
                          + "arn:aws:s3:::bluedragon-ecommerce-terraform-state/*",
                        ]
                    },
                  + {
                      + Action   = [
                          + "dynamodb:PutItem",
                          + "dynamodb:GetItem",
                          + "dynamodb:DeleteItem",
                          + "dynamodb:Scan",
                        ]
                      + Effect   = "Allow"
                      + Resource = "arn:aws:dynamodb:us-east-1:084375569056:table/terraform-state-lock"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.iam.aws_iam_policy.terraform_admin_ec2 will be created
  + resource "aws_iam_policy" "terraform_admin_ec2" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "EC2 policy for terraform-admin role"
      + id               = (known after apply)
      + name             = "TerraformAdminEC2Policy"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "ec2:Describe*",
                          + "ec2:Get*",
                          + "ec2:AuthorizeSecurityGroupIngress",
                          + "ec2:RevokeSecurityGroupIngress",
                          + "ec2:CreateSecurityGroup",
                          + "ec2:DeleteSecurityGroup",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action    = [
                          + "ec2:CreateTags",
                        ]
                      + Condition = {
                          + Null         = {
                              + "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
                            }
                          + StringEquals = {
                              + "ec2:CreateAction" = "CreateSecurityGroup"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:ec2:*:*:security-group/*"
                    },
                  + {
                      + Action    = [
                          + "ec2:CreateTags",
                          + "ec2:DeleteTags",
                        ]
                      + Condition = {
                          + Null = {
                              + "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
                              + "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:ec2:*:*:security-group/*"
                    },
                  + {
                      + Action    = [
                          + "ec2:AuthorizeSecurityGroupIngress",
                          + "ec2:RevokeSecurityGroupIngress",
                          + "ec2:DeleteSecurityGroup",
                        ]
                      + Condition = {
                          + Null = {
                              + "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.iam.aws_iam_policy.terraform_admin_eks will be created
  + resource "aws_iam_policy" "terraform_admin_eks" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "EKS-specific policy for terraform-admin role"
      + id               = (known after apply)
      + name             = "TerraformAdminEKSPolicy"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "eks:DescribeCluster",
                          + "eks:ListClusters",
                          + "eks:AccessKubernetesApi",
                          + "eks:ListAccessEntries",
                          + "eks:DescribeAccessEntry",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.iam.aws_iam_policy.terraform_admin_elb_other will be created
  + resource "aws_iam_policy" "terraform_admin_elb_other" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "ELB and other services policy for terraform-admin role"
      + id               = (known after apply)
      + name             = "TerraformAdminELBOtherPolicy"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = [
                          + "iam:CreateServiceLinkedRole",
                        ]
                      + Condition = {
                          + StringEquals = {
                              + "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                    },
                  + {
                      + Action    = "iam:PassRole"
                      + Condition = {
                          + StringEquals = {
                              + "iam:PassedToService" = "elasticloadbalancing.amazonaws.com"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:iam::084375569056:role/ecommerce-cluster-alb-controller"
                    },
                  + {
                      + Action   = [
                          + "elasticloadbalancing:Describe*",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action    = [
                          + "elasticloadbalancing:CreateLoadBalancer",
                          + "elasticloadbalancing:CreateTargetGroup",
                          + "elasticloadbalancing:DeleteLoadBalancer",
                          + "elasticloadbalancing:DeleteTargetGroup",
                          + "elasticloadbalancing:Modify*",
                          + "elasticloadbalancing:Set*",
                          + "elasticloadbalancing:RegisterTargets",
                          + "elasticloadbalancing:DeregisterTargets",
                        ]
                      + Condition = {
                          + Null = {
                              + "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "*"
                    },
                  + {
                      + Action   = [
                          + "elasticloadbalancing:CreateListener",
                          + "elasticloadbalancing:DeleteListener",
                          + "elasticloadbalancing:CreateRule",
                          + "elasticloadbalancing:DeleteRule",
                          + "elasticloadbalancing:AddListenerCertificates",
                          + "elasticloadbalancing:RemoveListenerCertificates",
                          + "elasticloadbalancing:SetWebAcl",
                          + "elasticloadbalancing:SetRulePriorities",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action    = [
                          + "elasticloadbalancing:AddTags",
                          + "elasticloadbalancing:RemoveTags",
                        ]
                      + Condition = {
                          + Null = {
                              + "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
                              + "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = [
                          + "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
                        ]
                    },
                  + {
                      + Action    = [
                          + "elasticloadbalancing:AddTags",
                        ]
                      + Condition = {
                          + Null         = {
                              + "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
                            }
                          + StringEquals = {
                              + "elasticloadbalancing:CreateAction" = [
                                  + "CreateTargetGroup",
                                  + "CreateLoadBalancer",
                                ]
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = [
                          + "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                          + "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
                        ]
                    },
                  + {
                      + Action   = [
                          + "cognito-idp:DescribeUserPoolClient",
                          + "acm:ListCertificates",
                          + "acm:DescribeCertificate",
                          + "iam:ListServerCertificates",
                          + "iam:GetServerCertificate",
                          + "waf-regional:*",
                          + "wafv2:*",
                          + "shield:GetSubscriptionState",
                          + "shield:DescribeProtection",
                          + "shield:CreateProtection",
                          + "shield:DeleteProtection",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.iam.aws_iam_role.alb_controller will be created
  + resource "aws_iam_role" "alb_controller" {
      + arn                   = (known after apply)
      + assume_role_policy    = (known after apply)
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "ecommerce-cluster-alb-controller"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.iam.aws_iam_role.terraform_admin will be created
  + resource "aws_iam_role" "terraform_admin" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + AWS = "arn:aws:iam::084375569056:user/bluedragon"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "terraform-admin"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.iam.aws_iam_role_policy_attachment.alb_controller_policy will be created
  + resource "aws_iam_role_policy_attachment" "alb_controller_policy" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "ecommerce-cluster-alb-controller"
    }

  # module.iam.aws_iam_role_policy_attachment.node_group_elb will be created
  + resource "aws_iam_role_policy_attachment" "node_group_elb" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = (known after apply)
    }

  # module.iam.aws_iam_role_policy_attachment.terraform_admin_backend_attachment will be created
  + resource "aws_iam_role_policy_attachment" "terraform_admin_backend_attachment" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "terraform-admin"
    }

  # module.iam.aws_iam_role_policy_attachment.terraform_admin_ec2_attachment will be created
  + resource "aws_iam_role_policy_attachment" "terraform_admin_ec2_attachment" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "terraform-admin"
    }

  # module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_attachment will be created
  + resource "aws_iam_role_policy_attachment" "terraform_admin_eks_attachment" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "terraform-admin"
    }

  # module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_policy will be created
  + resource "aws_iam_role_policy_attachment" "terraform_admin_eks_policy" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      + role       = "terraform-admin"
    }

  # module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_worker_policy will be created
  + resource "aws_iam_role_policy_attachment" "terraform_admin_eks_worker_policy" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      + role       = "terraform-admin"
    }

  # module.iam.aws_iam_role_policy_attachment.terraform_admin_elb_other_attachment will be created
  + resource "aws_iam_role_policy_attachment" "terraform_admin_elb_other_attachment" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "terraform-admin"
    }

  # module.networking.aws_security_group.app will be created
  + resource "aws_security_group" "app" {
      + arn                    = (known after apply)
      + description            = "Security group for e-commerce application"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = "Allow all outbound traffic"
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "23.93.84.244/32",
                ]
              + description      = "Allow app traffic from specified CIDRs"
              + from_port        = 8080
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 8080
            },
        ]
      + name                   = "ecommerce-cluster-app"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Name" = "ecommerce-cluster-app"
        }
      + tags_all               = {
          + "Name" = "ecommerce-cluster-app"
        }
      + vpc_id                 = (known after apply)
    }

  # module.networking.aws_security_group_rule.eks_control_plane_ingress will be created
  + resource "aws_security_group_rule" "eks_control_plane_ingress" {
      + cidr_blocks              = [
          + "23.93.84.244/32",
        ]
      + description              = "Allow ingress to EKS control plane from specified CIDRs"
      + from_port                = 443
      + id                       = (known after apply)
      + protocol                 = "tcp"
      + security_group_id        = (known after apply)
      + security_group_rule_id   = (known after apply)
      + self                     = false
      + source_security_group_id = (known after apply)
      + to_port                  = 443
      + type                     = "ingress"
    }

  # module.networking.aws_vpc_endpoint.s3 will be created
  + resource "aws_vpc_endpoint" "s3" {
      + arn                   = (known after apply)
      + cidr_blocks           = (known after apply)
      + dns_entry             = (known after apply)
      + id                    = (known after apply)
      + ip_address_type       = (known after apply)
      + network_interface_ids = (known after apply)
      + owner_id              = (known after apply)
      + policy                = (known after apply)
      + prefix_list_id        = (known after apply)
      + private_dns_enabled   = (known after apply)
      + requester_managed     = (known after apply)
      + route_table_ids       = (known after apply)
      + security_group_ids    = (known after apply)
      + service_name          = "com.amazonaws.us-east-1.s3"
      + service_region        = (known after apply)
      + state                 = (known after apply)
      + subnet_ids            = (known after apply)
      + tags                  = {
          + "Name" = "ecommerce-cluster-s3-endpoint"
        }
      + tags_all              = {
          + "Name" = "ecommerce-cluster-s3-endpoint"
        }
      + vpc_endpoint_type     = "Gateway"
      + vpc_id                = (known after apply)

      + dns_options (known after apply)

      + subnet_configuration (known after apply)
    }

  # module.s3.aws_s3_bucket.app_bucket will be created
  + resource "aws_s3_bucket" "app_bucket" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "blued-ecommerce-app-us-east-1-prod"
      + bucket_domain_name          = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags                        = {
          + "Environment" = "prod"
          + "Name"        = "ecommerce-cluster-app-bucket"
        }
      + tags_all                    = {
          + "Environment" = "prod"
          + "Name"        = "ecommerce-cluster-app-bucket"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + cors_rule (known after apply)

      + grant (known after apply)

      + lifecycle_rule (known after apply)

      + logging (known after apply)

      + object_lock_configuration (known after apply)

      + replication_configuration (known after apply)

      + server_side_encryption_configuration (known after apply)

      + versioning (known after apply)

      + website (known after apply)
    }

  # module.s3.aws_s3_bucket_public_access_block.app_bucket_public_access will be created
  + resource "aws_s3_bucket_public_access_block" "app_bucket_public_access" {
      + block_public_acls       = true
      + block_public_policy     = true
      + bucket                  = (known after apply)
      + id                      = (known after apply)
      + ignore_public_acls      = true
      + restrict_public_buckets = true
    }

  # module.s3.aws_s3_bucket_server_side_encryption_configuration.app_bucket_encryption will be created
  + resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_encryption" {
      + bucket = (known after apply)
      + id     = (known after apply)

      + rule {
          + apply_server_side_encryption_by_default {
              + sse_algorithm     = "AES256"
                # (1 unchanged attribute hidden)
            }
        }
    }

  # module.s3.aws_s3_bucket_versioning.app_bucket_versioning will be created
  + resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
      + bucket = (known after apply)
      + id     = (known after apply)

      + versioning_configuration {
          + mfa_delete = (known after apply)
          + status     = "Enabled"
        }
    }

  # module.vpc.aws_default_network_acl.this[0] will be created
  + resource "aws_default_network_acl" "this" {
      + arn                    = (known after apply)
      + default_network_acl_id = (known after apply)
      + id                     = (known after apply)
      + owner_id               = (known after apply)
      + tags                   = {
          + "Name" = "ecommerce-vpc"
        }
      + tags_all               = {
          + "Name" = "ecommerce-vpc"
        }
      + vpc_id                 = (known after apply)

      + egress {
          + action          = "allow"
          + from_port       = 0
          + ipv6_cidr_block = "::/0"
          + protocol        = "-1"
          + rule_no         = 101
          + to_port         = 0
            # (1 unchanged attribute hidden)
        }
      + egress {
          + action          = "allow"
          + cidr_block      = "0.0.0.0/0"
          + from_port       = 0
          + protocol        = "-1"
          + rule_no         = 100
          + to_port         = 0
            # (1 unchanged attribute hidden)
        }

      + ingress {
          + action          = "allow"
          + from_port       = 0
          + ipv6_cidr_block = "::/0"
          + protocol        = "-1"
          + rule_no         = 101
          + to_port         = 0
            # (1 unchanged attribute hidden)
        }
      + ingress {
          + action          = "allow"
          + cidr_block      = "0.0.0.0/0"
          + from_port       = 0
          + protocol        = "-1"
          + rule_no         = 100
          + to_port         = 0
            # (1 unchanged attribute hidden)
        }
    }

  # module.vpc.aws_default_route_table.default[0] will be created
  + resource "aws_default_route_table" "default" {
      + arn                    = (known after apply)
      + default_route_table_id = (known after apply)
      + id                     = (known after apply)
      + owner_id               = (known after apply)
      + route                  = (known after apply)
      + tags                   = {
          + "Name" = "ecommerce-vpc"
        }
      + tags_all               = {
          + "Name" = "ecommerce-vpc"
        }
      + vpc_id                 = (known after apply)

      + timeouts {
          + create = "5m"
          + update = "5m"
        }
    }

  # module.vpc.aws_default_security_group.this[0] will be created
  + resource "aws_default_security_group" "this" {
      + arn                    = (known after apply)
      + description            = (known after apply)
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = (known after apply)
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Name" = "ecommerce-vpc"
        }
      + tags_all               = {
          + "Name" = "ecommerce-vpc"
        }
      + vpc_id                 = (known after apply)
    }

  # module.vpc.aws_eip.nat[0] will be created
  + resource "aws_eip" "nat" {
      + allocation_id        = (known after apply)
      + arn                  = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = "vpc"
      + id                   = (known after apply)
      + instance             = (known after apply)
      + ipam_pool_id         = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + ptr_record           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Name" = "ecommerce-vpc"
        }
      + tags_all             = {
          + "Name" = "ecommerce-vpc"
        }
      + vpc                  = (known after apply)
    }

  # module.vpc.aws_internet_gateway.this[0] will be created
  + resource "aws_internet_gateway" "this" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + tags     = {
          + "Name" = "ecommerce-vpc"
        }
      + tags_all = {
          + "Name" = "ecommerce-vpc"
        }
      + vpc_id   = (known after apply)
    }

  # module.vpc.aws_nat_gateway.this[0] will be created
  + resource "aws_nat_gateway" "this" {
      + allocation_id                      = (known after apply)
      + association_id                     = (known after apply)
      + connectivity_type                  = "public"
      + id                                 = (known after apply)
      + network_interface_id               = (known after apply)
      + private_ip                         = (known after apply)
      + public_ip                          = (known after apply)
      + secondary_private_ip_address_count = (known after apply)
      + secondary_private_ip_addresses     = (known after apply)
      + subnet_id                          = (known after apply)
      + tags                               = {
          + "Name" = "ecommerce-vpc"
        }
      + tags_all                           = {
          + "Name" = "ecommerce-vpc"
        }
    }

  # module.vpc.aws_route.private_nat_gateway[0] will be created
  + resource "aws_route" "private_nat_gateway" {
      + destination_cidr_block = "0.0.0.0/0"
      + id                     = (known after apply)
      + instance_id            = (known after apply)
      + instance_owner_id      = (known after apply)
      + nat_gateway_id         = (known after apply)
      + network_interface_id   = (known after apply)
      + origin                 = (known after apply)
      + route_table_id         = (known after apply)
      + state                  = (known after apply)

      + timeouts {
          + create = "5m"
        }
    }

  # module.vpc.aws_route.public_internet_gateway[0] will be created
  + resource "aws_route" "public_internet_gateway" {
      + destination_cidr_block = "0.0.0.0/0"
      + gateway_id             = (known after apply)
      + id                     = (known after apply)
      + instance_id            = (known after apply)
      + instance_owner_id      = (known after apply)
      + network_interface_id   = (known after apply)
      + origin                 = (known after apply)
      + route_table_id         = (known after apply)
      + state                  = (known after apply)

      + timeouts {
          + create = "5m"
        }
    }

  # module.vpc.aws_route_table.private[0] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Name" = "ecommerce-vpc"
        }
      + tags_all         = {
          + "Name" = "ecommerce-vpc"
        }
      + vpc_id           = (known after apply)
    }

  # module.vpc.aws_route_table.public[0] will be created
  + resource "aws_route_table" "public" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Name" = "ecommerce-vpc"
        }
      + tags_all         = {
          + "Name" = "ecommerce-vpc"
        }
      + vpc_id           = (known after apply)
    }

  # module.vpc.aws_route_table_association.private[0] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.vpc.aws_route_table_association.private[1] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.vpc.aws_route_table_association.public[0] will be created
  + resource "aws_route_table_association" "public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.vpc.aws_route_table_association.public[1] will be created
  + resource "aws_route_table_association" "public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.vpc.aws_subnet.private[0] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Name"                                    = "ecommerce-vpc"
          + "kubernetes.io/cluster/ecommerce-cluster" = "shared"
          + "kubernetes.io/role/internal-elb"         = "1"
        }
      + tags_all                                       = {
          + "Name"                                    = "ecommerce-vpc"
          + "kubernetes.io/cluster/ecommerce-cluster" = "shared"
          + "kubernetes.io/role/internal-elb"         = "1"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.vpc.aws_subnet.private[1] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.2.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Name"                                    = "ecommerce-vpc"
          + "kubernetes.io/cluster/ecommerce-cluster" = "shared"
          + "kubernetes.io/role/internal-elb"         = "1"
        }
      + tags_all                                       = {
          + "Name"                                    = "ecommerce-vpc"
          + "kubernetes.io/cluster/ecommerce-cluster" = "shared"
          + "kubernetes.io/role/internal-elb"         = "1"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.vpc.aws_subnet.public[0] will be created
  + resource "aws_subnet" "public" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.101.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Name"                                    = "ecommerce-vpc"
          + "kubernetes.io/cluster/ecommerce-cluster" = "shared"
          + "kubernetes.io/role/elb"                  = "1"
        }
      + tags_all                                       = {
          + "Name"                                    = "ecommerce-vpc"
          + "kubernetes.io/cluster/ecommerce-cluster" = "shared"
          + "kubernetes.io/role/elb"                  = "1"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.vpc.aws_subnet.public[1] will be created
  + resource "aws_subnet" "public" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.102.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Name"                                    = "ecommerce-vpc"
          + "kubernetes.io/cluster/ecommerce-cluster" = "shared"
          + "kubernetes.io/role/elb"                  = "1"
        }
      + tags_all                                       = {
          + "Name"                                    = "ecommerce-vpc"
          + "kubernetes.io/cluster/ecommerce-cluster" = "shared"
          + "kubernetes.io/role/elb"                  = "1"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.vpc.aws_vpc.this[0] will be created
  + resource "aws_vpc" "this" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.0.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Name" = "ecommerce-vpc"
        }
      + tags_all                             = {
          + "Name" = "ecommerce-vpc"
        }
    }

  # module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0] will be created
  + resource "aws_eks_node_group" "this" {
      + ami_type               = (known after apply)
      + arn                    = (known after apply)
      + capacity_type          = (known after apply)
      + cluster_name           = (known after apply)
      + disk_size              = (known after apply)
      + id                     = (known after apply)
      + instance_types         = [
          + "t3.medium",
        ]
      + node_group_name        = (known after apply)
      + node_group_name_prefix = "default-"
      + node_role_arn          = (known after apply)
      + release_version        = (known after apply)
      + resources              = (known after apply)
      + status                 = (known after apply)
      + subnet_ids             = (known after apply)
      + tags                   = {
          + "Name" = "default"
        }
      + tags_all               = {
          + "Name" = "default"
        }
      + version                = "1.29"

      + launch_template {
          + id      = (known after apply)
          + name    = (known after apply)
          + version = (known after apply)
        }

      + node_repair_config (known after apply)

      + scaling_config {
          + desired_size = 2
          + max_size     = 3
          + min_size     = 2
        }

      + timeouts {}

      + update_config {
          + max_unavailable_percentage = 33
        }
    }

  # module.eks.module.eks_managed_node_group["default"].aws_iam_role.this[0] will be created
  + resource "aws_iam_role" "this" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "ec2.amazonaws.com"
                        }
                      + Sid       = "EKSNodeAssumeRole"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "EKS managed node group IAM role"
      + force_detach_policies = true
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = (known after apply)
      + name_prefix           = "default-eks-node-group-"
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEC2ContainerRegistryReadOnly"] will be created
  + resource "aws_iam_role_policy_attachment" "this" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      + role       = (known after apply)
    }

  # module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKSWorkerNodePolicy"] will be created
  + resource "aws_iam_role_policy_attachment" "this" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      + role       = (known after apply)
    }

  # module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKS_CNI_Policy"] will be created
  + resource "aws_iam_role_policy_attachment" "this" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
      + role       = (known after apply)
    }

  # module.eks.module.eks_managed_node_group["default"].aws_launch_template.this[0] will be created
  + resource "aws_launch_template" "this" {
      + arn                    = (known after apply)
      + default_version        = (known after apply)
      + description            = "Custom launch template for default EKS managed node group"
      + id                     = (known after apply)
      + latest_version         = (known after apply)
      + name                   = (known after apply)
      + name_prefix            = "default-"
      + tags_all               = (known after apply)
      + update_default_version = true
      + vpc_security_group_ids = (known after apply)
        # (2 unchanged attributes hidden)

      + metadata_options {
          + http_endpoint               = "enabled"
          + http_protocol_ipv6          = (known after apply)
          + http_put_response_hop_limit = 2
          + http_tokens                 = "required"
          + instance_metadata_tags      = (known after apply)
        }

      + monitoring {
          + enabled = true
        }

      + tag_specifications {
          + resource_type = "instance"
          + tags          = {
              + "Name" = "default"
            }
        }
      + tag_specifications {
          + resource_type = "network-interface"
          + tags          = {
              + "Name" = "default"
            }
        }
      + tag_specifications {
          + resource_type = "volume"
          + tags          = {
              + "Name" = "default"
            }
        }
    }

  # module.eks.module.kms.data.aws_iam_policy_document.this[0] will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "this" {
      + id                        = (known after apply)
      + json                      = (known after apply)
      + minified_json             = (known after apply)
      + override_policy_documents = []
      + source_policy_documents   = []

      + statement {
          + actions   = [
              + "kms:*",
            ]
          + resources = [
              + "*",
            ]
          + sid       = "Default"

          + principals {
              + identifiers = [
                  + "arn:aws:iam::084375569056:root",
                ]
              + type        = "AWS"
            }
        }
      + statement {
          + actions   = [
              + "kms:CancelKeyDeletion",
              + "kms:Create*",
              + "kms:Delete*",
              + "kms:Describe*",
              + "kms:Disable*",
              + "kms:Enable*",
              + "kms:Get*",
              + "kms:ImportKeyMaterial",
              + "kms:List*",
              + "kms:Put*",
              + "kms:ReplicateKey",
              + "kms:Revoke*",
              + "kms:ScheduleKeyDeletion",
              + "kms:TagResource",
              + "kms:UntagResource",
              + "kms:Update*",
            ]
          + resources = [
              + "*",
            ]
          + sid       = "KeyAdministration"

          + principals {
              + identifiers = [
                  + "arn:aws:iam::084375569056:user/bluedragon",
                ]
              + type        = "AWS"
            }
        }
      + statement {
          + actions   = [
              + "kms:Decrypt",
              + "kms:DescribeKey",
              + "kms:Encrypt",
              + "kms:GenerateDataKey*",
              + "kms:ReEncrypt*",
            ]
          + resources = [
              + "*",
            ]
          + sid       = "KeyUsage"

          + principals {
              + identifiers = [
                  + (known after apply),
                ]
              + type        = "AWS"
            }
        }
    }

  # module.eks.module.kms.aws_kms_alias.this["cluster"] will be created
  + resource "aws_kms_alias" "this" {
      + arn            = (known after apply)
      + id             = (known after apply)
      + name           = "alias/eks/ecommerce-cluster"
      + name_prefix    = (known after apply)
      + target_key_arn = (known after apply)
      + target_key_id  = (known after apply)
    }

  # module.eks.module.kms.aws_kms_key.this[0] will be created
  + resource "aws_kms_key" "this" {
      + arn                                = (known after apply)
      + bypass_policy_lockout_safety_check = false
      + customer_master_key_spec           = "SYMMETRIC_DEFAULT"
      + description                        = "ecommerce-cluster cluster encryption key"
      + enable_key_rotation                = true
      + id                                 = (known after apply)
      + is_enabled                         = true
      + key_id                             = (known after apply)
      + key_usage                          = "ENCRYPT_DECRYPT"
      + multi_region                       = false
      + policy                             = (known after apply)
      + rotation_period_in_days            = (known after apply)
      + tags                               = {
          + "terraform-aws-modules" = "eks"
        }
      + tags_all                           = {
          + "terraform-aws-modules" = "eks"
        }
    }

  # module.eks.module.eks_managed_node_group["default"].module.user_data.null_resource.validate_cluster_service_cidr will be created
  + resource "null_resource" "validate_cluster_service_cidr" {
      + id = (known after apply)
    }

Plan: 82 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + alb_controller_role_arn            = (known after apply)
  + cluster_certificate_authority_data = (known after apply)
  + cluster_endpoint                   = (known after apply)
  + cluster_name                       = "ecommerce-cluster"
  + s3_bucket_name                     = (known after apply)
  + terraform_role_arn                 = (known after apply)
  + vpc_id                             = (known after apply)

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
Releasing state lock. This may take a few moments...
tim@Tims-MacBook-Pro stage1-infra % terraform apply tfplan
╷
│ Warning: Deprecated Parameter
│ 
│ The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.
╵
module.iam.aws_iam_policy.terraform_admin_backend: Creating...
module.iam.aws_iam_policy.node_group_elb: Creating...
module.iam.aws_iam_policy.terraform_admin_elb_other: Creating...
module.eks.aws_cloudwatch_log_group.this[0]: Creating...
module.iam.aws_iam_role.terraform_admin: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role.this[0]: Creating...
module.iam.aws_iam_policy.alb_controller_policy: Creating...
module.vpc.aws_vpc.this[0]: Creating...
module.iam.aws_iam_policy.terraform_admin_ec2: Creating...
module.s3.aws_s3_bucket.app_bucket: Creating...
module.iam.aws_iam_policy.terraform_admin_ec2: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/TerraformAdminEC2Policy]
module.iam.aws_iam_policy.terraform_admin_eks: Creating...
module.iam.aws_iam_policy.terraform_admin_backend: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/TerraformAdminBackendPolicy]
module.iam.aws_iam_policy.node_group_elb: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/ecommerce-cluster-EKSNodeGroupELBPolicy]
module.iam.aws_iam_policy.alb_controller_policy: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/ecommerce-cluster-AWSLoadBalancerControllerPolicy]
module.iam.aws_iam_policy.terraform_admin_elb_other: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/TerraformAdminELBOtherPolicy]
module.eks.aws_iam_policy.custom[0]: Creating...
module.eks.aws_iam_role.this[0]: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role.this[0]: Creation complete after 1s [id=default-eks-node-group-20250623002453276000000001]
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKS_CNI_Policy"]: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKSWorkerNodePolicy"]: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEC2ContainerRegistryReadOnly"]: Creating...
module.iam.aws_iam_role.terraform_admin: Creation complete after 1s [id=terraform-admin]
module.iam.aws_iam_role_policy_attachment.terraform_admin_backend_attachment: Creating...
module.iam.aws_iam_policy.terraform_admin_eks: Creation complete after 0s [id=arn:aws:iam::084375569056:policy/TerraformAdminEKSPolicy]
module.iam.aws_iam_role_policy_attachment.terraform_admin_ec2_attachment: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEC2ContainerRegistryReadOnly"]: Creation complete after 0s [id=default-eks-node-group-20250623002453276000000001-20250623002454240600000004]
module.iam.aws_iam_role_policy_attachment.terraform_admin_elb_other_attachment: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKSWorkerNodePolicy"]: Creation complete after 0s [id=default-eks-node-group-20250623002453276000000001-20250623002454254000000005]
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_worker_policy: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKS_CNI_Policy"]: Creation complete after 0s [id=default-eks-node-group-20250623002453276000000001-20250623002454270000000006]
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_policy: Creating...
module.eks.aws_iam_policy.custom[0]: Creation complete after 0s [id=arn:aws:iam::084375569056:policy/ecommerce-cluster-cluster-20250623002454058900000002]
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_attachment: Creating...
module.iam.aws_iam_role_policy_attachment.terraform_admin_backend_attachment: Creation complete after 1s [id=terraform-admin-20250623002454403600000007]
module.iam.aws_iam_role_policy_attachment.terraform_admin_ec2_attachment: Creation complete after 1s [id=terraform-admin-20250623002454447200000008]
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_worker_policy: Creation complete after 1s [id=terraform-admin-20250623002454475400000009]
module.iam.aws_iam_role_policy_attachment.terraform_admin_elb_other_attachment: Creation complete after 1s [id=terraform-admin-2025062300245450000000000a]
module.eks.aws_iam_role.this[0]: Creation complete after 1s [id=ecommerce-cluster-cluster-20250623002454062100000003]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]: Creating...
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]: Creating...
module.eks.aws_iam_role_policy_attachment.custom[0]: Creating...
module.eks.module.kms.data.aws_iam_policy_document.this[0]: Reading...
module.eks.module.kms.data.aws_iam_policy_document.this[0]: Read complete after 0s [id=1268998151]
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_attachment: Creation complete after 1s [id=terraform-admin-2025062300245455480000000c]
module.eks.module.kms.aws_kms_key.this[0]: Creating...
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_policy: Creation complete after 1s [id=terraform-admin-2025062300245455330000000b]
module.eks.aws_iam_role_policy_attachment.custom[0]: Creation complete after 0s [id=ecommerce-cluster-cluster-20250623002454062100000003-2025062300245476680000000d]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]: Creation complete after 0s [id=ecommerce-cluster-cluster-20250623002454062100000003-2025062300245478760000000f]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]: Creation complete after 0s [id=ecommerce-cluster-cluster-20250623002454062100000003-2025062300245478380000000e]
module.eks.aws_cloudwatch_log_group.this[0]: Creation complete after 2s [id=/aws/eks/ecommerce-cluster/cluster]
module.s3.aws_s3_bucket.app_bucket: Creation complete after 2s [id=blued-ecommerce-app-us-east-1-prod]
module.s3.aws_s3_bucket_public_access_block.app_bucket_public_access: Creating...
module.s3.aws_s3_bucket_versioning.app_bucket_versioning: Creating...
module.s3.aws_s3_bucket_server_side_encryption_configuration.app_bucket_encryption: Creating...
module.s3.aws_s3_bucket_public_access_block.app_bucket_public_access: Creation complete after 1s [id=blued-ecommerce-app-us-east-1-prod]
module.s3.aws_s3_bucket_server_side_encryption_configuration.app_bucket_encryption: Creation complete after 1s [id=blued-ecommerce-app-us-east-1-prod]
module.s3.aws_s3_bucket_versioning.app_bucket_versioning: Creation complete after 2s [id=blued-ecommerce-app-us-east-1-prod]
module.vpc.aws_vpc.this[0]: Still creating... [00m10s elapsed]
module.eks.module.kms.aws_kms_key.this[0]: Still creating... [00m10s elapsed]
module.vpc.aws_vpc.this[0]: Creation complete after 14s [id=vpc-097127ba3fab8eeda]
module.vpc.aws_default_route_table.default[0]: Creating...
module.vpc.aws_default_security_group.this[0]: Creating...
module.vpc.aws_route_table.private[0]: Creating...
module.eks.aws_security_group.node[0]: Creating...
module.vpc.aws_subnet.private[1]: Creating...
module.vpc.aws_route_table.public[0]: Creating...
module.vpc.aws_internet_gateway.this[0]: Creating...
module.eks.aws_security_group.cluster[0]: Creating...
module.vpc.aws_default_network_acl.this[0]: Creating...
module.vpc.aws_default_route_table.default[0]: Creation complete after 1s [id=rtb-0720712e4bfdc0ec2]
module.vpc.aws_subnet.private[0]: Creating...
module.vpc.aws_internet_gateway.this[0]: Creation complete after 1s [id=igw-0eea12e062a4275c8]
module.vpc.aws_subnet.public[1]: Creating...
module.vpc.aws_route_table.private[0]: Creation complete after 1s [id=rtb-0aeea8d0368c69c86]
module.vpc.aws_route_table.public[0]: Creation complete after 1s [id=rtb-0ceb1d8fa0fa70721]
module.networking.aws_security_group.app: Creating...
module.vpc.aws_subnet.public[0]: Creating...
module.vpc.aws_subnet.private[1]: Creation complete after 1s [id=subnet-0785a3a6f667399e5]
module.vpc.aws_eip.nat[0]: Creating...
module.vpc.aws_subnet.private[0]: Creation complete after 1s [id=subnet-0f6588743c104ca82]
module.vpc.aws_route.public_internet_gateway[0]: Creating...
module.vpc.aws_subnet.public[0]: Creation complete after 1s [id=subnet-0ddf807f9bf16b628]
module.vpc.aws_route_table_association.private[0]: Creating...
module.vpc.aws_subnet.public[1]: Creation complete after 1s [id=subnet-002fa2e7e865dfea6]
module.vpc.aws_route_table_association.private[1]: Creating...
module.vpc.aws_default_network_acl.this[0]: Creation complete after 2s [id=acl-034b918c18487fc0d]
module.vpc.aws_route_table_association.public[1]: Creating...
module.vpc.aws_default_security_group.this[0]: Creation complete after 2s [id=sg-00ccc65e4f390c2b3]
module.vpc.aws_route_table_association.public[0]: Creating...
module.vpc.aws_eip.nat[0]: Creation complete after 1s [id=eipalloc-0a43cc3bea927133d]
module.networking.aws_vpc_endpoint.s3: Creating...
module.vpc.aws_route_table_association.private[0]: Creation complete after 0s [id=rtbassoc-09b7d667c22fdec89]
module.vpc.aws_nat_gateway.this[0]: Creating...
module.vpc.aws_route_table_association.private[1]: Creation complete after 0s [id=rtbassoc-057dde960d3f75d4e]
module.vpc.aws_route_table_association.public[1]: Creation complete after 0s [id=rtbassoc-003ae2783561f548c]
module.vpc.aws_route_table_association.public[0]: Creation complete after 0s [id=rtbassoc-04c620ed51894579d]
module.vpc.aws_route.public_internet_gateway[0]: Creation complete after 0s [id=r-rtb-0ceb1d8fa0fa707211080289494]
module.eks.aws_security_group.node[0]: Creation complete after 3s [id=sg-0d656f98a82abfa3b]
module.eks.aws_security_group.cluster[0]: Creation complete after 3s [id=sg-01c944107bfe23491]
module.networking.aws_security_group_rule.eks_control_plane_ingress: Creating...
module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_443"]: Creating...
module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"]: Creating...
module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"]: Creation complete after 0s [id=sgrule-3691392605]
module.eks.aws_security_group_rule.node["egress_all"]: Creating...
module.networking.aws_security_group_rule.eks_control_plane_ingress: Creation complete after 0s [id=sgrule-1097866281]
module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]: Creating...
module.networking.aws_security_group.app: Creation complete after 3s [id=sg-0c3c1fdb64d8835f9]
module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_443"]: Creation complete after 1s [id=sgrule-201012648]
module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"]: Creating...
module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]: Creation complete after 1s [id=sgrule-2651188977]
module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"]: Creating...
module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"]: Creation complete after 2s [id=sgrule-2194087752]
module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]: Creating...
module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"]: Creation complete after 3s [id=sgrule-3286835747]
module.eks.aws_security_group_rule.node["egress_all"]: Creation complete after 4s [id=sgrule-3327555708]
module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]: Creation complete after 4s [id=sgrule-1740014028]
module.eks.module.kms.aws_kms_key.this[0]: Still creating... [00m20s elapsed]
module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"]: Creation complete after 5s [id=sgrule-4203936617]
module.networking.aws_vpc_endpoint.s3: Creation complete after 7s [id=vpce-096e60bdf20ad3bbb]
module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"]: Creation complete after 5s [id=sgrule-1656309281]
module.eks.module.kms.aws_kms_key.this[0]: Creation complete after 22s [id=15baa9d1-4805-40e9-b0c5-17be1c29e0f5]
module.eks.module.kms.aws_kms_alias.this["cluster"]: Creating...
module.eks.aws_iam_policy.cluster_encryption[0]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"]: Creation complete after 6s [id=sgrule-2885362103]
module.eks.module.kms.aws_kms_alias.this["cluster"]: Creation complete after 0s [id=alias/eks/ecommerce-cluster]
module.eks.aws_iam_policy.cluster_encryption[0]: Creation complete after 0s [id=arn:aws:iam::084375569056:policy/ecommerce-cluster-cluster-ClusterEncryption20250623002516530700000016]
module.eks.aws_iam_role_policy_attachment.cluster_encryption[0]: Creating...
module.eks.aws_iam_role_policy_attachment.cluster_encryption[0]: Creation complete after 0s [id=ecommerce-cluster-cluster-20250623002454062100000003-20250623002517194600000017]
module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]: Creation complete after 5s [id=sgrule-3097959830]
module.eks.aws_eks_cluster.this[0]: Creating...
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m10s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m20s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m30s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m40s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m50s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m50s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [01m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m00s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [01m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m10s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [01m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m20s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [01m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m30s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [01m40s elapsed]
module.vpc.aws_nat_gateway.this[0]: Creation complete after 1m45s [id=nat-0047b397dd11bd56e]
module.vpc.aws_route.private_nat_gateway[0]: Creating...
module.vpc.aws_route.private_nat_gateway[0]: Creation complete after 1s [id=r-rtb-0aeea8d0368c69c861080289494]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m50s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m50s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m50s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m50s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m50s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m50s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [07m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [07m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [07m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [07m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [07m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [07m50s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [08m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [08m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [08m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [08m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [08m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [08m50s elapsed]
module.eks.aws_eks_cluster.this[0]: Creation complete after 8m59s [id=ecommerce-cluster]
module.eks.data.tls_certificate.this[0]: Reading...
module.eks.aws_eks_access_entry.this["terraform_role"]: Creating...
module.eks.aws_eks_access_entry.this["admin_user"]: Creating...
module.eks.time_sleep.this[0]: Creating...
module.eks.data.tls_certificate.this[0]: Read complete after 1s [id=922877a0975ad078a65b8ff11ebc47b8311945c7]
module.eks.aws_iam_openid_connect_provider.oidc_provider[0]: Creating...
module.eks.aws_eks_access_entry.this["admin_user"]: Creation complete after 1s [id=ecommerce-cluster:arn:aws:iam::084375569056:user/bluedragon]
module.eks.aws_eks_access_entry.this["terraform_role"]: Creation complete after 1s [id=ecommerce-cluster:arn:aws:iam::084375569056:role/terraform-admin]
module.eks.aws_eks_access_policy_association.this["admin_user_cluster_admin_policy"]: Creating...
module.eks.aws_eks_access_policy_association.this["admin_user_admin_policy"]: Creating...
module.eks.aws_eks_access_policy_association.this["terraform_role_cluster_admin_policy"]: Creating...
module.eks.aws_eks_access_policy_association.this["terraform_role_admin_policy"]: Creating...
module.eks.aws_eks_access_policy_association.this["admin_user_view_policy"]: Creating...
module.eks.aws_iam_openid_connect_provider.oidc_provider[0]: Creation complete after 0s [id=arn:aws:iam::084375569056:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/E06C1583EBB1BBE865A7024A0381FD48]
module.iam.aws_iam_role.alb_controller: Creating...
module.iam.aws_iam_role.alb_controller: Creation complete after 1s [id=ecommerce-cluster-alb-controller]
module.iam.aws_iam_role_policy_attachment.alb_controller_policy: Creating...
module.eks.aws_eks_access_policy_association.this["admin_user_admin_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:user/bluedragon#arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy]
module.eks.aws_eks_access_policy_association.this["terraform_role_admin_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:role/terraform-admin#arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy]
module.iam.aws_iam_role_policy_attachment.alb_controller_policy: Creation complete after 0s [id=ecommerce-cluster-alb-controller-20250623003417836800000018]
module.eks.aws_eks_access_policy_association.this["admin_user_view_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:user/bluedragon#arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy]
module.eks.aws_eks_access_policy_association.this["admin_user_cluster_admin_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:user/bluedragon#arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy]
module.eks.aws_eks_access_policy_association.this["terraform_role_cluster_admin_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:role/terraform-admin#arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy]
module.eks.time_sleep.this[0]: Still creating... [00m10s elapsed]
module.eks.time_sleep.this[0]: Still creating... [00m20s elapsed]
module.eks.time_sleep.this[0]: Still creating... [00m30s elapsed]
module.eks.time_sleep.this[0]: Creation complete after 30s [id=2025-06-23T00:34:46Z]
module.eks.module.eks_managed_node_group["default"].module.user_data.null_resource.validate_cluster_service_cidr: Creating...
module.eks.module.eks_managed_node_group["default"].module.user_data.null_resource.validate_cluster_service_cidr: Creation complete after 0s [id=7746891460195071704]
module.eks.module.eks_managed_node_group["default"].aws_launch_template.this[0]: Creating...
module.eks.module.eks_managed_node_group["default"].aws_launch_template.this[0]: Creation complete after 6s [id=lt-096f186aadeec8ca8]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Creating...
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [00m10s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [00m20s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [00m30s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [00m40s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [00m50s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [01m00s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [01m10s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [01m20s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [01m30s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [01m40s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [01m50s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [02m00s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [02m10s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [02m20s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [02m30s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [02m40s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Creation complete after 2m40s [id=ecommerce-cluster:default-2025062300345334360000001b]
module.iam.aws_iam_role_policy_attachment.node_group_elb: Creating...
module.iam.aws_iam_role_policy_attachment.node_group_elb: Creation complete after 1s [id=default-eks-node-group-20250623002453276000000001-2025062300373466830000001d]

Apply complete! Resources: 82 added, 0 changed, 0 destroyed.

Outputs:

alb_controller_role_arn = "arn:aws:iam::084375569056:role/ecommerce-cluster-alb-controller"
cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJV1ZvL0FCbjN0bmt3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBMk1qTXdNREkwTkRKYUZ3MHpOVEEyTWpFd01ESTVOREphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUN3N3hmcDdjaU1mSEVqc3Mzd2F6UmNtZEtxblF5QjdIVjZJRGgwWmVXaTRGdUhFRS96WEJiZkx0Y1EKZExuaVVxODdsUTNDOXUrM3lOYUxFeS9saHE0RDRqa3FJNEdVb1B0emZFeVRFQlZYMnVXeFZmUmtzb04vbGxWNQpBS0JaeGZDUjh2ZzNmYXJ2eHpJMVRrRThGSnZwRVhScmNHNjJ6YmlHcWNEK1A1UWE3NHpFaURyaWs3VEkvaFZxCmFvM3pkRnZ2dzBKelNzdFVld0xMSkxDZ2YyYy9YZUxlRTFoeUl5TFhnZVNCTkJZSTZnS3hzbFF2MC9MbUpscmsKSVQxOXBTaVMyMUFKdVEwTXNHLzhaKzJYSEpnN3NCNSt4UXU0OWY0cFdxZFlaOXdOTlBDeVpSTzJScGxUMWM2QgpjdzQzRzA2UHNpazZzcVQ2Ukd5c0NFMzBmT2tsQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUcW9nNGU3Z1FtU01PY0ZMOHcrVUFqMm9SZG9UQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQWFiRUdVTmFleQpxa2dzV2poRnpPcjdabWxEdzFhTjEvMllyOGViblNxZzJKelhyZGtoM0NHZ1lhbjVOQXJtbGtMdndVNEhBM2J0CmQ3eEliTGpNb01kS2dIY0ZxcjNOMTdNK1VsNWV3NmV5N3hHL0c5dGpMTDZwN1RTVnVOYk9QOXFwVlB3M1k1Q2QKUjV1eUtrM1JZS21aa3dtWWdKdzBhUTB4TVFlcHk2Mis3dWdNdjVVSjdDeENaQnM2QkYzRmxTd0wycTRNUTZPUApLK0Q3eW5kVThaRGd4cFVqK1J4eTFlcUw4aXF6eDBCTTYxRDYwZUd1VitwVThVQlJjM3lXZ0N6RmNZTExpSldjCm41TEoyQ0hrVXpMZ3RESkNqN0h6ZlE4bzZrWFN5T0x6VlhwQmhhODcrQVVNd0tyeVpEcmUvTkx2aXMxWUIzU3IKQ3hJMjZpeFMrbFBhCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
cluster_endpoint = "https://E06C1583EBB1BBE865A7024A0381FD48.yl4.us-east-1.eks.amazonaws.com"
cluster_name = "ecommerce-cluster"
s3_bucket_name = "blued-ecommerce-app-us-east-1-prod"
terraform_role_arn = "arn:aws:iam::084375569056:role/terraform-admin"
vpc_id = "vpc-097127ba3fab8eeda"
tim@Tims-MacBook-Pro stage1-infra % terraform state list
module.eks.data.aws_caller_identity.current[0]
module.eks.data.aws_iam_policy_document.assume_role_policy[0]
module.eks.data.aws_iam_policy_document.custom[0]
module.eks.data.aws_iam_session_context.current[0]
module.eks.data.aws_partition.current[0]
module.eks.data.tls_certificate.this[0]
module.eks.aws_cloudwatch_log_group.this[0]
module.eks.aws_eks_access_entry.this["admin_user"]
module.eks.aws_eks_access_entry.this["terraform_role"]
module.eks.aws_eks_access_policy_association.this["admin_user_admin_policy"]
module.eks.aws_eks_access_policy_association.this["admin_user_cluster_admin_policy"]
module.eks.aws_eks_access_policy_association.this["admin_user_view_policy"]
module.eks.aws_eks_access_policy_association.this["terraform_role_admin_policy"]
module.eks.aws_eks_access_policy_association.this["terraform_role_cluster_admin_policy"]
module.eks.aws_eks_cluster.this[0]
module.eks.aws_iam_openid_connect_provider.oidc_provider[0]
module.eks.aws_iam_policy.cluster_encryption[0]
module.eks.aws_iam_policy.custom[0]
module.eks.aws_iam_role.this[0]
module.eks.aws_iam_role_policy_attachment.cluster_encryption[0]
module.eks.aws_iam_role_policy_attachment.custom[0]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]
module.eks.aws_security_group.cluster[0]
module.eks.aws_security_group.node[0]
module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]
module.eks.aws_security_group_rule.node["egress_all"]
module.eks.aws_security_group_rule.node["ingress_cluster_443"]
module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"]
module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"]
module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]
module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"]
module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"]
module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"]
module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]
module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"]
module.eks.time_sleep.this[0]
module.iam.aws_iam_policy.alb_controller_policy
module.iam.aws_iam_policy.node_group_elb
module.iam.aws_iam_policy.terraform_admin_backend
module.iam.aws_iam_policy.terraform_admin_ec2
module.iam.aws_iam_policy.terraform_admin_eks
module.iam.aws_iam_policy.terraform_admin_elb_other
module.iam.aws_iam_role.alb_controller
module.iam.aws_iam_role.terraform_admin
module.iam.aws_iam_role_policy_attachment.alb_controller_policy
module.iam.aws_iam_role_policy_attachment.node_group_elb
module.iam.aws_iam_role_policy_attachment.terraform_admin_backend_attachment
module.iam.aws_iam_role_policy_attachment.terraform_admin_ec2_attachment
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_attachment
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_policy
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_worker_policy
module.iam.aws_iam_role_policy_attachment.terraform_admin_elb_other_attachment
module.networking.aws_security_group.app
module.networking.aws_security_group_rule.eks_control_plane_ingress
module.networking.aws_vpc_endpoint.s3
module.s3.aws_s3_bucket.app_bucket
module.s3.aws_s3_bucket_public_access_block.app_bucket_public_access
module.s3.aws_s3_bucket_server_side_encryption_configuration.app_bucket_encryption
module.s3.aws_s3_bucket_versioning.app_bucket_versioning
module.vpc.aws_default_network_acl.this[0]
module.vpc.aws_default_route_table.default[0]
module.vpc.aws_default_security_group.this[0]
module.vpc.aws_eip.nat[0]
module.vpc.aws_internet_gateway.this[0]
module.vpc.aws_nat_gateway.this[0]
module.vpc.aws_route.private_nat_gateway[0]
module.vpc.aws_route.public_internet_gateway[0]
module.vpc.aws_route_table.private[0]
module.vpc.aws_route_table.public[0]
module.vpc.aws_route_table_association.private[0]
module.vpc.aws_route_table_association.private[1]
module.vpc.aws_route_table_association.public[0]
module.vpc.aws_route_table_association.public[1]
module.vpc.aws_subnet.private[0]
module.vpc.aws_subnet.private[1]
module.vpc.aws_subnet.public[0]
module.vpc.aws_subnet.public[1]
module.vpc.aws_vpc.this[0]
module.eks.module.eks_managed_node_group["default"].data.aws_caller_identity.current
module.eks.module.eks_managed_node_group["default"].data.aws_iam_policy_document.assume_role_policy[0]
module.eks.module.eks_managed_node_group["default"].data.aws_partition.current
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]
module.eks.module.eks_managed_node_group["default"].aws_iam_role.this[0]
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEC2ContainerRegistryReadOnly"]
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKSWorkerNodePolicy"]
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKS_CNI_Policy"]
module.eks.module.eks_managed_node_group["default"].aws_launch_template.this[0]
module.eks.module.kms.data.aws_caller_identity.current[0]
module.eks.module.kms.data.aws_iam_policy_document.this[0]
module.eks.module.kms.data.aws_partition.current[0]
module.eks.module.kms.aws_kms_alias.this["cluster"]
module.eks.module.kms.aws_kms_key.this[0]
module.eks.module.eks_managed_node_group["default"].module.user_data.null_resource.validate_cluster_service_cidr
tim@Tims-MacBook-Pro stage1-infra % aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1 --profile default
Updated context arn:aws:eks:us-east-1:084375569056:cluster/ecommerce-cluster in /Users/tim/.kube/config
tim@Tims-MacBook-Pro stage1-infra % kubectl get nodes
NAME                        STATUS   ROLES    AGE     VERSION
ip-10-0-1-34.ec2.internal   Ready    <none>   7m40s   v1.29.15-eks-473151a
ip-10-0-2-44.ec2.internal   Ready    <none>   7m42s   v1.29.15-eks-473151a

