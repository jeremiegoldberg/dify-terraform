
resource "random_password" "secret_key" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}



resource "kubernetes_stateful_set" "api" {
  metadata {
    name      = "dify-api"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-api"
      "app"                       = "dify-api"
    }
  }

  spec {
    service_name = "dify-api"
    replicas     = 1
    revision_history_limit = 1
    min_ready_seconds = 10

    selector {
      match_labels = {
        app = "dify-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-api"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "dify-api"
          image = "langgenius/dify-api:1.1.3"

          env {
            name  = "MODE"
            value = "api"
          }
          env {
            name  = "LOG_LEVEL"
            value = "DEBUG"
          }
          env {
            name  = "SECRET_KEY"
            value = random_password.secret_key.result
          }
          env {
            name  = "CONSOLE_WEB_URL"
            value = "https://dify.${var.domain}"
          }
          env {
            name  = "CONSOLE_API_URL"
            value = "https://consoleapi.${var.domain}"
          }
          env {
            name  = "SERVICE_API_URL"
            value = "https://difyapi.${var.domain}"
          }
          env {
            name  = "APP_WEB_URL"
            value = "https://difyapp.${var.domain}"
          }
          env {
            name  = "CODE_EXECUTION_ENDPOINT"
            value = "http://dify-sandbox-svc:8194"
          }
          env {
            name  = "PLUGIN_DAEMON_URL"
            value = "http://dify-plugin-daemon-svc:5002"
          }
          env {
            name  = "PLUGIN_DAEMON_KEY"
            value = random_password.plugin_daemon_key.result
          }
          env {
            name  = "INNER_API_KEY_FOR_PLUGIN"
            value = random_password.inner_api_key_for_plugin.result
          }
          env {
            name  = "MARKETPLACE_ENABLED"
            value = "true"
          }
          env {
            name  = "MARKETPLACE_API_URL"
            value = "https://marketplace.dify.ai"
          }
          env {
            name  = "PLUGIN_REMOTE_INSTALL_HOST"
            value = "dify-plugin-daemon-svc"
          }
          env {
            name  = "PLUGIN_REMOTE_INSTALL_PORT"
            value = "5003"
          }
          env {
            name  = "INIT_PASSWORD"
            value = "password"
          }
          env {
            name  = "MIGRATION_ENABLED"
            value = "true"
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
            name  = "DB_DATABASE"
            value = var.PG_DATABASE
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
            name  = "WEB_API_CORS_ALLOW_ORIGINS"
            value = "*"
          }
          env {
            name  = "CONSOLE_CORS_ALLOW_ORIGINS"
            value = "*"
          }
          env {
            name  = "STORAGE_TYPE"
            value = "opendal"
          }
          env {
            name  = "OPENDAL_SCHEME"
            value = "fs"
          }
          env {
            name  = "OPENDAL_FS_ROOT"
            value = "storage"
          }
          env {
            name  = "STORAGE_LOCAL_PATH"
            value = "/app/api/storage"
          }
          env {
            name  = "VECTOR_STORE"
            value = "weaviate"
          }
          env {
            name  = "WEAVIATE_HOST"
            value = "dify-weaviate"
          }
          env {
            name  = "WEAVIATE_PORT"
            value = "8080"
          }
          env {
            name  = "WEAVIATE_ENDPOINT"
            value = "http://dify-weaviate:8080"
          }
          env {
            name  = "WEAVIATE_API_KEY"
            value = random_password.weaviate_api_key.result
          }
          env {
            name  = "SSRF_PROXY_HTTP_URL"
            value = "http://dify-ssrf-svc:3128"
          }
          env {
            name  = "SSRF_PROXY_HTTPS_URL"
            value = "http://dify-ssrf-svc:3128"
          }

          resources {
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          port {
            container_port = 5001
          }

          volume_mount {
            name       = "dify-api-storage"
            mount_path = "/app/api/storage"
          }
        }

        volume {
          name = "dify-api-storage"
          host_path {
            path = "${var.storage_path}/app/api/storage"
            type = "DirectoryOrCreate"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api" {
  metadata {
    name      = "dify-api-svc"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    selector = {
      app = "dify-api"
    }

    port {
      port        = 5001
      target_port = 5001
      protocol    = "TCP"
      name        = "dify-api"
    }

    type = "ClusterIP"
  }
} 