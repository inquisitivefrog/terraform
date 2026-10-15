data "aws_eks_cluster" "this" {
  name = "ecommerce-cluster"
}

data "aws_eks_cluster_auth" "this" {
  name = "ecommerce-cluster"
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "stage1_infra" {
  backend = "s3"
  config = {
    bucket = "bluedragon-ecommerce-terraform-state"
    key    = "stage1-infra/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

resource "kubernetes_config_map_v1" "aws_auth" {
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
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.terraform_remote_state.stage1_infra.outputs.alb_controller_role_arn
  }
  set {
    name  = "region"
    value = "us-east-1"
  }
  set {
    name  = "vpcId"
    value = data.terraform_remote_state.stage1_infra.outputs.vpc_id
  }
  set {
    name  = "env.AWS_DEFAULT_REGION"
    value = "us-east-1"
  }
  set {
    name  = "env.AWS_STS_REGIONAL_ENDPOINTS"
    value = "regional"
  }
  set {
    name  = "serviceAccount.automountServiceAccountToken"
    value = "true"
  }
  set {
    name  = "serviceAccount.token.enabled"
    value = "true"
  }
  set {
    name  = "serviceAccount.token.audiences[0]"
    value = "sts.amazonaws.com"
  }
  set {
    name  = "serviceAccount.token.expirationSeconds"
    value = "86400"
  }
}

resource "random_password" "argocd_secretkey" {
  length  = 32
  special = false
}

resource "helm_release" "argocd" {
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
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-subnets" = join(",", data.terraform_remote_state.stage1_infra.outputs.vpc_public_subnets)
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
    name  = "image.tag"
    value = "latest"
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
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/subnets"     = join(",", data.terraform_remote_state.stage1_infra.outputs.vpc_public_subnets)
    }
  }
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
}

resource "kubernetes_manifest" "bluedragon_admin_clusterrole" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "bluedragon-admin"
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

resource "kubernetes_manifest" "bluedragon_admin_clusterrolebinding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "bluedragon-admin"
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
      name     = "bluedragon-admin"
      apiGroup = "rbac.authorization.k8s.io"
    }
  }
}

resource "kubernetes_manifest" "bluedragon_impersonator_clusterrole" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "bluedragon-impersonator"
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

resource "kubernetes_manifest" "bluedragon_impersonator_clusterrolebinding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "bluedragon-impersonator"
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
      name     = "bluedragon-impersonator"
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

output "bluedragon_admin_role" {
  value = {
    name = kubernetes_manifest.bluedragon_admin_clusterrole.manifest.metadata.name
  }
}

output "ingress_hostname" {
  value = try(kubernetes_ingress_v1.ecommerce_app.status[0].load_balancer[0].ingress[0].hostname, "pending")
}
