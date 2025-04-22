resource "random_password" "postgres_password" {
  length           = 16
  special          = false
}

resource "kubernetes_service_account" "postgres" {
  metadata {
    name      = "dify-postgres"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-postgres"
    }
  }
}

resource "kubernetes_role" "postgres" {
  metadata {
    name      = "dify-postgres"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-postgres"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "postgres" {
  metadata {
    name      = "dify-postgres"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-postgres"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.postgres.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.postgres.metadata[0].name
    namespace = kubernetes_namespace.dify.metadata[0].name
  }
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "dify-postgres"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    service_name = "dify-postgres"
    replicas     = 1

    selector {
      match_labels = {
        app = "dify-postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-postgres"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.postgres.metadata[0].name
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "dify-postgres"
          image = "postgres:15-alpine"

          env {
            name  = "PGUSER"
            value = var.PG_USERNAME
          }

          env {
            name  = "POSTGRES_USER"
            value = var.PG_USERNAME
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = random_password.postgres_password.result
          }

          env {
            name  = "POSTGRES_DB"
            value = var.PG_DATABASE
          }

          port {
            container_port = 5432
            name          = "postgres-port"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", "$(PGUSER)", "-d", "$(POSTGRES_DB)"]
            }
            initial_delay_seconds = 5
            period_seconds       = 5
            timeout_seconds     = 2
            success_threshold   = 1
            failure_threshold   = 10
          }
        }

        volume {
          name = "postgres-data"
          host_path {
            path = "${var.storage_path}/db/postgres/data"
            type = "DirectoryOrCreate"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "dify-postgres"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    selector = {
      app = "dify-postgres"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }

    cluster_ip = "None"
    type       = "ClusterIP"
  }
} 