resource "routeros_ip_dns_record" "dify" {
  name    = "dify.${var.domain}"
  address = "192.168.1.121"
  type    = "A"
}

resource "routeros_ip_dns_record" "dify_api" {
  name    = "difyapi.${var.domain}"
  address = "192.168.1.121"
  type    = "A"
}

resource "routeros_ip_dns_record" "dify_console_api" {
  name    = "consoleapi.${var.domain}"
  address = "192.168.1.121"
  type    = "A"
}

resource "routeros_ip_dns_record" "dify_app" {
  name    = "difyapp.${var.domain}"
  address = "192.168.1.121"
  type    = "A"
}

resource "routeros_ip_dns_record" "dify_app_api" {
  name    = "appapi.${var.domain}"
  address = "192.168.1.121"
  type    = "A"
}

