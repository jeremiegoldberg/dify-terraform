resource "kubernetes_deployment" "sandbox" {
  metadata {
    name      = "dify-sandbox"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      app = "dify-sandbox"
    }
  }

  spec {
    replicas               = 1
    revision_history_limit = 1

    selector {
      match_labels = {
        app = "dify-sandbox"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-sandbox"
        }
      }

      spec {
        automount_service_account_token = false
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "dify-sandbox"
          image = "langgenius/dify-sandbox:0.2.11"

          env {
            name  = "API_KEY"
            value = "dify-sandbox"
          }
          env {
            name  = "GIN_MODE"
            value = "release"
          }
          env {
            name  = "WORKER_TIMEOUT"
            value = "15"
          }
          env {
            name  = "ENABLE_NETWORK"
            value = "true"
          }
          env {
            name  = "SANDBOX_PORT"
            value = "8194"
          }
          env {
            name  = "HTTP_PROXY"
            value = "http://dify-ssrf-svc:3128"
          }
          env {
            name  = "HTTPS_PROXY"
            value = "http://dify-ssrf-svc:3128"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            exec {
              command = ["curl", "-f", "http://localhost:8194/health"]
            }
          }

          port {
            container_port = 8194
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "sandbox" {
  metadata {
    name      = "dify-sandbox-svc"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    selector = {
      app = "dify-sandbox"
    }

    port {
      port        = 8194
      target_port = 8194
      protocol    = "TCP"
      name        = "dify-sandbox"
    }

    type       = "ClusterIP"
    cluster_ip = "None"
  }
} 