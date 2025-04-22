resource "kubernetes_namespace" "dify" {
  metadata {
    name = "dify"
  }
} 