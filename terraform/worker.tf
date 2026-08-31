resource "kubernetes_stateful_set" "worker" {
  metadata {
    name      = "dify-worker"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      app                          = "dify-worker"
      "app.kubernetes.io/instance" = "dify-worker"
    }
  }

  spec {
    service_name = "dify-worker"
    replicas     = 1

    selector {
      match_labels = {
        app = "dify-worker"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-worker"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "dify-worker"
          image = "langgenius/dify-api:1.1.3"

          env {
            name  = "MODE"
            value = "worker"
          }
          env {
            name  = "LOG_LEVEL"
            value = "INFO"
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
            value = "http://dify-weaviate-svc:8080"
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
          env {
            name  = "PLUGIN_MAX_PACKAGE_SIZE"
            value = "52428800"
          }
          env {
            name  = "PLUGIN_DAEMON_URL"
            value = "http://dify-plugin-daemon:5002"
          }
          env {
            name  = "PLUGIN_DAEMON_KEY"
            value = random_password.plugin_daemon_key.result
          }
          env {
            name  = "INNER_API_KEY_FOR_PLUGIN"
            value = random_password.inner_api_key_for_plugin.result
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
            protocol       = "TCP"
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

resource "kubernetes_service" "worker" {
  metadata {
    name      = "dify-worker-svc"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    selector = {
      app = "dify-worker-svc"
    }

    port {
      protocol    = "TCP"
      port        = 5001
      target_port = 5001
    }

    type = "ClusterIP"
  }
} 