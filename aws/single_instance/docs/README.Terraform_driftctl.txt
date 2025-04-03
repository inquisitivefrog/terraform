
Docs
----
1. https://github.com/snyk/driftctl
2. https://github.com/cloudskiff/driftctl-advanced-aws-tutorial

Installation
------------
tim@Tims-MacBook-Pro ~ % brew install driftctl
==> Auto-updating Homebrew...
Adjust how often this is run with HOMEBREW_AUTO_UPDATE_SECS or disable with
HOMEBREW_NO_AUTO_UPDATE. Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).
==> Auto-updated Homebrew!
Updated 4 taps (heroku/brew, hashicorp/tap, homebrew/core and homebrew/cask).
==> New Formulae
anubis              ente-cli            harsh               mcpm
dish                gdown               hjson               mob
easyeda2kicad       geesefs             is-fast             x-cmd
==> New Casks
atv-remote                 hamrs-pro                  restapia
bambu-connect              inmusic-software-center    slidepad
captainplugins             kilohearts-installer       stability-matrix
font-lxgw-wenkai-gb-lite   moment                     swift-shift
font-playpen-sans-deva     rave                       vesktop

You have 15 outdated formulae installed.

==> Downloading https://ghcr.io/v2/homebrew/core/driftctl/manifests/0.40.0
######################################################################### 100.0%
==> Fetching driftctl
==> Downloading https://ghcr.io/v2/homebrew/core/driftctl/blobs/sha256:8b9dfc0d2
######################################################################### 100.0%
==> Pouring driftctl--0.40.0.ventura.bottle.tar.gz
==> Caveats
zsh completions have been installed to:
  /usr/local/share/zsh/site-functions
==> Summary
🍺  /usr/local/Cellar/driftctl/0.40.0: 9 files, 71.9MB
==> Running `brew cleanup driftctl`...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).
==> `brew cleanup` has not been run in the last 30 days, running now...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).
Error: Permission denied @ apply2files - /usr/local/lib/docker/cli-plugins
tim@Tims-MacBook-Pro ~ % which driftctl
/usr/local/bin/driftctl
tim@Tims-MacBook-Pro ~ % driftctl version  
v0.40.0

Configure
---------
tim@Tims-MacBook-Pro ~ % ls -l $HOME/.driftctl
total 0
drwxr-xr-x  3 tim  staff  96 Apr  3 15:08 plugins

Execution
---------
tim@Tims-MacBook-Pro tfstate % driftctl scan
Scanned states (1) 
Found missing resources:
  From tfstate://terraform.tfstate
    - bluedragon-tfstate-admin-prod (module.storage.aws_s3_bucket.state_bucket)
    - bluedragon-tfstate-admin-prod-logs (module.storage.aws_s3_bucket.state_log_bucket)
    - bluedragon-tfstate-admin-prod-logs (module.storage.aws_s3_bucket_policy.state_log_bucket_policy)
    - bluedragon-tfstate-admin-prod (module.storage.aws_s3_bucket_public_access_block.block_public_access)
    - bluedragon-tfstate-admin-prod-logs (module.storage.aws_s3_bucket_public_access_block.state_log_bucket)
