resource "random_password" "inner_api_key_for_plugin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "plugin_daemon_key" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_deployment" "dify_plugin_daemon" {
  metadata {
    name      = "dify-plugin-daemon"
    namespace = "dify"
    labels = {
      app = "dify-plugin-daemon"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "dify-plugin-daemon"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-plugin-daemon"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.dify_plugin_daemon.metadata[0].name
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        automount_service_account_token = true

        volume {
          name = "dify-plugin-daemon-storage"
          host_path {
            path = "${var.storage_path}/app/plugin/storage"
            type = "DirectoryOrCreate"
          }
        }

        container {
          name  = "dify-plugin-daemon"
          image = "langgenius/dify-plugin-daemon:0.0.6-local"

          resources {
            limits = {
              memory = "1024Mi"
              cpu    = "2000m"
            }
            requests = {
              memory = "256Mi"
              cpu    = "500m"
            }
          }

          port {
            container_port = 5003
            protocol      = "TCP"
            name         = "debug-port"
          }

          port {
            container_port = 5002
            protocol      = "TCP"
            name         = "service-port"
          }

          env {
            name  = "DB_USERNAME"
            value = var.PG_USERNAME
          }

          env {
            name  = "DB_PASSWORD"
            value = random_password.postgres_password.result
          }

          env {
            name  = "DB_HOST"
            value = "dify-postgres"
          }

          env {
            name  = "DB_PORT"
            value = "5432"
          }

          env {
            name  = "REDIS_HOST"
            value = "dify-redis"
          }

          env {
            name  = "REDIS_PORT"
            value = "6379"
          }

          env {
            name  = "REDIS_USERNAME"
            value = var.REDIS_USERNAME
          }

          env {
            name  = "REDIS_PASSWORD"
            value = random_password.redis_password.result
          }

          env {
            name  = "REDIS_USE_SSL"
            value = "false"
          }

          env {
            name  = "REDIS_DB"
            value = "0"
          }

          env {
            name  = "CELERY_BROKER_URL"
            value = "redis://${var.REDIS_USERNAME}:${random_password.redis_password.result}@dify-redis:6379/1"
          }

          env {
            name  = "DB_DATABASE"
            value = var.PG_DATABASE
          }

          env {
            name  = "SERVER_PORT"
            value = "5002"
          }

          env {
            name  = "EXPOSE_PLUGIN_DAEMON_PORT"
            value = "5002"
          }

          env {
            name  = "SERVER_KEY"
            value = random_password.plugin_daemon_key.result
          }

          env {
            name  = "MAX_PLUGIN_PACKAGE_SIZE"
            value = "52428800"
          }

          env {
            name  = "PPROF_ENABLED"
            value = "false"
          }

          env {
            name  = "DIFY_INNER_API_URL"
            value = "http://dify-api-svc:5001"
          }

          env {
            name  = "DIFY_INNER_API_KEY"
            value = random_password.inner_api_key_for_plugin.result
          }

          env {
            name  = "PLUGIN_REMOTE_INSTALLING_HOST"
            value = "0.0.0.0"
          }

          env {
            name  = "PLUGIN_REMOTE_INSTALLING_PORT"
            value = "5003"
          }

          env {
            name  = "PLUGIN_WORKING_PATH"
            value = "/app/storage/cwd"
          }

          env {
            name  = "FORCE_VERIFYING_SIGNATURE"
            value = "true"
          }

          env {
            name  = "EXPOSE_PLUGIN_DEBUGGING_HOST"
            value = "localhost"
          }

          env {
            name  = "EXPOSE_PLUGIN_DEBUGGING_PORT"
            value = "5003"
          }

          env {
            name  = "PYTHON_ENV_INIT_TIMEOUT"
            value = "120"
          }

          env {
            name  = "PLUGIN_MAX_EXECUTION_TIMEOUT"
            value = "600"
          }

          volume_mount {
            name       = "dify-plugin-daemon-storage"
            mount_path = "/app/storage"
          }
        }
      }
    }
  }
} 

resource "kubernetes_service" "dify_plugin_daemon" {
  metadata {
    name      = "dify-plugin-daemon-svc"
    namespace = "dify"
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "dify-plugin-daemon"
    }

    port {
      port        = 5003
      target_port = 5003
      protocol    = "TCP"
      name        = "debug-port"
    }

    port {
      port        = 5002
      target_port = 5002
      protocol    = "TCP"
      name        = "service-port"
    }
  }
} 

resource "kubernetes_service_account" "dify_plugin_daemon" {
  metadata {
    name      = "dify-plugin-daemon"
    namespace = "dify"
    labels = {
      "app.kubernetes.io/instance" = "dify-plugin-daemon"
    }
  }
}

resource "kubernetes_role" "dify_plugin_daemon" {
  metadata {
    name      = "dify-plugin-daemon"
    namespace = "dify"
    labels = {
      "app.kubernetes.io/instance" = "dify-plugin-daemon"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "dify_plugin_daemon" {
  metadata {
    name      = "dify-plugin-daemon"
    namespace = "dify"
    labels = {
      "app.kubernetes.io/instance" = "dify-plugin-daemon"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.dify_plugin_daemon.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.dify_plugin_daemon.metadata[0].name
    namespace = "dify"
  }
}


