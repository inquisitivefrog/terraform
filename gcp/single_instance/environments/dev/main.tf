# gcp/single_instance/environments/dev/main.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.4"
    }
  }
  backend "gcs" {} # see backend.hcl
}

provider "google" {
  project = var.project_id
  region  = var.region

  # Charge API quota to this project, not the ADC quota project (dairyfarm)
  billing_project       = var.project_id
  user_project_override = true
}

data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false # bucket names must be lowercase
}

# APIs this layer needs; left enabled on destroy (shared by dev and prod)
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "redis.googleapis.com",
    "run.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

locals {
  zone         = var.zones[0]
  gke_node_tag = "gke-node-${var.env}"
  # /29 for Memorystore near the top of the VPC range, clear of the subnets
  redis_cidr_block = cidrsubnet(var.vpc_cidr_block, 13, 8000)
}

module "vpc" {
  source              = "../../modules/vpc"
  env                 = var.env
  pods_cidr_block     = var.pods_cidr_block
  project_id          = var.project_id
  region              = var.region
  services_cidr_block = var.services_cidr_block
  vpc_cidr_block      = var.vpc_cidr_block

  depends_on = [google_project_service.apis]
}

module "networking" {
  source                    = "../../modules/networking"
  env                       = var.env
  gke_node_tag              = local.gke_node_tag
  my_laptop_cidr_block      = var.my_laptop_cidr_block
  network_id                = module.vpc.network_id
  project_id                = var.project_id
  redis_cidr_block          = local.redis_cidr_block
  redis_port                = module.cache.redis_port # 6378 with TLS on
  subnet_private_cidr_block = module.vpc.subnet_private_cidr_block
  subnet_public_cidr_block  = module.vpc.subnet_public_cidr_block
  vpc_cidr_block            = var.vpc_cidr_block
}

module "identity" {
  source                 = "../../modules/identity"
  cloud_run_service_name = module.compute.cloud_run_service_name
  dev_bucket_name        = module.storage.dev_bucket_name
  env                    = var.env
  key_ring_id            = module.kms.key_ring_id
  project_id             = var.project_id
  region                 = var.region
  vm_names               = [module.compute.public_vm_name, module.compute.private_vm_name]
  zone                   = local.zone

  depends_on = [google_project_service.apis]
}

module "kms" {
  source             = "../../modules/kms"
  admin_sa_email     = module.identity.admin_sa_email
  developer_sa_email = module.identity.developer_sa_email
  env                = var.env
  project_id         = var.project_id
  random_suffix      = random_string.suffix.result
  region             = var.region

  depends_on = [google_project_service.apis]
}

module "messages" {
  source            = "../../modules/messages"
  env               = var.env
  gcs_service_agent = module.kms.gcs_service_agent
  messages_key_id   = module.kms.messages_key_id
  project_id        = var.project_id
  region            = var.region
}

module "storage" {
  source           = "../../modules/storage"
  env              = var.env
  example_topic_id = module.messages.example_topic_id
  messages_key_id  = module.kms.messages_key_id
  project_id       = var.project_id
  random_suffix    = random_string.suffix.result
  region           = var.region
}

module "cache" {
  source           = "../../modules/cache"
  env              = var.env
  network_id       = module.vpc.network_id
  project_id       = var.project_id
  redis_cidr_block = local.redis_cidr_block
  region           = var.region
  zone             = local.zone
}

module "compute" {
  source            = "../../modules/compute"
  cloudrun_sa_email = module.identity.cloudrun_sa_email
  env               = var.env
  machine_type      = var.machine_type
  network_id        = module.vpc.network_id
  private_vm_tag    = module.networking.private_vm_tag
  project_id        = var.project_id
  public_vm_tag     = module.networking.public_vm_tag
  region            = var.region
  subnet_private_id = module.vpc.subnet_private_id
  subnet_public_id  = module.vpc.subnet_public_id
  vm_sa_email       = module.identity.vm_sa_email
  zone              = local.zone
}

module "gke" {
  source = "../../modules/gke"
  authorized_cidrs = [
    { cidr = var.my_laptop_cidr_block, name = "laptop" },
    { cidr = module.vpc.subnet_public_cidr_block, name = "public-subnet" }, # public VM via private endpoint
  ]
  env               = var.env
  kms_key_id        = module.kms.gke_key_id
  machine_type      = var.gke_machine_type
  network_id        = module.vpc.network_id
  node_count        = var.gke_node_count
  node_max_count    = var.gke_node_max_count
  node_sa_email     = module.identity.gke_node_sa_email
  node_tag          = local.gke_node_tag
  project_id        = var.project_id
  random_suffix     = random_string.suffix.result
  subnet_private_id = module.vpc.subnet_private_id
  zone              = local.zone
}

module "kubernetes" {
  source         = "../../modules/kubernetes"
  enable_ingress = var.enable_ingress
  env            = var.env
  namespaces     = ["app1", "app2"]
  cluster_admin_users = {
    vm = module.identity.vm_sa_email
  }
  rbac_roles = [
    {
      name       = "sre"
      user       = module.identity.operator_sa_emails["sre"]
      namespace  = "app1"
      api_groups = [""]
      resources  = ["pods", "services"]
      verbs      = ["get", "list", "create", "delete"]
    },
    {
      name       = "dba"
      user       = module.identity.operator_sa_emails["dba"]
      namespace  = "app2"
      api_groups = [""]
      resources  = ["pods", "services"]
      verbs      = ["get", "list", "create", "delete"]
    }
  ]

  depends_on = [module.gke] # wait for the node pool, not just the endpoint
}
