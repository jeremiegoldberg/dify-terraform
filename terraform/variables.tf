variable "CI_REGISTRY" {
  type        = string
  description = "My personal Docker hub registry"
}

variable "KUBECONFIG_MKS8" {
  type        = string
  description = "Path to kubeconfig file"
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

# Mikrotik Configuration
variable "MIKROTIK_HOST" {
  type        = string
  description = "Mikrotik router host URL"
  sensitive   = true
}

variable "MIKROTIK_USER" {
  type        = string
  description = "Mikrotik router username"
  sensitive   = true
}

variable "MIKROTIK_PASSWORD" {
  type        = string
  description = "Mikrotik router password"
  sensitive   = true
} 