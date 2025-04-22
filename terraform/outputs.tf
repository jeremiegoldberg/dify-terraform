output "web_url" {
  description = "URL for Dify web interface"
  value       = "https://dify.${var.domain}"
}

output "api_url" {
  description = "URL for Dify API"
  value       = "https://difyapi.${var.domain}"
}

output "console_api_url" {
  description = "URL for Dify console API"
  value       = "https://consoleapi.${var.domain}"
}

output "app_url" {
  description = "URL for Dify app"
  value       = "https://difyapp.${var.domain}"
}

output "app_api_url" {
  description = "URL for Dify app API"
  value       = "https://appapi.${var.domain}"
} 