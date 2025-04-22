resource "kubernetes_config_map" "nginx_cors" {
  metadata {
    name      = "nginx-cors-config"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  data = {
    "enable-cors"            = "true"
    "cors-allow-methods"     = "GET, OPTIONS, PUT, POST, DELETE, PATCH"
    "cors-allow-headers"     = "Content-Type, authorization"
    "cors-allow-credentials" = "true"
    "cors-allow-origin" = join(",", [
      "https://consoleapi.${var.domain}",
      "https://dify.${var.domain}",
      "https://difyapi.${var.domain}",
      "https://difyapp.${var.domain}",
      "https://appapi.${var.domain}"
    ])
    "cors-max-age" = "100"
  }
} 