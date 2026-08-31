variable "registry" {
  type        = string
  description = "Container registry the Dify images are pulled from, without a trailing slash. Leave empty for Docker Hub."
  default     = ""
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file used to reach the cluster."
  default     = "~/.kube/config"
}

variable "namespace" {
  type        = string
  description = "Namespace everything is created in."
  default     = "dify"
}

variable "domain" {
  description = "Base domain for Dify services"
  type        = string
  default     = "dify.lan"
}

variable "image_tag" {
  description = "Tag for Dify images"
  type        = string
  default     = "1.1.3"
}

variable "storage_path" {
  description = "Base path for persistent storage"
  type        = string
  default     = "/root/dify"
}

# Database credentials
variable "PG_USERNAME" {
  type        = string
  description = "PostgreSQL username"
}

variable "PG_DATABASE" {
  type        = string
  description = "PostgreSQL database name"
  default     = "dify"
}

# Redis credentials
variable "REDIS_USERNAME" {
  type        = string
  description = "Redis username"
  default     = ""
}

# Optional DNS records on a Mikrotik router. This is how the author resolves
# the Dify hostnames on a home network; it is off by default because most
# people have DNS somewhere else entirely. Everything else applies without it.
variable "create_dns_records" {
  type        = bool
  description = "Create A records for the Dify hostnames on a Mikrotik router."
  default     = false
}

variable "ingress_address" {
  type        = string
  description = "Address the DNS records point at, usually the ingress controller's. Only used when create_dns_records is true."
  default     = ""
}

variable "MIKROTIK_HOST" {
  type        = string
  description = "Mikrotik router host URL. Only used when create_dns_records is true."
  default     = ""
  sensitive   = true
}

variable "MIKROTIK_USER" {
  type        = string
  description = "Mikrotik router username. Only used when create_dns_records is true."
  default     = ""
  sensitive   = true
}

variable "MIKROTIK_PASSWORD" {
  type        = string
  description = "Mikrotik router password. Only used when create_dns_records is true."
  default     = ""
  sensitive   = true
}
variable "tls_cert_path" {
  type        = string
  description = "Path to a TLS certificate for the ingress hosts. Empty leaves the secret uncreated."
  default     = ""
}

variable "tls_key_path" {
  type        = string
  description = "Path to the matching private key. Empty leaves the secret uncreated."
  default     = ""
}
