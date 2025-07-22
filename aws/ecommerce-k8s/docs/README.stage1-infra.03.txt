
tim@Tims-MBP stage1-infra % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/ecommerce-k8s/stage1-infra

tim@Tims-MBP stage1-infra % terraform apply tfplan
╷
│ Warning: Deprecated Parameter
│ 
│ The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.
╵
module.eks.aws_cloudwatch_log_group.this[0]: Creating...
module.vpc.aws_vpc.this[0]: Creating...
module.iam.aws_iam_policy.node_group_elb: Creating...
module.iam.aws_iam_policy.terraform_admin_ec2: Creating...
module.iam.aws_iam_policy.terraform_admin_eks: Creating...
module.iam.aws_iam_policy.terraform_admin_elb_other: Creating...
module.iam.aws_iam_policy.terraform_admin_backend: Creating...
module.iam.aws_iam_role.terraform_admin: Creating...
module.iam.aws_iam_policy.alb_controller_policy: Creating...
module.s3.aws_s3_bucket.app_bucket: Creating...
module.iam.aws_iam_policy.terraform_admin_elb_other: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/TerraformAdminELBOtherPolicy]
module.iam.aws_iam_policy.terraform_admin_ec2: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/TerraformAdminEC2Policy]
module.eks.aws_iam_role.this[0]: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role.this[0]: Creating...
module.iam.aws_iam_policy.terraform_admin_backend: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/TerraformAdminBackendPolicy]
module.eks.aws_iam_policy.custom[0]: Creating...
module.iam.aws_iam_policy.node_group_elb: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/ecommerce-cluster-EKSNodeGroupELBPolicy]
module.iam.aws_iam_policy.terraform_admin_eks: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/TerraformAdminEKSPolicy]
module.iam.aws_iam_policy.alb_controller_policy: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/ecommerce-cluster-AWSLoadBalancerControllerPolicy]
module.eks.aws_cloudwatch_log_group.this[0]: Creation complete after 1s [id=/aws/eks/ecommerce-cluster/cluster]
module.iam.aws_iam_role.terraform_admin: Creation complete after 1s [id=terraform-admin]
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_worker_policy: Creating...
module.iam.aws_iam_role_policy_attachment.terraform_admin_elb_other_attachment: Creating...
module.iam.aws_iam_role_policy_attachment.terraform_admin_ec2_attachment: Creating...
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_policy: Creating...
module.iam.aws_iam_role_policy_attachment.terraform_admin_backend_attachment: Creating...
module.iam.aws_iam_role_policy_attachment.terraform_admin_ec2_attachment: Creation complete after 0s [id=terraform-admin-20250620174645208700000004]
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_attachment: Creating...
module.iam.aws_iam_role_policy_attachment.terraform_admin_elb_other_attachment: Creation complete after 0s [id=terraform-admin-20250620174645213900000007]
module.iam.aws_iam_role_policy_attachment.terraform_admin_backend_attachment: Creation complete after 0s [id=terraform-admin-20250620174645217800000008]
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_policy: Creation complete after 0s [id=terraform-admin-20250620174645210500000005]
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_worker_policy: Creation complete after 0s [id=terraform-admin-20250620174645213700000006]
module.eks.aws_iam_policy.custom[0]: Creation complete after 0s [id=arn:aws:iam::084375569056:policy/ecommerce-cluster-cluster-20250620174644949100000003]
module.eks.module.eks_managed_node_group["default"].aws_iam_role.this[0]: Creation complete after 0s [id=default-eks-node-group-20250620174644934400000002]
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKSWorkerNodePolicy"]: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKS_CNI_Policy"]: Creating...
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEC2ContainerRegistryReadOnly"]: Creating...
module.eks.aws_iam_role.this[0]: Creation complete after 1s [id=ecommerce-cluster-cluster-20250620174644934300000001]
module.eks.aws_iam_role_policy_attachment.custom[0]: Creating...
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]: Creating...
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]: Creating...
module.eks.module.kms.data.aws_iam_policy_document.this[0]: Reading...
module.eks.module.kms.data.aws_iam_policy_document.this[0]: Read complete after 0s [id=428118965]
module.eks.module.kms.aws_kms_key.this[0]: Creating...
module.iam.aws_iam_role_policy_attachment.terraform_admin_eks_attachment: Creation complete after 1s [id=terraform-admin-20250620174645465800000009]
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKS_CNI_Policy"]: Creation complete after 1s [id=default-eks-node-group-20250620174644934400000002-2025062017464559990000000a]
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEKSWorkerNodePolicy"]: Creation complete after 1s [id=default-eks-node-group-20250620174644934400000002-2025062017464560330000000b]
module.eks.module.eks_managed_node_group["default"].aws_iam_role_policy_attachment.this["AmazonEC2ContainerRegistryReadOnly"]: Creation complete after 1s [id=default-eks-node-group-20250620174644934400000002-2025062017464561170000000c]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]: Creation complete after 0s [id=ecommerce-cluster-cluster-20250620174644934300000001-2025062017464565760000000d]
module.eks.aws_iam_role_policy_attachment.custom[0]: Creation complete after 0s [id=ecommerce-cluster-cluster-20250620174644934300000001-2025062017464566880000000e]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]: Creation complete after 0s [id=ecommerce-cluster-cluster-20250620174644934300000001-2025062017464568230000000f]
module.s3.aws_s3_bucket.app_bucket: Creation complete after 2s [id=blued-ecommerce-app-us-east-1-prod]
module.s3.aws_s3_bucket_public_access_block.app_bucket_public_access: Creating...
module.s3.aws_s3_bucket_server_side_encryption_configuration.app_bucket_encryption: Creating...
module.s3.aws_s3_bucket_versioning.app_bucket_versioning: Creating...
module.s3.aws_s3_bucket_public_access_block.app_bucket_public_access: Creation complete after 1s [id=blued-ecommerce-app-us-east-1-prod]
module.s3.aws_s3_bucket_server_side_encryption_configuration.app_bucket_encryption: Creation complete after 1s [id=blued-ecommerce-app-us-east-1-prod]
module.s3.aws_s3_bucket_versioning.app_bucket_versioning: Creation complete after 2s [id=blued-ecommerce-app-us-east-1-prod]
module.vpc.aws_vpc.this[0]: Still creating... [00m10s elapsed]
module.eks.module.kms.aws_kms_key.this[0]: Still creating... [00m10s elapsed]
module.vpc.aws_vpc.this[0]: Creation complete after 13s [id=vpc-00b854c121195db23]
module.vpc.aws_subnet.private[0]: Creating...
module.vpc.aws_route_table.public[0]: Creating...
module.vpc.aws_internet_gateway.this[0]: Creating...
module.vpc.aws_default_security_group.this[0]: Creating...
module.vpc.aws_subnet.private[1]: Creating...
module.eks.aws_security_group.node[0]: Creating...
module.vpc.aws_default_route_table.default[0]: Creating...
module.vpc.aws_subnet.public[0]: Creating...
module.vpc.aws_default_network_acl.this[0]: Creating...
module.vpc.aws_default_route_table.default[0]: Creation complete after 1s [id=rtb-04a1f50d764d3da04]
module.vpc.aws_subnet.public[1]: Creating...
module.vpc.aws_route_table.public[0]: Creation complete after 1s [id=rtb-01d9cabf8714e58d2]
module.eks.aws_security_group.cluster[0]: Creating...
module.vpc.aws_internet_gateway.this[0]: Creation complete after 1s [id=igw-0ab06ae2a214698ea]
module.networking.aws_security_group.app: Creating...
module.vpc.aws_subnet.public[0]: Creation complete after 1s [id=subnet-0c5a4d7d8bf702eb6]
module.vpc.aws_route_table.private[0]: Creating...
module.vpc.aws_subnet.private[1]: Creation complete after 1s [id=subnet-0310394bb972fac39]
module.vpc.aws_route.public_internet_gateway[0]: Creating...
module.vpc.aws_subnet.public[1]: Creation complete after 1s [id=subnet-01fb85e517215f049]
module.vpc.aws_eip.nat[0]: Creating...
module.vpc.aws_default_network_acl.this[0]: Creation complete after 2s [id=acl-047229ea7308907e0]
module.vpc.aws_route_table_association.public[1]: Creating...
module.vpc.aws_route_table.private[0]: Creation complete after 1s [id=rtb-02ac6390268bac8df]
module.vpc.aws_route_table_association.public[0]: Creating...
module.vpc.aws_route.public_internet_gateway[0]: Creation complete after 1s [id=r-rtb-01d9cabf8714e58d21080289494]
module.networking.aws_vpc_endpoint.s3: Creating...
module.vpc.aws_default_security_group.this[0]: Creation complete after 2s [id=sg-0221a525783bc8c1b]
module.vpc.aws_route_table_association.public[1]: Creation complete after 0s [id=rtbassoc-0583f61f065883de8]
module.eks.aws_security_group.node[0]: Creation complete after 3s [id=sg-046dc3a408c47257a]
module.vpc.aws_route_table_association.public[0]: Creation complete after 1s [id=rtbassoc-0fe10a9d7a801ab2e]
module.vpc.aws_subnet.private[0]: Creation complete after 3s [id=subnet-069f2b51476da8713]
module.vpc.aws_route_table_association.private[0]: Creating...
module.vpc.aws_route_table_association.private[1]: Creating...
module.vpc.aws_eip.nat[0]: Creation complete after 1s [id=eipalloc-0da7488804aae4bce]
module.vpc.aws_nat_gateway.this[0]: Creating...
module.vpc.aws_route_table_association.private[1]: Creation complete after 0s [id=rtbassoc-047b0a96775aa21bb]
module.vpc.aws_route_table_association.private[0]: Creation complete after 0s [id=rtbassoc-00ef50d992c6b40a1]
module.eks.aws_security_group.cluster[0]: Creation complete after 2s [id=sg-07e6d5c95653ee8c0]
module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]: Creating...
module.eks.aws_security_group_rule.node["egress_all"]: Creating...
module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"]: Creating...
module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"]: Creating...
module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]: Creation complete after 1s [id=sgrule-242760443]
module.networking.aws_security_group_rule.eks_control_plane_ingress: Creating...
module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]: Creation complete after 1s [id=sgrule-1627380612]
module.eks.aws_security_group_rule.node["ingress_cluster_443"]: Creating...
module.networking.aws_security_group.app: Creation complete after 3s [id=sg-0b3dac3cfaec6e11e]
module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]: Creating...
module.networking.aws_security_group_rule.eks_control_plane_ingress: Creation complete after 1s [id=sgrule-3232272649]
module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"]: Creating...
module.eks.aws_security_group_rule.node["egress_all"]: Creation complete after 2s [id=sgrule-3600250809]
module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"]: Creation complete after 3s [id=sgrule-67402453]
module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"]: Creating...
module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"]: Creation complete after 4s [id=sgrule-3364465189]
module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"]: Creation complete after 4s [id=sgrule-3808026704]
module.eks.aws_security_group_rule.node["ingress_cluster_443"]: Creation complete after 4s [id=sgrule-226579010]
module.eks.module.kms.aws_kms_key.this[0]: Still creating... [00m20s elapsed]
module.networking.aws_vpc_endpoint.s3: Creation complete after 7s [id=vpce-0ce9d391a443bda38]
module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]: Creation complete after 5s [id=sgrule-954711015]
module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"]: Creation complete after 5s [id=sgrule-733710278]
module.eks.module.kms.aws_kms_key.this[0]: Creation complete after 21s [id=465ad33f-bdbc-4960-8050-80fb30c359e3]
module.eks.module.kms.aws_kms_alias.this["cluster"]: Creating...
module.eks.aws_iam_policy.cluster_encryption[0]: Creating...
module.eks.module.kms.aws_kms_alias.this["cluster"]: Creation complete after 1s [id=alias/eks/ecommerce-cluster]
module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"]: Creation complete after 6s [id=sgrule-1548126252]
module.eks.aws_iam_policy.cluster_encryption[0]: Creation complete after 1s [id=arn:aws:iam::084375569056:policy/ecommerce-cluster-cluster-ClusterEncryption20250620174707404300000016]
module.eks.aws_iam_role_policy_attachment.cluster_encryption[0]: Creating...
module.eks.aws_iam_role_policy_attachment.cluster_encryption[0]: Creation complete after 0s [id=ecommerce-cluster-cluster-20250620174644934300000001-20250620174707887900000017]
module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"]: Creation complete after 5s [id=sgrule-3298850923]
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
module.vpc.aws_nat_gateway.this[0]: Creation complete after 1m25s [id=nat-0c4adcc266bf97d22]
module.vpc.aws_route.private_nat_gateway[0]: Creating...
module.vpc.aws_route.private_nat_gateway[0]: Creation complete after 1s [id=r-rtb-02ac6390268bac8df1080289494]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m30s elapsed]
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
module.eks.aws_eks_cluster.this[0]: Still creating... [09m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [09m10s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [09m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [09m30s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [09m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [09m51s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [10m01s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [10m11s elapsed]
module.eks.aws_eks_cluster.this[0]: Creation complete after 10m20s [id=ecommerce-cluster]
module.eks.aws_eks_access_entry.this["admin_user"]: Creating...
module.eks.aws_eks_access_entry.this["terraform_role"]: Creating...
module.eks.data.tls_certificate.this[0]: Reading...
module.eks.time_sleep.this[0]: Creating...
module.eks.data.tls_certificate.this[0]: Read complete after 0s [id=922877a0975ad078a65b8ff11ebc47b8311945c7]
module.eks.aws_iam_openid_connect_provider.oidc_provider[0]: Creating...
module.eks.aws_eks_access_entry.this["admin_user"]: Creation complete after 0s [id=ecommerce-cluster:arn:aws:iam::084375569056:user/bluedragon]
module.eks.aws_iam_openid_connect_provider.oidc_provider[0]: Creation complete after 1s [id=arn:aws:iam::084375569056:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/7C04F2EDB5C522741829BED52851F5E1]
module.iam.aws_iam_role.alb_controller: Creating...
module.eks.aws_eks_access_entry.this["terraform_role"]: Creation complete after 1s [id=ecommerce-cluster:arn:aws:iam::084375569056:role/terraform-admin]
module.eks.aws_eks_access_policy_association.this["admin_user_view_policy"]: Creating...
module.eks.aws_eks_access_policy_association.this["terraform_role_cluster_admin_policy"]: Creating...
module.eks.aws_eks_access_policy_association.this["admin_user_admin_policy"]: Creating...
module.eks.aws_eks_access_policy_association.this["terraform_role_admin_policy"]: Creating...
module.eks.aws_eks_access_policy_association.this["admin_user_cluster_admin_policy"]: Creating...
module.iam.aws_iam_role.alb_controller: Creation complete after 0s [id=ecommerce-cluster-alb-controller]
module.iam.aws_iam_role_policy_attachment.alb_controller_policy: Creating...
module.iam.aws_iam_role_policy_attachment.alb_controller_policy: Creation complete after 0s [id=ecommerce-cluster-alb-controller-20250620175730143800000018]
module.eks.aws_eks_access_policy_association.this["admin_user_admin_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:user/bluedragon#arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy]
module.eks.aws_eks_access_policy_association.this["terraform_role_admin_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:role/terraform-admin#arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy]
module.eks.aws_eks_access_policy_association.this["terraform_role_cluster_admin_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:role/terraform-admin#arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy]
module.eks.aws_eks_access_policy_association.this["admin_user_cluster_admin_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:user/bluedragon#arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy]
module.eks.aws_eks_access_policy_association.this["admin_user_view_policy"]: Creation complete after 1s [id=ecommerce-cluster#arn:aws:iam::084375569056:user/bluedragon#arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy]
module.eks.time_sleep.this[0]: Still creating... [00m10s elapsed]
module.eks.time_sleep.this[0]: Still creating... [00m20s elapsed]
module.eks.time_sleep.this[0]: Still creating... [00m30s elapsed]
module.eks.time_sleep.this[0]: Creation complete after 30s [id=2025-06-20T17:57:58Z]
module.eks.module.eks_managed_node_group["default"].module.user_data.null_resource.validate_cluster_service_cidr: Creating...
module.eks.module.eks_managed_node_group["default"].module.user_data.null_resource.validate_cluster_service_cidr: Creation complete after 0s [id=5873664579842108364]
module.eks.module.eks_managed_node_group["default"].aws_launch_template.this[0]: Creating...
module.eks.module.eks_managed_node_group["default"].aws_launch_template.this[0]: Creation complete after 7s [id=lt-0cc5fa9c3930487a6]
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
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [02m50s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [03m00s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Still creating... [03m10s elapsed]
module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]: Creation complete after 3m10s [id=ecommerce-cluster:default-2025062017580565600000001b]
module.iam.aws_iam_role_policy_attachment.node_group_elb: Creating...
module.iam.aws_iam_role_policy_attachment.node_group_elb: Creation complete after 1s [id=default-eks-node-group-20250620174644934400000002-2025062018011740290000001d]

Apply complete! Resources: 82 added, 0 changed, 0 destroyed.

Outputs:

cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJWTdROHVWNHIxOVF3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBMk1qQXhOelEyTkRaYUZ3MHpOVEEyTVRneE56VXhORFphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNiTnJFRksvRHRYcEZOWUhjUDBqZytXSlQrZUloY3ZsMmlrKzM0Y1FMWTRQZ3dSREFOdU1VZEtYWjIKT2VraHhEbFA2SGlNcjJBQUxMeFBxZm9ZUEtKOFpXb2szY3BlR1BpelZxR2dOamorMGF6SkVlRDAxREZmVDJGSQpRb1ZOSGE0V3RuSTljNUJOeWRsKzNUaWw3MlVGMXBUMFdvQVM1ZUNrRjZId3BJYVhqVkFhZEZ5VndBT3ovUXNUClZId1VUZmEzbmpxa1FTR3FYQXVVL0xWNjkrbjJKeTFoelhaSHYyV1lQT1J5b3FQbnFpdm12WXBhL2JPME1UUkcKTVFkWHpBUGFnanlSTU1jcm9Hd0VLQVV6aWpRWG96VGlmTkpwYlI5cysxLzNwd3hSRCtvNUp3M2dNNmd4TTVlMAozc1d4V3MwR0ZEZ21vNitOY3hmRUwrVEc5WTlOQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJURmNpT0NVaDh0UTA4SUZTVUh0UkY5WmEyNldEQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ1dBK01JYm1wYwpzWCsvYjZ6Rjk1WHFpeFNZMTFBdVZjRnlUTkg5TXZFakNxQnI0M3Q2ZWJKRExPTkN5YWZJOFpFQzlUbDA4MnkyClBLSTNHMFNnUTRuQy9zNVFsdWxMdy9kNGlOQTFlWGNVY2hrM1lUU3Fydm9wOHkzbTZtWnVCcXRwUGt0TVY2OEoKRVE2emRTOExibHNBRVRhVTFmVTRsc1V3REY0SUtKSmlXOVM2S1QxdzdFVExqc1QvY0tnWEY5aUlSYkcyNGdGcQp2MWFDdHdMVjNFUENnS081Vm5MNXRtUjhLYWtpeWxBUjhZN3hMRENvRkhGM2xsMnorZ3pOcmZ2QWxXNEo2NitWCmRIT3RvNFhKbzlrdXFSSzFjSXlUdk1nOFBsS1Q1MFE0cTdJL2lVTXA2R284Zjh2Vy9DUDY1QmJPa2ppRXBOc1AKenluVDhLN2poQnFlCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
cluster_endpoint = "https://7C04F2EDB5C522741829BED52851F5E1.gr7.us-east-1.eks.amazonaws.com"
cluster_name = "ecommerce-cluster"
s3_bucket_name = "blued-ecommerce-app-us-east-1-prod"
terraform_role_arn = "arn:aws:iam::084375569056:role/terraform-admin"
vpc_id = "vpc-00b854c121195db23"
tim@Tims-MBP stage1-infra % 

tim@Tims-MBP stage1-infra % terraform init -backend-config=backend.hcl
Initializing the backend...
Initializing modules...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/cloudinit from the dependency lock file
- Reusing previous version of hashicorp/time from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of hashicorp/tls from the dependency lock file
- Installing hashicorp/null v3.2.4...
- Installed hashicorp/null v3.2.4 (signed by HashiCorp)
- Installing hashicorp/tls v4.1.0...
- Installed hashicorp/tls v4.1.0 (signed by HashiCorp)
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)
- Using previously-installed hashicorp/cloudinit v2.3.7
- Using previously-installed hashicorp/time v0.13.1

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
tim@Tims-MBP stage1-infra % 


tim@Tims-MBP stage1-infra % terraform state list
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

tim@Tims-MBP stage1-infra % cd ../stage2-k8s 

tim@Tims-MBP stage2-k8s % terraform init -backend-config=backend.hcl -reconfigure
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/helm from the dependency lock file
- Reusing previous version of hashicorp/kubernetes from the dependency lock file
- Reusing previous version of hashicorp/time from the dependency lock file
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)
- Installing hashicorp/helm v2.17.0...
- Installed hashicorp/helm v2.17.0 (signed by HashiCorp)
- Installing hashicorp/kubernetes v2.37.1...
- Installed hashicorp/kubernetes v2.37.1 (signed by HashiCorp)
- Installing hashicorp/time v0.13.1...
- Installed hashicorp/time v0.13.1 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.


