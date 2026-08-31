resource "routeros_ip_dns_record" "dify" {
  count = var.create_dns_records ? 1 : 0

  name    = "dify.${var.domain}"
  address = var.ingress_address
  type    = "A"
}

resource "routeros_ip_dns_record" "dify_api" {
  count = var.create_dns_records ? 1 : 0

  name    = "difyapi.${var.domain}"
  address = var.ingress_address
  type    = "A"
}

resource "routeros_ip_dns_record" "dify_console_api" {
  count = var.create_dns_records ? 1 : 0

  name    = "consoleapi.${var.domain}"
  address = var.ingress_address
  type    = "A"
}

resource "routeros_ip_dns_record" "dify_app" {
  count = var.create_dns_records ? 1 : 0

  name    = "difyapp.${var.domain}"
  address = var.ingress_address
  type    = "A"
}

resource "routeros_ip_dns_record" "dify_app_api" {
  count = var.create_dns_records ? 1 : 0

  name    = "appapi.${var.domain}"
  address = var.ingress_address
  type    = "A"
}

