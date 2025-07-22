
tim@Tims-MBP stage2-k8s % terraform validate
Success! The configuration is valid.

tim@Tims-MBP stage2-k8s % terraform plan -out=tfplan -var-file=terraform.tfvars  
:data.aws_eks_cluster.this: Reading...
data.aws_eks_cluster.this: Read complete after 0s [id=ecommerce-cluster]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # helm_release.aws_load_balancer_controller will be created
  + resource "helm_release" "aws_load_balancer_controller" {
      + atomic                     = false
      + chart                      = "aws-load-balancer-controller"
      + cleanup_on_fail            = false
      + create_namespace           = false
      + dependency_update          = false
      + disable_crd_hooks          = false
      + disable_openapi_validation = false
      + disable_webhooks           = false
      + force_update               = false
      + id                         = (known after apply)
      + lint                       = false
      + manifest                   = (known after apply)
      + max_history                = 0
      + metadata                   = (known after apply)
      + name                       = "aws-load-balancer-controller"
      + namespace                  = "kube-system"
      + pass_credentials           = false
      + recreate_pods              = false
      + render_subchart_notes      = true
      + replace                    = false
      + repository                 = "https://aws.github.io/eks-charts"
      + reset_values               = false
      + reuse_values               = false
      + skip_crds                  = false
      + status                     = "deployed"
      + timeout                    = 300
      + verify                     = false
      + version                    = "1.13.3"
      + wait                       = true
      + wait_for_jobs              = false

      + set {
          + name  = "clusterName"
          + value = "ecommerce-cluster"
            # (1 unchanged attribute hidden)
        }
      + set {
          + name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
          + value = "arn:aws:iam::084375569056:role/ecommerce-cluster-alb-controller"
            # (1 unchanged attribute hidden)
        }
      + set {
          + name  = "serviceAccount.create"
          + value = "true"
            # (1 unchanged attribute hidden)
        }
      + set {
          + name  = "serviceAccount.name"
          + value = "aws-load-balancer-controller"
            # (1 unchanged attribute hidden)
        }
    }

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

  # kubernetes_ingress_v1.sample_app will be created
  + resource "kubernetes_ingress_v1" "sample_app" {
      + id     = (known after apply)
      + status = (known after apply)

      + metadata {
          + annotations      = {
              + "alb.ingress.kubernetes.io/healthcheck-path" = "/"
              + "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
              + "alb.ingress.kubernetes.io/target-type"      = "ip"
              + "kubernetes.io/ingress.class"                = "alb"
            }
          + generation       = (known after apply)
          + name             = "sample-app"
          + namespace        = "default"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + spec {
          + ingress_class_name = (known after apply)

          + rule {
              + http {
                  + path {
                      + path      = "/"
                      + path_type = "Prefix"

                      + backend {
                          + service {
                              + name = "sample-app"

                              + port {
                                  + number = 80
                                }
                            }
                        }
                    }
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
          + type                              = "ClusterIP"

          + port {
              + node_port   = (known after apply)
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

Plan: 12 to add, 0 to change, 0 to destroy.

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

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
Releasing state lock. This may take a few moments...
tim@Tims-MBP stage2-k8s % :

