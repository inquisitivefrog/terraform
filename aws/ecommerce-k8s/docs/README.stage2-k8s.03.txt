

tim@Tims-MBP ecommerce-k8s % aws iam attach-user-policy --user-name bluedragon --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
tim@Tims-MBP stage2-k8s % aws iam get-policy --policy-arn arn:aws:iam::084375569056:policy/AWSLoadBalancerControllerIAMPolicy --region us-east-1
{
    "Policy": {
        "PolicyName": "AWSLoadBalancerControllerIAMPolicy",
        "PolicyId": "ANPARHJJNAKQH3HA5HMXA",
        "Arn": "arn:aws:iam::084375569056:policy/AWSLoadBalancerControllerIAMPolicy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 1,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2025-06-09T22:19:58+00:00",
        "UpdateDate": "2025-06-09T22:19:58+00:00",
        "Tags": []
    }
}
tim@Tims-MBP stage2-k8s % aws iam attach-user-policy --user-name bluedragon --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
tim@Tims-MBP stage2-k8s % aws sts get-caller-identity
{
    "UserId": "AIDARHJJNAKQBXQUGMWXF",
    "Account": "084375569056",
    "Arn": "arn:aws:iam::084375569056:user/bluedragon"
}
tim@Tims-MBP stage2-k8s % aws eks describe-cluster --name ecommerce-cluster --region us-east-1
{
    "cluster": {
        "name": "ecommerce-cluster",
        "arn": "arn:aws:eks:us-east-1:084375569056:cluster/ecommerce-cluster",
        "createdAt": "2025-06-20T10:47:10.528000-07:00",
        "version": "1.29",
        "endpoint": "https://7C04F2EDB5C522741829BED52851F5E1.gr7.us-east-1.eks.amazonaws.com",
        "roleArn": "arn:aws:iam::084375569056:role/ecommerce-cluster-cluster-20250620174644934300000001",
        "resourcesVpcConfig": {
            "subnetIds": [
                "subnet-069f2b51476da8713",
                "subnet-0310394bb972fac39"
            ],
            "securityGroupIds": [
                "sg-07e6d5c95653ee8c0"
            ],
            "clusterSecurityGroupId": "sg-0bf5a20a7d502582f",
            "vpcId": "vpc-00b854c121195db23",
            "endpointPublicAccess": true,
            "endpointPrivateAccess": true,
            "publicAccessCidrs": [
                "23.93.84.244/32"
            ]
        },
        "kubernetesNetworkConfig": {
            "serviceIpv4Cidr": "172.20.0.0/16",
            "ipFamily": "ipv4"
        },
        "logging": {
            "clusterLogging": [
                {
                    "types": [
                        "api",
                        "audit",
                        "authenticator",
                        "controllerManager",
                        "scheduler"
                    ],
                    "enabled": true
                }
            ]
        },
        "identity": {
            "oidc": {
                "issuer": "https://oidc.eks.us-east-1.amazonaws.com/id/7C04F2EDB5C522741829BED52851F5E1"
            }
        },
        "status": "ACTIVE",
        "certificateAuthority": {
            "data": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJWTdROHVWNHIxOVF3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBMk1qQXhOelEyTkRaYUZ3MHpOVEEyTVRneE56VXhORFphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNiTnJFRksvRHRYcEZOWUhjUDBqZytXSlQrZUloY3ZsMmlrKzM0Y1FMWTRQZ3dSREFOdU1VZEtYWjIKT2VraHhEbFA2SGlNcjJBQUxMeFBxZm9ZUEtKOFpXb2szY3BlR1BpelZxR2dOamorMGF6SkVlRDAxREZmVDJGSQpRb1ZOSGE0V3RuSTljNUJOeWRsKzNUaWw3MlVGMXBUMFdvQVM1ZUNrRjZId3BJYVhqVkFhZEZ5VndBT3ovUXNUClZId1VUZmEzbmpxa1FTR3FYQXVVL0xWNjkrbjJKeTFoelhaSHYyV1lQT1J5b3FQbnFpdm12WXBhL2JPME1UUkcKTVFkWHpBUGFnanlSTU1jcm9Hd0VLQVV6aWpRWG96VGlmTkpwYlI5cysxLzNwd3hSRCtvNUp3M2dNNmd4TTVlMAozc1d4V3MwR0ZEZ21vNitOY3hmRUwrVEc5WTlOQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJURmNpT0NVaDh0UTA4SUZTVUh0UkY5WmEyNldEQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ1dBK01JYm1wYwpzWCsvYjZ6Rjk1WHFpeFNZMTFBdVZjRnlUTkg5TXZFakNxQnI0M3Q2ZWJKRExPTkN5YWZJOFpFQzlUbDA4MnkyClBLSTNHMFNnUTRuQy9zNVFsdWxMdy9kNGlOQTFlWGNVY2hrM1lUU3Fydm9wOHkzbTZtWnVCcXRwUGt0TVY2OEoKRVE2emRTOExibHNBRVRhVTFmVTRsc1V3REY0SUtKSmlXOVM2S1QxdzdFVExqc1QvY0tnWEY5aUlSYkcyNGdGcQp2MWFDdHdMVjNFUENnS081Vm5MNXRtUjhLYWtpeWxBUjhZN3hMRENvRkhGM2xsMnorZ3pOcmZ2QWxXNEo2NitWCmRIT3RvNFhKbzlrdXFSSzFjSXlUdk1nOFBsS1Q1MFE0cTdJL2lVTXA2R284Zjh2Vy9DUDY1QmJPa2ppRXBOc1AKenluVDhLN2poQnFlCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
        },
        "platformVersion": "eks.39",
        "tags": {
            "terraform-aws-modules": "eks"
        },
        "encryptionConfig": [
            {
                "resources": [
                    "secrets"
                ],
                "provider": {
                    "keyArn": "arn:aws:kms:us-east-1:084375569056:key/465ad33f-bdbc-4960-8050-80fb30c359e3"
                }
            }
        ],
        "health": {
            "issues": []
        },
        "accessConfig": {
            "authenticationMode": "API_AND_CONFIG_MAP"
        },
        "upgradePolicy": {
            "supportType": "EXTENDED"
        }
    }
}
tim@Tims-MBP stage2-k8s % aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1 --profile default
Updated context arn:aws:eks:us-east-1:084375569056:cluster/ecommerce-cluster in /Users/tim/.kube/config


