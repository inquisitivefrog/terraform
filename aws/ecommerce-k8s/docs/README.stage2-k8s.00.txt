
tim@Tims-MacBook-Pro stage1-infra % cd ../stage2-k8s 
tim@Tims-MacBook-Pro stage2-k8s % terraform init -backend-config=backend.hcl   
Initializing the backend...
Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Reusing previous version of hashicorp/time from the dependency lock file
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/kubernetes from the dependency lock file
- Using previously-installed hashicorp/kubernetes v2.37.1
- Using previously-installed hashicorp/time v0.13.1
- Using previously-installed hashicorp/aws v5.95.0
Terraform has made some changes to the provider dependency selections recorded
in the .terraform.lock.hcl file. Review those changes and commit them to your
version control system if they represent changes you intended to make.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
tim@Tims-MacBook-Pro stage2-k8s % terraform validate
Success! The configuration is valid.

tim@Tims-MacBook-Pro stage2-k8s % terraform plan -out=tfplan -var-file=terraform.tfvars
data.terraform_remote_state.stage1_infra: Reading...
data.aws_eks_cluster.this: Reading...
data.aws_eks_cluster_auth.this: Reading...
data.aws_eks_cluster_auth.this: Read complete after 0s [id=ecommerce-cluster]
data.terraform_remote_state.stage1_infra: Read complete after 2s
data.aws_eks_cluster.this: Read complete after 1s [id=ecommerce-cluster]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with
the following symbols:
  + create

