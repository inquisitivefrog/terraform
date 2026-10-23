data "aws_eks_cluster" "this" {
  name = "ecommerce-cluster"
}

data "terraform_remote_state" "stage1_infra" {
  backend = "s3"
  config = {
    bucket  = "blue-elephant-ecommerce-terraform-state"
    key     = "ecommerce-k8s/stage1-infra/terraform.tfstate" # matches stage1-infra/backend.hcl
    region  = "us-east-2"
    profile = "blue-elephant"
  }
}

# No aws-auth: the cluster uses access entries only (stage1,
# authentication_mode = "API"). Every principal's access is visible and
# revocable through the EKS API.

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "3.6.1" # controller v3.6.1; chart and controller versions match from v3 on
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

resource "helm_release" "argocd" {
  # Its server Service is a LoadBalancer: remove it while the controller runs.
  depends_on       = [helm_release.aws_load_balancer_controller]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "10.11.1" # Argo CD v3.5.6
  create_namespace = true
  timeout          = 1200
  wait             = true

  # Argo CD generates its own server key and initial admin password
  # (Secret argocd-initial-admin-secret; argocd_use.sh prints it), so neither
  # passes through Terraform state.
  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = true # plain HTTP behind the NLB, which only admits the laptop
        }
      }
      dex = {
        enabled = false # no SSO; the built-in admin user is enough here
      }
      notifications = {
        enabled = false
      }
      server = {
        service = {
          type                     = "LoadBalancer"
          loadBalancerSourceRanges = [var.my_laptop_cidr_block]
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-subnets" = join(",", data.terraform_remote_state.stage1_infra.outputs.vpc_public_subnets)
            # The controller turns this Service into an NLB, internal unless told otherwise
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
        resources = {
          limits   = { cpu = "250m", memory = "256Mi" }
          requests = { cpu = "50m", memory = "128Mi" }
        }
      }
      controller = {
        resources = {
          limits   = { cpu = "500m", memory = "512Mi" }
          requests = { cpu = "100m", memory = "256Mi" }
        }
      }
      repoServer = {
        resources = {
          limits   = { cpu = "500m", memory = "512Mi" }
          requests = { cpu = "50m", memory = "128Mi" }
        }
      }
      applicationSet = {
        resources = {
          limits   = { cpu = "100m", memory = "128Mi" }
          requests = { cpu = "10m", memory = "64Mi" }
        }
      }
      redis = {
        resources = {
          limits   = { cpu = "250m", memory = "128Mi" }
          requests = { cpu = "50m", memory = "64Mi" }
        }
      }
    })
  ]
}

# Argo CD deploys the app (GitOps): it renders charts/ecommerce-app from
# git and keeps the cluster in sync with it, so a pushed chart change rolls
# out with no Terraform run. Terraform only creates the Application, through
# the argocd-apps chart: a kubernetes_manifest would need the Application
# CRD at plan time, before the Argo CD release above has installed it.
resource "helm_release" "argocd_apps" {
  depends_on = [helm_release.argocd]
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.7"
  namespace  = "argocd"
  wait       = true

  values = [
    yamlencode({
      applications = {
        ecommerce-app = {
          namespace = "argocd"
          project   = "default"
          # Destroy deletes the app's resources before the Application goes
          finalizers = ["resources-finalizer.argocd.argoproj.io"]
          source = {
            repoURL        = var.app_repo_url
            targetRevision = var.app_target_revision
            path           = "aws/ecommerce-k8s/charts/ecommerce-app"
            helm = {
              releaseName = "ecommerce-app" # Service ecommerce-app-service, which the Ingress targets
            }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "default"
          }
          syncPolicy = {
            automated = {
              prune    = true # remove what was deleted from git
              selfHeal = true # undo changes made by hand
            }
          }
        }
      }
    })
  ]
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
  depends_on = [helm_release.aws_load_balancer_controller, helm_release.argocd_apps]
}

# No custom ClusterRoles. Humans and the terraform-admin role get cluster
# admin from EKS access policies (stage1). The previous roles duplicated that
# and added risk: blue-elephant-impersonator let the load-balancer
# controller's service account impersonate any user (system:masters
# included), and terraform-admin and blue-elephant-admin could create new
# ClusterRoleBindings. The controller's own chart grants what it needs.
