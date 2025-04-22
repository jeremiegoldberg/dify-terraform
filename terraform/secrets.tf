resource "kubernetes_secret" "dify_credentials" {
  metadata {
    name      = "dify-credentials"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  data = {
    "pg-username"    = var.PG_USERNAME
    "pg-host"        = "dify-postgres"
    "pg-port"        = "5432"
    "redis-host"     = "dify-redis"
    "redis-port"     = "6379"
    "weaviate-host"  = "dify-weaviate"
    "weaviate-port"  = "8080"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "dify_tls" {
  metadata {
    name      = "dify-tls"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  data = {
    "tls.crt" = file("certs/dify.crt")
    "tls.key" = file("certs/dify.key")
  }

  type = "kubernetes.io/tls"
}     