resource "random_password" "redis_password" {
  length  = 16
  special = false
}




resource "kubernetes_service_account" "redis" {
  metadata {
    name      = "dify-redis"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-redis"
    }
  }
}

resource "kubernetes_role" "redis" {
  metadata {
    name      = "dify-redis"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-redis"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "redis" {
  metadata {
    name      = "dify-redis"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-redis"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.redis.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.redis.metadata[0].name
    namespace = kubernetes_namespace.dify.metadata[0].name
  }
}

resource "kubernetes_stateful_set" "redis" {
  metadata {
    name      = "dify-redis"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    service_name = "dify-redis"
    replicas     = 1

    selector {
      match_labels = {
        app = "dify-redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-redis"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.redis.metadata[0].name
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "dify-redis"
          image = "redis:6-alpine"

          command = [
            "redis-server",
            "--save", "20", "1",
            "--loglevel", "warning",
            "--requirepass", random_password.redis_password.result
          ]

          port {
            container_port = 6379
            name           = "redis-p"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "1024Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "102Mi"
            }
          }

          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }

          liveness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
          }
        }

        volume {
          name = "redis-data"
          host_path {
            path = "/root/dify/db/redis/data"
            type = "DirectoryOrCreate"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "dify-redis"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    selector = {
      app = "dify-redis"
    }

    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
      protocol    = "TCP"
    }

    cluster_ip = "None"
    type       = "ClusterIP"
  }
} 