Terraform will perform the following actions:

  # kubernetes_cluster_role.bluedragon_admin will be created
  + resource "kubernetes_cluster_role" "bluedragon_admin" {
      + id = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "bluedragon-admin"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + rule {
          + api_groups = [
              + null,
            ]
          + resources  = [
              + "nodes",
              + "pods",
              + "services",
              + "namespaces",
            ]
          + verbs      = [
              + "get",
              + "list",
              + "watch",
              + "create",
              + "update",
              + "delete",
            ]
        }
      + rule {
          + api_groups = [
              + "apps",
            ]
          + resources  = [
              + "deployments",
              + "replicasets",
            ]
          + verbs      = [
              + "get",
              + "list",
              + "watch",
              + "create",
              + "update",
              + "delete",
            ]
        }
      + rule {
          + api_groups = [
              + "rbac.authorization.k8s.io",
            ]
          + resources  = [
              + "clusterroles",
              + "clusterrolebindings",
            ]
          + verbs      = [
              + "get",
              + "list",
              + "watch",
              + "create",
              + "update",
              + "delete",
            ]
        }
      + rule {
          + api_groups = [
              + null,
            ]
          + resources  = [
              + "users",
              + "groups",
            ]
          + verbs      = [
              + "impersonate",
            ]
        }
    }

  # kubernetes_cluster_role_binding.bluedragon_admin_binding will be created
  + resource "kubernetes_cluster_role_binding" "bluedragon_admin_binding" {
      + id = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "bluedragon-admin-binding"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + role_ref {
          + api_group = "rbac.authorization.k8s.io"
          + kind      = "ClusterRole"
          + name      = "bluedragon-admin"
        }

      + subject {
          + api_group = "rbac.authorization.k8s.io"
          + kind      = "User"
          + name      = "bluedragon"
          + namespace = "default"
        }
    }

  # kubernetes_config_map.aws_auth will be created
  + resource "kubernetes_config_map" "aws_auth" {
      + data = {
          + "mapRoles" = <<-EOT
                - "groups":
                  - "system:bootstrappers"
                  - "system:nodes"
                  "rolearn": "arn:aws:iam::084375569056:role/default-eks-node-group-20250612215659371300000001"
                  "username": "system:node:{{EC2PrivateDNSName}}"
                - "groups":
                  - "system:masters"
                  "rolearn": "arn:aws:iam::084375569056:role/terraform-admin"
                  "username": "terraform-admin"
            EOT
          + "mapUsers" = <<-EOT
                - userarn: arn:aws:iam::084375569056:user/bluedragon
                  username: bluedragon
                  groups:
                    - system:masters
            EOT
        }
      + id   = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "aws-auth"
          + namespace        = "kube-system"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }
    }

  # kubernetes_deployment.sample_app will be created
  + resource "kubernetes_deployment" "sample_app" {
      + id               = (known after apply)
      + wait_for_rollout = true

      + metadata {
          + generation       = (known after apply)
          + name             = "sample-app"
          + namespace        = "default"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + spec {
          + min_ready_seconds         = 0
          + paused                    = false
          + progress_deadline_seconds = 600
          + replicas                  = "2"
          + revision_history_limit    = 10

          + selector {
              + match_labels = {
                  + "app" = "sample-app"
                }
            }

          + strategy (known after apply)

          + template {
              + metadata {
                  + generation       = (known after apply)
                  + labels           = {
                      + "app" = "sample-app"
                    }
                  + name             = (known after apply)
                  + resource_version = (known after apply)
                  + uid              = (known after apply)
                }
              + spec {
                  + automount_service_account_token  = true
                  + dns_policy                       = "ClusterFirst"
                  + enable_service_links             = true
                  + host_ipc                         = false
                  + host_network                     = false
                  + host_pid                         = false
                  + hostname                         = (known after apply)
                  + node_name                        = (known after apply)
                  + restart_policy                   = "Always"
                  + scheduler_name                   = (known after apply)
                  + service_account_name             = (known after apply)
                  + share_process_namespace          = false
                  + termination_grace_period_seconds = 30

                  + container {
                      + image                      = "nginx:latest"
                      + image_pull_policy          = (known after apply)
                      + name                       = "sample-app"
                      + stdin                      = false
                      + stdin_once                 = false
                      + termination_message_path   = "/dev/termination-log"
                      + termination_message_policy = (known after apply)
                      + tty                        = false

                      + port {
                          + container_port = 80
                          + protocol       = "TCP"
                        }

                      + resources (known after apply)
                    }

                  + image_pull_secrets (known after apply)

                  + readiness_gate (known after apply)
                }
            }
        }
    }

  # kubernetes_manifest.bluedragon_impersonator_clusterrole will be created
  + resource "kubernetes_manifest" "bluedragon_impersonator_clusterrole" {
      + manifest = {
          + apiVersion = "rbac.authorization.k8s.io/v1"
          + kind       = "ClusterRole"
          + metadata   = {
              + name = "bluedragon-impersonator"
            }
          + rules      = [
              + {
                  + apiGroups = [
                      + "",
                    ]
                  + resources = [
                      + "users",
                      + "groups",
                    ]
                  + verbs     = [
                      + "impersonate",
                    ]
                },
            ]
        }
      + object   = {
          + aggregationRule = {
              + clusterRoleSelectors = (known after apply)
            }
          + apiVersion      = "rbac.authorization.k8s.io/v1"
          + kind            = "ClusterRole"
          + metadata        = {
              + annotations                = (known after apply)
              + creationTimestamp          = (known after apply)
              + deletionGracePeriodSeconds = (known after apply)
              + deletionTimestamp          = (known after apply)
              + finalizers                 = (known after apply)
              + generateName               = (known after apply)
              + generation                 = (known after apply)
              + labels                     = (known after apply)
              + managedFields              = (known after apply)
              + name                       = "bluedragon-impersonator"
              + namespace                  = (known after apply)
              + ownerReferences            = (known after apply)
              + resourceVersion            = (known after apply)
              + selfLink                   = (known after apply)
              + uid                        = (known after apply)
            }
          + rules           = [
              + {
                  + apiGroups       = [
                      + "",
                    ]
                  + nonResourceURLs = (known after apply)
                  + resourceNames   = (known after apply)
                  + resources       = [
                      + "users",
                      + "groups",
                    ]
                  + verbs           = [
                      + "impersonate",
                    ]
                },
            ]
        }
    }

  # kubernetes_manifest.bluedragon_impersonator_clusterrolebinding will be created
  + resource "kubernetes_manifest" "bluedragon_impersonator_clusterrolebinding" {
      + manifest = {
          + apiVersion = "rbac.authorization.k8s.io/v1"
          + kind       = "ClusterRoleBinding"
          + metadata   = {
              + name = "bluedragon-impersonator"
            }
          + roleRef    = {
              + apiGroup = "rbac.authorization.k8s.io"
              + kind     = "ClusterRole"
              + name     = "bluedragon-impersonator"
            }
          + subjects   = [
              + {
                  + apiGroup = "rbac.authorization.k8s.io"
                  + kind     = "User"
                  + name     = "bluedragon"
                },
            ]
        }
      + object   = {
          + apiVersion = "rbac.authorization.k8s.io/v1"
          + kind       = "ClusterRoleBinding"
          + metadata   = {
              + annotations                = (known after apply)
              + creationTimestamp          = (known after apply)
              + deletionGracePeriodSeconds = (known after apply)
              + deletionTimestamp          = (known after apply)
              + finalizers                 = (known after apply)
              + generateName               = (known after apply)
              + generation                 = (known after apply)
              + labels                     = (known after apply)
              + managedFields              = (known after apply)
              + name                       = "bluedragon-impersonator"
              + namespace                  = (known after apply)
              + ownerReferences            = (known after apply)
              + resourceVersion            = (known after apply)
              + selfLink                   = (known after apply)
              + uid                        = (known after apply)
            }
          + roleRef    = {
              + apiGroup = "rbac.authorization.k8s.io"
              + kind     = "ClusterRole"
              + name     = "bluedragon-impersonator"
            }
          + subjects   = [
              + {
                  + apiGroup  = "rbac.authorization.k8s.io"
                  + kind      = "User"
                  + name      = "bluedragon"
                  + namespace = (known after apply)
                },
            ]
        }
    }

  # kubernetes_manifest.terraform_admin_clusterrole will be created
  + resource "kubernetes_manifest" "terraform_admin_clusterrole" {
      + manifest = {
          + apiVersion = "rbac.authorization.k8s.io/v1"
          + kind       = "ClusterRole"
          + metadata   = {
              + name = "terraform-admin"
            }
          + rules      = [
              + {
                  + apiGroups = [
                      + "*",
                    ]
                  + resources = [
                      + "*",
                    ]
                  + verbs     = [
                      + "*",
                    ]
                },
            ]
        }
      + object   = {
          + aggregationRule = {
              + clusterRoleSelectors = (known after apply)
            }
          + apiVersion      = "rbac.authorization.k8s.io/v1"
          + kind            = "ClusterRole"
          + metadata        = {
              + annotations                = (known after apply)
              + creationTimestamp          = (known after apply)
              + deletionGracePeriodSeconds = (known after apply)
              + deletionTimestamp          = (known after apply)
              + finalizers                 = (known after apply)
              + generateName               = (known after apply)
              + generation                 = (known after apply)
              + labels                     = (known after apply)
              + managedFields              = (known after apply)
              + name                       = "terraform-admin"
              + namespace                  = (known after apply)
              + ownerReferences            = (known after apply)
              + resourceVersion            = (known after apply)
              + selfLink                   = (known after apply)
              + uid                        = (known after apply)
            }
          + rules           = [
              + {
                  + apiGroups       = [
                      + "*",
                    ]
                  + nonResourceURLs = (known after apply)
                  + resourceNames   = (known after apply)
                  + resources       = [
                      + "*",
                    ]
                  + verbs           = [
                      + "*",
                    ]
                },
            ]
        }
    }

  # kubernetes_manifest.terraform_admin_clusterrolebinding will be created
  + resource "kubernetes_manifest" "terraform_admin_clusterrolebinding" {
      + manifest = {
          + apiVersion = "rbac.authorization.k8s.io/v1"
          + kind       = "ClusterRoleBinding"
          + metadata   = {
              + name = "terraform-admin"
            }
          + roleRef    = {
              + apiGroup = "rbac.authorization.k8s.io"
              + kind     = "ClusterRole"
              + name     = "terraform-admin"
            }
          + subjects   = [
              + {
                  + apiGroup = "rbac.authorization.k8s.io"
                  + kind     = "User"
                  + name     = "terraform-admin"
                },
            ]
        }
      + object   = {
          + apiVersion = "rbac.authorization.k8s.io/v1"
          + kind       = "ClusterRoleBinding"
          + metadata   = {
              + annotations                = (known after apply)
              + creationTimestamp          = (known after apply)
              + deletionGracePeriodSeconds = (known after apply)
              + deletionTimestamp          = (known after apply)
              + finalizers                 = (known after apply)
              + generateName               = (known after apply)
              + generation                 = (known after apply)
              + labels                     = (known after apply)
              + managedFields              = (known after apply)
              + name                       = "terraform-admin"
              + namespace                  = (known after apply)
              + ownerReferences            = (known after apply)
              + resourceVersion            = (known after apply)
              + selfLink                   = (known after apply)
              + uid                        = (known after apply)
            }
          + roleRef    = {
              + apiGroup = "rbac.authorization.k8s.io"
              + kind     = "ClusterRole"
              + name     = "terraform-admin"
            }
          + subjects   = [
              + {
                  + apiGroup  = "rbac.authorization.k8s.io"
                  + kind      = "User"
                  + name      = "terraform-admin"
                  + namespace = (known after apply)
                },
            ]
        }
    }

  # kubernetes_service.sample_app will be created
  + resource "kubernetes_service" "sample_app" {
      + id                     = (known after apply)
      + status                 = (known after apply)
      + wait_for_load_balancer = true

      + metadata {
          + generation       = (known after apply)
          + name             = "sample-app"
          + namespace        = "default"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + spec {
          + allocate_load_balancer_node_ports = true
          + cluster_ip                        = (known after apply)
          + cluster_ips                       = (known after apply)
          + external_traffic_policy           = (known after apply)
          + health_check_node_port            = (known after apply)
          + internal_traffic_policy           = (known after apply)
          + ip_families                       = (known after apply)
          + ip_family_policy                  = (known after apply)
          + publish_not_ready_addresses       = false
          + selector                          = {
              + "app" = "sample-app"
            }
          + session_affinity                  = "None"
          + type                              = "NodePort"

          + port {
              + node_port   = 30080
              + port        = 80
              + protocol    = "TCP"
              + target_port = "80"
            }

          + session_affinity_config (known after apply)
        }
    }

  # time_sleep.wait_for_cluster will be created
  + resource "time_sleep" "wait_for_cluster" {
      + create_duration = "120s"
      + id              = (known after apply)
    }

Plan: 10 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + aws_auth_configmap    = [
      + {
          + annotations      = null
          + generate_name    = null
          + generation       = (known after apply)
          + labels           = null
          + name             = "aws-auth"
          + namespace        = "kube-system"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        },
    ]
  + bluedragon_admin_role = [
      + {
          + annotations      = null
          + generate_name    = null
          + generation       = (known after apply)
          + labels           = null
          + name             = "bluedragon-admin"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        },
    ]

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
Releasing state lock. This may take a few moments...
tim@Tims-MacBook-Pro stage2-k8s % terraform apply tfplan
╷
│ Warning: Deprecated Parameter
│ 
│ The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.
╵
time_sleep.wait_for_cluster: Creating...
time_sleep.wait_for_cluster: Still creating... [00m10s elapsed]
time_sleep.wait_for_cluster: Still creating... [00m20s elapsed]
time_sleep.wait_for_cluster: Still creating... [00m30s elapsed]
time_sleep.wait_for_cluster: Still creating... [00m40s elapsed]
time_sleep.wait_for_cluster: Still creating... [00m50s elapsed]
time_sleep.wait_for_cluster: Still creating... [01m00s elapsed]
time_sleep.wait_for_cluster: Still creating... [01m10s elapsed]
time_sleep.wait_for_cluster: Still creating... [01m20s elapsed]



