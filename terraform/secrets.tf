resource "kubernetes_secret" "dify_credentials" {
  metadata {
    name      = "dify-credentials"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  data = {
    "pg-username"   = var.PG_USERNAME
    "pg-host"       = "dify-postgres"
    "pg-port"       = "5432"
    "redis-host"    = "dify-redis"
    "redis-port"    = "6379"
    "weaviate-host" = "dify-weaviate"
    "weaviate-port" = "8080"
  }

  type = "Opaque"
}

# TLS material is not in the repository, and should not be. Point these at a
# certificate and key you already have, or leave them empty and terminate TLS
# somewhere else - cert-manager, or the ingress controller. Empty is the
# default so that terraform validate and plan work on a fresh clone.
resource "kubernetes_secret" "dify_tls" {
  count = var.tls_cert_path != "" && var.tls_key_path != "" ? 1 : 0

  metadata {
    name      = "dify-tls"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  data = {
    "tls.crt" = file(var.tls_cert_path)
    "tls.key" = file(var.tls_key_path)
  }

  type = "kubernetes.io/tls"
}     