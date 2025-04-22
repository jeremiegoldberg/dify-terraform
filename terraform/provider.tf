terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

provider "kubernetes" {
  config_path    = var.KUBECONFIG_MKS8
}

provider "routeros" {
  hosturl = var.MIKROTIK_HOST
  username = var.MIKROTIK_USER
  password = var.MIKROTIK_PASSWORD
  insecure = true     
}