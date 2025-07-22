

tim@Tims-MBP stage2-k8s % aws iam get-role --role-name alb_controller --region us-east-1

An error occurred (NoSuchEntity) when calling the GetRole operation: The role with name alb_controller cannot be found.
tim@Tims-MBP stage2-k8s % aws iam list-roles --region us-east-1
{
    "Roles": [
        {
            "Path": "/",
            "RoleName": "AmazonBraketJobsExecutionRole",
            "RoleId": "AROARHJJNAKQIEU7RBKFV",
            "Arn": "arn:aws:iam::084375569056:role/AmazonBraketJobsExecutionRole",
            "CreateDate": "2025-05-15T22:27:59+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "braket.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/service-role/",
            "RoleName": "AmazonSagemakerCanvasBedrockRole-20250513T204280",
            "RoleId": "AROARHJJNAKQCJKWQIFYT",
            "Arn": "arn:aws:iam::084375569056:role/service-role/AmazonSagemakerCanvasBedrockRole-20250513T204280",
            "CreateDate": "2025-05-14T03:42:16+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "BedrockAssumeRole",
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "bedrock.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole",
                        "Condition": {
                            "StringEquals": {
                                "aws:SourceAccount": "084375569056"
                            }
                        }
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/service-role/",
            "RoleName": "AmazonSagemakerCanvasBedrockRole-20250520T093900",
            "RoleId": "AROARHJJNAKQPL3HJSXBM",
            "Arn": "arn:aws:iam::084375569056:role/service-role/AmazonSagemakerCanvasBedrockRole-20250520T093900",
            "CreateDate": "2025-05-20T16:39:56+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "BedrockAssumeRole",
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "bedrock.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole",
                        "Condition": {
                            "StringEquals": {
                                "aws:SourceAccount": "084375569056"
                            }
                        }
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/service-role/",
            "RoleName": "AmazonSagemakerCanvasBedrockRole-20250521T124725",
            "RoleId": "AROARHJJNAKQNLQASHVU7",
            "Arn": "arn:aws:iam::084375569056:role/service-role/AmazonSagemakerCanvasBedrockRole-20250521T124725",
            "CreateDate": "2025-05-21T19:47:53+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "BedrockAssumeRole",
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "bedrock.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole",
                        "Condition": {
                            "StringEquals": {
                                "aws:SourceAccount": "084375569056"
                            }
                        }
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/service-role/",
            "RoleName": "AmazonSagemakerCanvasBedrockRole-20250529T111613",
            "RoleId": "AROARHJJNAKQG4JQIFIK4",
            "Arn": "arn:aws:iam::084375569056:role/service-role/AmazonSagemakerCanvasBedrockRole-20250529T111613",
            "CreateDate": "2025-05-29T19:06:53+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "BedrockAssumeRole",
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "bedrock.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole",
                        "Condition": {
                            "StringEquals": {
                                "aws:SourceAccount": "084375569056"
                            }
                        }
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/braket.amazonaws.com/",
            "RoleName": "AWSServiceRoleForAmazonBraket",
            "RoleId": "AROARHJJNAKQMMGFWCIHO",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/braket.amazonaws.com/AWSServiceRoleForAmazonBraket",
            "CreateDate": "2025-05-14T18:58:51+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "braket.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/eks.amazonaws.com/",
            "RoleName": "AWSServiceRoleForAmazonEKS",
            "RoleId": "AROARHJJNAKQECIIRSQ7W",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS",
            "CreateDate": "2025-01-29T00:28:35+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "eks.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "Allows Amazon EKS to call AWS services on your behalf.",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/eks-nodegroup.amazonaws.com/",
            "RoleName": "AWSServiceRoleForAmazonEKSNodegroup",
            "RoleId": "AROARHJJNAKQLQSSH7O77",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup",
            "CreateDate": "2025-04-07T18:52:16+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "eks-nodegroup.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "This policy allows Amazon EKS to create and manage Nodegroups",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/elasticfilesystem.amazonaws.com/",
            "RoleName": "AWSServiceRoleForAmazonElasticFileSystem",
            "RoleId": "AROARHJJNAKQELYTR2YHR",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/elasticfilesystem.amazonaws.com/AWSServiceRoleForAmazonElasticFileSystem",
            "CreateDate": "2025-05-17T21:55:58+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "elasticfilesystem.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/ops.emr-serverless.amazonaws.com/",
            "RoleName": "AWSServiceRoleForAmazonEMRServerless",
            "RoleId": "AROARHJJNAKQLZYPKTDSQ",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/ops.emr-serverless.amazonaws.com/AWSServiceRoleForAmazonEMRServerless",
            "CreateDate": "2025-05-14T03:42:17+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "ops.emr-serverless.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/sagemaker.amazonaws.com/",
            "RoleName": "AWSServiceRoleForAmazonSageMakerNotebooks",
            "RoleId": "AROARHJJNAKQCWPFRVK7U",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/sagemaker.amazonaws.com/AWSServiceRoleForAmazonSageMakerNotebooks",
            "CreateDate": "2025-05-29T19:08:48+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "sagemaker.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "AWS SageMaker Notebooks Service Linked Role",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/autoscaling.amazonaws.com/",
            "RoleName": "AWSServiceRoleForAutoScaling",
            "RoleId": "AROARHJJNAKQAI54J2WST",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
            "CreateDate": "2025-01-30T21:35:28+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "autoscaling.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "Default Service-Linked Role enables access to AWS Services and Resources used or managed by Auto Scaling",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/ecs.amazonaws.com/",
            "RoleName": "AWSServiceRoleForECS",
            "RoleId": "AROARHJJNAKQHU2OPITLP",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
            "CreateDate": "2025-01-24T22:41:34+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "ecs.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "Policy to enable Amazon ECS to manage your EC2 instances and related resources.",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/elasticache.amazonaws.com/",
            "RoleName": "AWSServiceRoleForElastiCache",
            "RoleId": "AROARHJJNAKQIV77EA4SV",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/elasticache.amazonaws.com/AWSServiceRoleForElastiCache",
            "CreateDate": "2025-01-23T23:10:58+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "elasticache.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "This policy allows ElastiCache to manage AWS resources on your behalf as necessary for managing your cache.",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/elasticloadbalancing.amazonaws.com/",
            "RoleName": "AWSServiceRoleForElasticLoadBalancing",
            "RoleId": "AROARHJJNAKQHAP3JEYJQ",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
            "CreateDate": "2025-01-24T00:09:45+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "elasticloadbalancing.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "Allows ELB to call AWS services on your behalf.",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/network-firewall.amazonaws.com/",
            "RoleName": "AWSServiceRoleForNetworkFirewall",
            "RoleId": "AROARHJJNAKQPEK6GCMIL",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/network-firewall.amazonaws.com/AWSServiceRoleForNetworkFirewall",
            "CreateDate": "2024-12-24T00:15:17+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "network-firewall.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/organizations.amazonaws.com/",
            "RoleName": "AWSServiceRoleForOrganizations",
            "RoleId": "AROARHJJNAKQNPWGQLZQD",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/organizations.amazonaws.com/AWSServiceRoleForOrganizations",
            "CreateDate": "2025-01-13T19:27:11+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "organizations.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "Service-linked role used by AWS Organizations to enable integration of other AWS services with Organizations.",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/servicequotas.amazonaws.com/",
            "RoleName": "AWSServiceRoleForServiceQuotas",
            "RoleId": "AROARHJJNAKQHRXXYYQFQ",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/servicequotas.amazonaws.com/AWSServiceRoleForServiceQuotas",
            "CreateDate": "2025-05-29T18:16:54+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "servicequotas.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "A service-linked role is required for Service Quotas to access your service limits.",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/support.amazonaws.com/",
            "RoleName": "AWSServiceRoleForSupport",
            "RoleId": "AROARHJJNAKQKYWKXFCFT",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/support.amazonaws.com/AWSServiceRoleForSupport",
            "CreateDate": "2024-12-13T17:00:04+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "support.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "Enables resource access for AWS to provide billing, administrative and support services",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/aws-service-role/trustedadvisor.amazonaws.com/",
            "RoleName": "AWSServiceRoleForTrustedAdvisor",
            "RoleId": "AROARHJJNAKQMI663LPBV",
            "Arn": "arn:aws:iam::084375569056:role/aws-service-role/trustedadvisor.amazonaws.com/AWSServiceRoleForTrustedAdvisor",
            "CreateDate": "2024-12-13T17:00:04+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "trustedadvisor.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "Access for the AWS Trusted Advisor Service to help reduce cost, increase performance, and improve security of your AWS environment.",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/",
            "RoleName": "default-eks-node-group-20250620174644934400000002",
            "RoleId": "AROARHJJNAKQIPCWVB7IE",
            "Arn": "arn:aws:iam::084375569056:role/default-eks-node-group-20250620174644934400000002",
            "CreateDate": "2025-06-20T17:46:45+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "EKSNodeAssumeRole",
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "ec2.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "EKS managed node group IAM role",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/",
            "RoleName": "ecommerce-cluster-alb-controller",
            "RoleId": "AROARHJJNAKQPRMMTD2QW",
            "Arn": "arn:aws:iam::084375569056:role/ecommerce-cluster-alb-controller",
            "CreateDate": "2025-06-20T17:57:29+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Federated": "arn:aws:iam::084375569056:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/7C04F2EDB5C522741829BED52851F5E1"
                        },
                        "Action": "sts:AssumeRoleWithWebIdentity",
                        "Condition": {
                            "StringEquals": {
                                "arn:aws:iam::084375569056:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/7C04F2EDB5C522741829BED52851F5E1:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                            }
                        }
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/",
            "RoleName": "ecommerce-cluster-cluster-20250620174644934300000001",
            "RoleId": "AROARHJJNAKQO46POTQBH",
            "Arn": "arn:aws:iam::084375569056:role/ecommerce-cluster-cluster-20250620174644934300000001",
            "CreateDate": "2025-06-20T17:46:45+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "EKSClusterAssumeRole",
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "eks.amazonaws.com"
                        },
                        "Action": [
                            "sts:TagSession",
                            "sts:AssumeRole"
                        ]
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/",
            "RoleName": "eksctl-ecommerce-cluster-addon-iamserviceacco-Role1-OY1e3sroGXOi",
            "RoleId": "AROARHJJNAKQMMM4YJFEF",
            "Arn": "arn:aws:iam::084375569056:role/eksctl-ecommerce-cluster-addon-iamserviceacco-Role1-OY1e3sroGXOi",
            "CreateDate": "2025-06-10T23:50:45+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Federated": "arn:aws:iam::084375569056:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/FBEDC358103BF81590987173813C5E10"
                        },
                        "Action": "sts:AssumeRoleWithWebIdentity",
                        "Condition": {
                            "StringEquals": {
                                "oidc.eks.us-east-1.amazonaws.com/id/FBEDC358103BF81590987173813C5E10:aud": "sts.amazonaws.com",
                                "oidc.eks.us-east-1.amazonaws.com/id/FBEDC358103BF81590987173813C5E10:sub": "system:serviceaccount:app:ecommerce-sa"
                            }
                        }
                    }
                ]
            },
            "Description": "",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/",
            "RoleName": "eksctl-ecommerce-cluster-addon-iamserviceacco-Role1-pxV02YioKFsC",
            "RoleId": "AROARHJJNAKQIGD2VIY5I",
            "Arn": "arn:aws:iam::084375569056:role/eksctl-ecommerce-cluster-addon-iamserviceacco-Role1-pxV02YioKFsC",
            "CreateDate": "2025-06-11T00:42:40+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Federated": "arn:aws:iam::084375569056:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/FBEDC358103BF81590987173813C5E10"
                        },
                        "Action": "sts:AssumeRoleWithWebIdentity",
                        "Condition": {
                            "StringEquals": {
                                "oidc.eks.us-east-1.amazonaws.com/id/FBEDC358103BF81590987173813C5E10:aud": "sts.amazonaws.com",
                                "oidc.eks.us-east-1.amazonaws.com/id/FBEDC358103BF81590987173813C5E10:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                            }
                        }
                    }
                ]
            },
            "Description": "",
            "MaxSessionDuration": 3600
        },
        {
            "Path": "/",
            "RoleName": "terraform-admin",
            "RoleId": "AROARHJJNAKQO7T54P42E",
            "Arn": "arn:aws:iam::084375569056:role/terraform-admin",
            "CreateDate": "2025-06-20T17:46:44+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "AWS": "arn:aws:iam::084375569056:user/bluedragon"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "MaxSessionDuration": 3600
        }
    ]
}

