
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

tim@Tims-MBP stage2-k8s % terraform import kubernetes_config_map.aws_auth kube-system/aws-auth
data.aws_eks_cluster.this: Reading...
data.aws_eks_cluster.this: Read complete after 1s [id=ecommerce-cluster]
kubernetes_config_map.aws_auth: Importing from ID "kube-system/aws-auth"...
kubernetes_config_map.aws_auth: Import prepared!
  Prepared kubernetes_config_map for import
kubernetes_config_map.aws_auth: Refreshing state... [id=kube-system/aws-auth]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.

tim@Tims-MBP stage2-k8s % terraform validate
Success! The configuration is valid.

tim@Tims-MBP stage2-k8s % terraform plan -out=tfplan -var-file=terraform.tfvars
time_sleep.wait_for_cluster: Refreshing state... [id=2025-06-20T18:33:09Z]
data.aws_eks_cluster.this: Reading...
data.aws_eks_cluster.this: Read complete after 0s [id=ecommerce-cluster]
kubernetes_config_map.aws_auth: Refreshing state... [id=kube-system/aws-auth]
kubernetes_cluster_role.bluedragon_admin: Refreshing state... [id=bluedragon-admin]
helm_release.aws_load_balancer_controller: Refreshing state... [id=aws-load-balancer-controller]
kubernetes_cluster_role_binding.bluedragon_admin_binding: Refreshing state... [id=bluedragon-admin-binding]
kubernetes_manifest.terraform_admin_clusterrole: Refreshing state...
kubernetes_manifest.bluedragon_impersonator_clusterrole: Refreshing state...
kubernetes_deployment.sample_app: Refreshing state... [id=default/sample-app]
kubernetes_manifest.terraform_admin_clusterrolebinding: Refreshing state...
kubernetes_service.sample_app: Refreshing state... [id=default/sample-app]
kubernetes_manifest.bluedragon_impersonator_clusterrolebinding: Refreshing state...
kubernetes_ingress_v1.sample_app: Refreshing state... [id=default/sample-app]

Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the last "terraform apply" which may have affected this plan:

  # kubernetes_cluster_role.bluedragon_admin has changed
  ~ resource "kubernetes_cluster_role" "bluedragon_admin" {
        id = "bluedragon-admin"

      ~ metadata {
          + annotations      = {}
          + labels           = {}
            name             = "bluedragon-admin"
            # (4 unchanged attributes hidden)
        }

        # (4 unchanged blocks hidden)
    }


Unless you have made equivalent changes to your configuration, or ignored the relevant attributes using ignore_changes, the following plan may include actions to undo or respond to
these changes.

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # kubernetes_config_map.aws_auth will be updated in-place
  ~ resource "kubernetes_config_map" "aws_auth" {
      ~ data        = {
          ~ "mapRoles" = <<-EOT
              - - groups:
              -   - system:bootstrappers
              -   - system:nodes
              -   rolearn: arn:aws:iam::084375569056:role/default-eks-node-group-20250620174644934400000002
              -   username: system:node:{{EC2PrivateDNSName}}
              + - "groups":
              +   - "system:bootstrappers"
              +   - "system:nodes"
              +   "rolearn": "arn:aws:iam::084375569056:role/default-eks-node-group-20250612215659371300000001"
              +   "username": "system:node:{{EC2PrivateDNSName}}"
              + - "groups":
              +   - "system:masters"
              +   "rolearn": "arn:aws:iam::084375569056:role/terraform-admin"
              +   "username": "terraform-admin"
            EOT
          + "mapUsers" = <<-EOT
                - userarn: arn:aws:iam::084375569056:user/bluedragon
                  username: bluedragon
                  groups:
                    - system:masters
            EOT
        }
        id          = "kube-system/aws-auth"
        # (2 unchanged attributes hidden)

        # (1 unchanged block hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

Changes to Outputs:
  ~ bluedragon_admin_role = [
      ~ {
          ~ annotations      = null -> {}
          ~ labels           = null -> {}
            name             = "bluedragon-admin"
            # (4 unchanged attributes hidden)
        },
    ]

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
Releasing state lock. This may take a few moments...

tim@Tims-MBP stage2-k8s % terraform apply tfplan
╷
│ Warning: Deprecated Parameter
│ 
│ The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.
╵
kubernetes_config_map.aws_auth: Modifying... [id=kube-system/aws-auth]
kubernetes_config_map.aws_auth: Modifications complete after 2s [id=kube-system/aws-auth]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

aws_auth_configmap = tolist([
  {
    "annotations" = tomap({})
    "generate_name" = ""
    "generation" = 0
    "labels" = tomap({})
    "name" = "aws-auth"
    "namespace" = "kube-system"
    "resource_version" = "1525"
    "uid" = "91a3e707-adee-461e-89a5-d3bd7e4030ca"
  },
])
bluedragon_admin_role = tolist([
  {
    "annotations" = tomap({})
    "generate_name" = ""
    "generation" = 0
    "labels" = tomap({})
    "name" = "bluedragon-admin"
    "resource_version" = "7098"
    "uid" = "09263995-9fb7-430e-8ce2-8e15dfa20120"
  },
])

tim@Tims-MBP stage2-k8s % terraform state list
data.aws_eks_cluster.this
helm_release.aws_load_balancer_controller
kubernetes_cluster_role.bluedragon_admin
kubernetes_cluster_role_binding.bluedragon_admin_binding
kubernetes_config_map.aws_auth
kubernetes_deployment.sample_app
kubernetes_ingress_v1.sample_app
kubernetes_manifest.bluedragon_impersonator_clusterrole
kubernetes_manifest.bluedragon_impersonator_clusterrolebinding
kubernetes_manifest.terraform_admin_clusterrole
kubernetes_manifest.terraform_admin_clusterrolebinding
kubernetes_service.sample_app
time_sleep.wait_for_cluster

