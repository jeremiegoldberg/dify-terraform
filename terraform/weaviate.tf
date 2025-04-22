resource "random_password" "weaviate_api_key" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "kubernetes_service_account" "weaviate" {
  metadata {
    name      = "dify-weaviate"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-weaviate"
    }
  }
}

resource "kubernetes_role" "weaviate" {
  metadata {
    name      = "dify-weaviate"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-weaviate"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "weaviate" {
  metadata {
    name      = "dify-weaviate"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      "app.kubernetes.io/instance" = "dify-weaviate"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.weaviate.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.weaviate.metadata[0].name
    namespace = kubernetes_namespace.dify.metadata[0].name
  }
}

resource "kubernetes_stateful_set" "weaviate" {
  metadata {
    name      = "dify-weaviate"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    service_name = "dify-weaviate"
    replicas     = 1

    selector {
      match_labels = {
        app = "dify-weaviate"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-weaviate"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.weaviate.metadata[0].name
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "dify-weaviate"
          image = "semitechnologies/weaviate:1.19.0"

          env {
            name  = "QUERY_DEFAULTS_LIMIT"
            value = "25"
          }
          env {
            name  = "AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED"
            value = "false"
          }
          env {
            name  = "PERSISTENCE_DATA_PATH"
            value = "/var/lib/weaviate"
          }
          env {
            name  = "DEFAULT_VECTORIZER_MODULE"
            value = "none"
          }
          env {
            name  = "AUTHENTICATION_APIKEY_ENABLED"
            value = "true"
          }
          env {
            name  = "AUTHENTICATION_APIKEY_ALLOWED_KEYS"
            value = random_password.weaviate_api_key.result
          }
          env {
            name  = "AUTHENTICATION_APIKEY_USERS"
            value = "hello@dify.ai"
          }
          env {
            name  = "AUTHORIZATION_ADMINLIST_ENABLED"
            value = "true"
          }
          env {
            name  = "AUTHORIZATION_ADMINLIST_USERS"
            value = "hello@dify.ai"
          }

          port {
            container_port = 8080
            name          = "weaviate-p"
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
            name       = "weaviate-data"
            mount_path = "/var/lib/weaviate"
          }
        }

        volume {
          name = "weaviate-data"
          host_path {
            path = "/root/dify/db/weaviate/data"
            type = "DirectoryOrCreate"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "weaviate" {
  metadata {
    name      = "dify-weaviate"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    selector = {
      app = "dify-weaviate-svc"
    }

    port {
      name        = "weaviate"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    cluster_ip = "None"
    type       = "ClusterIP"
  }
} 