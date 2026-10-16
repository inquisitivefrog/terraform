# terraform
Configuration Knowledge for Future Reference

**Repo checks:** a pre-commit hook (`scripts/git-hooks/pre-commit`) and a
GitHub Action (`.github/workflows/repo-checks.yml`) block secrets, files that
`.gitignore` excludes, and unformatted Terraform. On a new clone run
`git config core.hooksPath scripts/git-hooks` once. Details, plus a cheat
sheet of the Terraform and security tools (pre-commit, trivy, tflint,
checkov, ...): [docs/REPO_CHECKS.md](docs/REPO_CHECKS.md).

**Status of the AWS rebuild:** [aws/tfstate/docs/STATUS.md](aws/tfstate/docs/STATUS.md)

AWS

1. tfstate: create S3 bucket for terraform.tfstate
            in dev, prod environments

2. single_instance: create resources 

   a. networking: VPC, subnets, EIP, NAT, IGW, security group, route table

   b. identity: IAM user, group, role, policy, instance_profile

   c. cache: elasticache cluster

   d. compute: EC2, ECS cluster

   e. eks: EKS cluster, EKS node group

   f. messages: SNS topic

   g. kms: KMS key, alias

   h. kubernetes: namespace, RBAC, quota, secret, ingress, deployment

3. ecommerce-k8s: create Kubernetes deployments and services and resources

   a. networking: VPC, subnets, EIP, NAT, IGW, security group, route table

   b. identity: IAM role, IAM policy

   c. cluster_config: EKS access entry, EKS access policy

   d. eks: EKS cluster, EKS node group, IAM OpenID

   e. helm: helm_release

   f. rbac: kubernetes_manifest

   g. s3: S3 bucket

   h. sample-app: kubernetes_deployment, kubernetes_service
