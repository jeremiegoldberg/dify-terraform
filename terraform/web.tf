resource "kubernetes_deployment" "web" {
  metadata {
    name      = "dify-web"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      app = "dify-web"
    }
  }

  spec {
    replicas = 1
    revision_history_limit = 1

    selector {
      match_labels = {
        app = "dify-web"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-web"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }
        automount_service_account_token = false

        container {
          name  = "dify-web"
          image = "langgenius/dify-web:1.1.3"

          env {
            name  = "EDITION"
            value = "SELF_HOSTED"
          }
          env {
            name  = "CONSOLE_API_URL"
            value = "https://consoleapi.${var.domain}"
          }
          env {
            name  = "APP_API_URL"
            value = "https://appapi.${var.domain}"
          }
          env {
            name  = "SENTRY_DSN"
            value = ""
          }
          env {
            name  = "NEXT_TELEMETRY_DISABLED"
            value = "0"
          }
          env {
            name  = "TEXT_GENERATION_TIMEOUT_MS"
            value = "60000"
          }
          env {
            name  = "CSP_WHITELIST"
            value = ""
          }
          env {
            name  = "MARKETPLACE_API_URL"
            value = "https://marketplace.dify.ai"
          }
          env {
            name  = "MARKETPLACE_URL"
            value = "https://marketplace.dify.ai"
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

          port {
            container_port = 3000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "web" {
  metadata {
    name      = "dify-web-svc"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    selector = {
      app = "dify-web"
    }

    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
      name        = "dify-web"
    }

    type = "ClusterIP"
  }
} 