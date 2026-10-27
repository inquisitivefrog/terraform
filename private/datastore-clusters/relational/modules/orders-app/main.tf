# The orders example app for one engine: a Deployment spread across zones, a
# Service, and a ServiceMonitor so the shared Prometheus scrapes its metrics
# (HTTP latency per endpoint, connection pools, retries).
#
# TLS to the database is verified against the cluster's CA. PostgreSQL's
# JDBC driver reads the PEM file directly; MySQL's needs a PKCS12 trust
# store, which an init container builds with keytool from the same image.
# The store holds only the public CA certificate, so its password is a
# fixed, non-secret value.

locals {
  labels = {
    "app.kubernetes.io/name"     = "orders"
    "app.kubernetes.io/instance" = var.name
  }
  truststore = "/truststore/ca.p12"
  # Not a secret: the store holds only the cluster's public CA certificate,
  # and "changeit" is the JDK's default truststore password.
  truststore_password = "changeit" # gitleaks:allow
}

resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = local.labels
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 10001
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "topology.kubernetes.io/zone"
          when_unsatisfiable = "DoNotSchedule"
          label_selector {
            match_labels = local.labels
          }
        }

        dynamic "init_container" {
          for_each = var.engine == "mysql" ? [1] : []
          content {
            name  = "truststore"
            image = var.image
            # Replace the CA every time: the emptyDir outlives a node restart,
            # init containers run again, and keytool refuses an alias that is
            # already there (CrashLoopBackOff, 2026-10-27). Replace, not "skip
            # if present", so a rotated CA is picked up. The delete fails
            # harmlessly on a first start, when there is no store yet
            # (keytool prints its errors on stdout).
            command = ["sh", "-c", join(" ", [
              "keytool -delete -alias cluster-ca -keystore \"$1\" -storetype PKCS12 -storepass \"$2\" >/dev/null 2>&1;",
              "exec keytool -importcert -noprompt -alias cluster-ca -file /ca/ca.crt -keystore \"$1\" -storetype PKCS12 -storepass \"$2\"",
            ]), "truststore", local.truststore, local.truststore_password]
            volume_mount {
              name       = "ca"
              mount_path = "/ca"
              read_only  = true
            }
            volume_mount {
              name       = "truststore"
              mount_path = "/truststore"
            }
            resources {
              requests = { cpu = "100m", memory = "128Mi" }
              limits   = { memory = "256Mi" }
            }
            security_context {
              allow_privilege_escalation = false
              read_only_root_filesystem  = true
              capabilities {
                drop = ["ALL"]
              }
            }
          }
        }

        container {
          name  = "orders"
          image = var.image

          env {
            name  = "ORDERS_ENGINE"
            value = var.engine
          }
          env {
            name  = "ORDERS_WRITER_HOST"
            value = var.writer_host
          }
          env {
            name  = "ORDERS_READER_HOST"
            value = var.reader_host
          }
          env {
            name  = "ORDERS_DATABASE"
            value = var.database
          }
          env {
            name  = "ORDERS_DB_USER"
            value = var.user
          }
          env {
            name = "ORDERS_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.password_secret.name
                key  = var.password_secret.key
              }
            }
          }
          env {
            name  = "ORDERS_CA_FILE"
            value = "/ca/ca.crt"
          }
          env {
            name  = "ORDERS_TRUSTSTORE"
            value = local.truststore
          }
          env {
            name  = "ORDERS_TRUSTSTORE_PASSWORD"
            value = local.truststore_password
          }

          port {
            name           = "http"
            container_port = 8080
          }

          # Ready means the app is up, not that the database is: if the
          # writer fails over, the pods stay in the Service and answer 503
          # (retry) rather than vanishing (connection refused).
          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = "http"
            }
            period_seconds = 5
          }
          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = "http"
            }
            period_seconds    = 10
            failure_threshold = 6
          }
          startup_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = "http"
            }
            period_seconds    = 2
            failure_threshold = 60
          }

          # Guaranteed memory; no CPU limit (it throttles even with CPU spare).
          resources {
            requests = { cpu = "100m", memory = var.memory }
            limits   = { memory = var.memory }
          }

          volume_mount {
            name       = "ca"
            mount_path = "/ca"
            read_only  = true
          }
          volume_mount {
            name       = "truststore"
            mount_path = "/truststore"
            read_only  = true
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        volume {
          name = "ca"
          secret {
            secret_name = var.ca_secret
            items {
              key  = "ca.crt"
              path = "ca.crt"
            }
          }
        }
        volume {
          name = "truststore"
          empty_dir {}
        }
        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "app" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    selector = local.labels
    port {
      name        = "http"
      port        = 8080
      target_port = "http"
    }
  }
}

resource "kubernetes_manifest" "service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      selector  = { matchLabels = local.labels }
      endpoints = [{ port = "http", path = "/actuator/prometheus", interval = "15s" }]
    }
  }
}