Found resources not covered by IaC:
  aws_iam_access_key:
    - AKIARHJJNAKQIIJBIAEZ
        User: bluedragon
    - AKIARHJJNAKQIYWAY4R3
        User: bluedragon
  aws_iam_group:
    - mygroup
    - sre
  aws_iam_policy:
    - arn:aws:iam::084375569056:policy/my-eks-cluster-cluster-20250129002812357700000002
    - arn:aws:iam::084375569056:policy/my-eks-cluster-cluster-ClusterEncryption2025012900283384830000000f
  aws_iam_policy_attachment:
    - AWSServiceRoleForAmazonEKS-arn:aws:iam::aws:policy/aws-service-role/AmazonEKSServiceRolePolicy
    - AWSServiceRoleForAutoScaling-arn:aws:iam::aws:policy/aws-service-role/AutoScalingServiceRolePolicy
    - AWSServiceRoleForECS-arn:aws:iam::aws:policy/aws-service-role/AmazonECSServiceRolePolicy
    - AWSServiceRoleForElastiCache-arn:aws:iam::aws:policy/aws-service-role/ElastiCacheServiceRolePolicy
    - AWSServiceRoleForElasticLoadBalancing-arn:aws:iam::aws:policy/aws-service-role/AWSElasticLoadBalancingServiceRolePolicy
    - AWSServiceRoleForNetworkFirewall-arn:aws:iam::aws:policy/aws-service-role/AWSNetworkFirewallServiceRolePolicy
    - EC2-arn:aws:iam::aws:policy/AdministratorAccess
    - ECS-arn:aws:iam::aws:policy/AdministratorAccess
    - ECS-arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole
    - bluedragon-arn:aws:iam::aws:policy/AdministratorAccess
    - bluedragon-arn:aws:iam::aws:policy/IAMUserChangePassword
    - example-eks-node-group-20250129003607721700000011-arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
    - example-eks-node-group-20250129003607721700000011-arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
    - example-eks-node-group-20250129003607721700000011-arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
    - my-eks-cluster-cluster-20250129002812356300000001-arn:aws:iam::084375569056:policy/my-eks-cluster-cluster-20250129002812357700000002
    - my-eks-cluster-cluster-20250129002812356300000001-arn:aws:iam::084375569056:policy/my-eks-cluster-cluster-ClusterEncryption2025012900283384830000000f
    - my-eks-cluster-cluster-20250129002812356300000001-arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
    - my-eks-cluster-cluster-20250129002812356300000001-arn:aws:iam::aws:policy/AmazonEKSVPCResourceController
    - mygroup-arn:aws:iam::aws:policy/AWSNetworkManagerFullAccess
    - mygroup-arn:aws:iam::aws:policy/AdministratorAccess
    - mygroup-arn:aws:iam::aws:policy/AmazonECS_FullAccess
    - mygroup-arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy
    - mygroup-arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
    - mygroup-arn:aws:iam::aws:policy/AmazonEKSComputePolicy
    - mygroup-arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy
    - mygroup-arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy
    - mygroup-arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
    - mygroup-arn:aws:iam::aws:policy/job-function/NetworkAdministrator
    - sre-arn:aws:iam::aws:policy/AdministratorAccess
  aws_iam_role:
    - EC2
    - ECS
    - example-eks-node-group-20250129003607721700000011
    - my-eks-cluster-cluster-20250129002812356300000001
  aws_iam_user:
    - bluedragon
  aws_key_pair:
    - bluedragon
  aws_kms_key:
    - 13382cf7-cf25-4e64-bb4b-33ae4d1f0e5e
    - 23512f1c-c660-44ca-a85b-1f4115c3b1c3
    - 3e270057-c07f-4024-a2ef-1b56de8b7683
    - 43c53d8e-90b3-47a1-b9bd-36697dbdeba0
    - 7566afa1-1454-4f7d-8ce8-308042df6975
    - 94bdaba3-b36f-48dd-b273-bd1fc152e5f3
    - 9d3fc11c-ae39-46e5-a62f-88cc87176b09
    - d19f6d1e-6ae7-47f1-9994-ee5aaae012aa
    - e9eeaf71-ea44-4e9f-87a6-989e5f532efa
  aws_network_acl_rule:
    - nacl-1841199975
        CIDR: 0.0.0.0/0, Egress: true, Network: acl-084b61fdb69f52b8d, Protocol: All, Rule number: 100
    - nacl-2288355613
        CIDR: 0.0.0.0/0, Egress: false, Network: acl-084b61fdb69f52b8d, Protocol: All, Rule number: 100
Found 57 resource(s)
 - 0% coverage
 - 0 resource(s) managed by Terraform
 - 52 resource(s) not managed by Terraform
 - 5 resource(s) found in a Terraform state but missing on the cloud provider
aws_sns_topic_subscription with incorrect subscription arn (PendingConfirmation) for endpoint "https://example.com/sns-notification" will be ignored
aws_sns_topic_subscription with incorrect subscription arn (PendingConfirmation) for endpoint "https://example.com/sns-notification" will be ignored
Scan duration: 14s
Provider version used to scan: 5.93.0. Use --tf-provider-version to use another version.

