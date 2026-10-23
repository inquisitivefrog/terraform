data "aws_eks_cluster" "this" {
  name = "ecommerce-cluster"
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "stage1_infra" {
  backend = "s3"
  config = {
    bucket  = "blue-elephant-ecommerce-terraform-state"
    key     = "ecommerce-k8s/stage1-infra/terraform.tfstate" # matches stage1-infra/backend.hcl
    region  = "us-east-2"
    profile = "blue-elephant"
  }
}

# EKS creates aws-auth with the node role when the node group joins, so
# Terraform takes over its keys (force) rather than creating the ConfigMap.
# Access entries (stage1) grant the same access; this keeps CONFIG_MAP auth
# working too.
resource "kubernetes_config_map_v1_data" "aws_auth" {
  force = true
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode([
      {
        rolearn  = data.terraform_remote_state.stage1_infra.outputs.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = data.terraform_remote_state.stage1_infra.outputs.terraform_role_arn
        username = "terraform-admin"
        groups   = ["system:masters"]
      }
    ])
    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.admin_user_name}"
        username = var.admin_user_name
        groups   = ["system:masters"]
      }
    ])
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.9.1"
  timeout    = 1200
  wait       = true

  set {
    name  = "clusterName"
    value = "ecommerce-cluster"
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller" # matches stage1's aws_eks_pod_identity_association
  }
  set {
    name  = "region"
    value = "us-east-2"
  }
  set {
    name  = "vpcId"
    value = data.terraform_remote_state.stage1_infra.outputs.vpc_id
  }
  set {
    name  = "env.AWS_DEFAULT_REGION"
    value = "us-east-2"
  }
  set {
    name  = "env.AWS_STS_REGIONAL_ENDPOINTS"
    value = "regional"
  }
  set {
    name  = "serviceAccount.automountServiceAccountToken"
    value = "true"
  }
}

resource "random_password" "argocd_secretkey" {
  length  = 32
  special = false
}

resource "helm_release" "argocd" {
  # Its server Service is a LoadBalancer: remove it while the controller runs.
  depends_on       = [helm_release.aws_load_balancer_controller]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "2.17.0"
  create_namespace = true
  timeout          = 1200
  wait             = true

  values = [
    yamlencode({
      dex = {
        enabled = false
      }
      notifications = {
        enabled = false
      }
      server = {
        service = {
          type                     = "LoadBalancer"
          loadBalancerSourceRanges = [var.my_laptop_cidr_block] # the UI is plain HTTP (--insecure)
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-subnets" = join(",", data.terraform_remote_state.stage1_infra.outputs.vpc_public_subnets)
            # The controller turns this Service into an NLB, internal unless told otherwise
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
        extraArgs = [
          "--insecure"
        ]
        secret = {
          create          = true
          serverSecretKey = random_password.argocd_secretkey.result
        }
        resources = {
          limits = {
            cpu    = "250m"
            memory = "256Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }
      controller = {
        resources = {
          limits = {
            cpu    = "250m"
            memory = "256Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }
      repoServer = {
        resources = {
          limits = {
            cpu    = "250m"
            memory = "256Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }
      redis = {
        resources = {
          limits = {
            cpu    = "250m"
            memory = "128Mi"
          }
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
        }
      }
    })
  ]
}

resource "helm_release" "ecommerce_app" {
  depends_on       = [helm_release.aws_load_balancer_controller]
  name             = "ecommerce-app"
  chart            = "./../charts/ecommerce-app"
  namespace        = "default"
  create_namespace = true
  timeout          = 600
  wait             = true

  set {
    name  = "replicaCount"
    value = "1"
  }
  set {
    name  = "image.repository"
    value = "hashicorp/http-echo"
  }
  set {
    name  = "service.port"
    value = "80"
  }
  set {
    name  = "service.targetPort"
    value = "5678"
  }
}

resource "kubernetes_ingress_v1" "ecommerce_app" {
  metadata {
    name      = "ecommerce-app"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class"             = "alb"
      "alb.ingress.kubernetes.io/scheme"        = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"   = "ip"
      "alb.ingress.kubernetes.io/subnets"       = join(",", data.terraform_remote_state.stage1_infra.outputs.vpc_public_subnets)
      "alb.ingress.kubernetes.io/inbound-cidrs" = var.my_laptop_cidr_block
    }
  }
  # Waits for the ALB hostname, so the ingress_hostname output is filled in
  wait_for_load_balancer = true
  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "ecommerce-app-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  timeouts {
    create = "10m"
    delete = "10m"
  }
  # Deleted before the controller, which must remove the ALB and the
  # ingress.k8s.aws/resources finalizer; otherwise the Ingress hangs and the
  # ALB is orphaned, blocking stage1's VPC destroy (single_instance dev hit
  # the hang 2026-10-22).
  depends_on = [helm_release.aws_load_balancer_controller, helm_release.ecommerce_app]
}

resource "kubernetes_manifest" "blue_elephant_admin_clusterrole" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "blue-elephant-admin"
    }
    rules = [
      {
        apiGroups = [""]
        resources = ["nodes", "pods", "services", "namespaces"]
        verbs     = ["get", "list", "watch", "create", "update", "delete"]
      },
      {
        apiGroups = ["apps"]
        resources = ["deployments", "replicasets"]
        verbs     = ["get", "list", "watch", "create", "update", "delete"]
      },
      {
        apiGroups = ["rbac.authorization.k8s.io"]
        resources = ["clusterroles", "clusterrolebindings"]
        verbs     = ["get", "list", "watch", "create", "update", "delete"]
      },
      {
        apiGroups = [""]
        resources = ["users", "groups"]
        verbs     = ["impersonate"]
      }
    ]
  }
}

resource "kubernetes_manifest" "blue_elephant_admin_clusterrolebinding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "blue-elephant-admin"
    }
    subjects = [
      {
        kind     = "User"
        name     = var.admin_user_name
        apiGroup = "rbac.authorization.k8s.io"
      }
    ]
    roleRef = {
      kind     = "ClusterRole"
      name     = "blue-elephant-admin"
      apiGroup = "rbac.authorization.k8s.io"
    }
  }
}

resource "kubernetes_manifest" "blue_elephant_impersonator_clusterrole" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "blue-elephant-impersonator"
    }
    rules = [
      {
        apiGroups = [""]
        resources = ["users", "groups"]
        verbs     = ["impersonate"]
      }
    ]
  }
}

resource "kubernetes_manifest" "blue_elephant_impersonator_clusterrolebinding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "blue-elephant-impersonator"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "aws-load-balancer-controller"
        namespace = "kube-system"
      }
    ]
    roleRef = {
      kind     = "ClusterRole"
      name     = "blue-elephant-impersonator"
      apiGroup = "rbac.authorization.k8s.io"
    }
  }
}

resource "kubernetes_manifest" "terraform_admin_clusterrole" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "terraform-admin"
    }
    rules = [
      {
        apiGroups = ["*"]
        resources = ["*"]
        verbs     = ["*"]
      }
    ]
  }
}

resource "kubernetes_manifest" "terraform_admin_clusterrolebinding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "terraform-admin"
    }
    subjects = [
      {
        kind     = "User"
        name     = "terraform-admin"
        apiGroup = "rbac.authorization.k8s.io"
      }
    ]
    roleRef = {
      kind     = "ClusterRole"
      name     = "terraform-admin"
      apiGroup = "rbac.authorization.k8s.io"
    }
  }
}
