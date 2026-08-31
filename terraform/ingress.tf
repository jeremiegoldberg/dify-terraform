# Ingress with NGINX ingress controller
resource "kubernetes_ingress_v1" "dify" {
  metadata {
    name      = "dify-ingress"
    namespace = kubernetes_namespace.dify.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "15m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "3600"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "3600"

      # CORS configuration
      "nginx.ingress.kubernetes.io/enable-cors"            = "true"
      "nginx.ingress.kubernetes.io/cors-allow-credentials" = "true"
      "nginx.ingress.kubernetes.io/cors-allow-methods"     = "*"
      "nginx.ingress.kubernetes.io/cors-allow-headers"     = "*"
      "nginx.ingress.kubernetes.io/cors-allow-origin"      = "https://consoleapi.${var.domain},https://dify.${var.domain},https://difyapi.${var.domain},https://difyapp.${var.domain},https://appapi.${var.domain}"
      "nginx.ingress.kubernetes.io/cors-max-age"           = "100"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {

      host = "dify.${var.domain}"
      http {
        path {
          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # Direct service access ingress rules
    rule {

      host = "difyapi.${var.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {

      host = "consoleapi.${var.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {

      host = "difyapp.${var.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {

      host = "appapi.${var.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # Declared only when the secret exists. An ingress pointing at a missing
    # TLS secret serves the controller's default certificate and says nothing
    # about why.
    dynamic "tls" {
      for_each = kubernetes_secret.dify_tls

      content {
        secret_name = tls.value.metadata[0].name
        hosts = [
          "dify.${var.domain}",
          "difyapi.${var.domain}",
          "consoleapi.${var.domain}",
          "difyapp.${var.domain}",
          "appapi.${var.domain}"
        ]
      }
    }
  }
} 