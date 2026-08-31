resource "kubernetes_config_map" "ssrf_proxy_config" {
  metadata {
    name      = "ssrf-proxy-config"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  data = {
    "squid.conf" = <<-EOT
    acl localnet src 0.0.0.1-0.255.255.255	# RFC 1122 "this" network (LAN)
    acl localnet src 10.0.0.0/8		# RFC 1918 local private network (LAN)
    acl localnet src 100.64.0.0/10		# RFC 6598 shared address space (CGN)
    acl localnet src 169.254.0.0/16 	# RFC 3927 link-local (directly plugged) machines
    acl localnet src 172.16.0.0/12		# RFC 1918 local private network (LAN)
    acl localnet src 192.168.0.0/16		# RFC 1918 local private network (LAN)
    acl localnet src fc00::/7       	# RFC 4193 local private network range
    acl localnet src fe80::/10      	# RFC 4291 link-local (directly plugged) machines
    acl SSL_ports port 443
    acl Safe_ports port 80		# http
    acl Safe_ports port 21		# ftp
    acl Safe_ports port 443		# https
    acl Safe_ports port 70		# gopher
    acl Safe_ports port 210		# wais
    acl Safe_ports port 1025-65535	# unregistered ports
    acl Safe_ports port 280		# http-mgmt
    acl Safe_ports port 488		# gss-http
    acl Safe_ports port 591		# filemaker
    acl Safe_ports port 777		# multiling http
    acl CONNECT method CONNECT
    http_access deny !Safe_ports
    http_access deny CONNECT !SSL_ports
    http_access allow localhost manager
    http_access deny manager
    http_access allow localhost
    http_access allow localnet
    http_access deny all

    ################################## Proxy Server ################################
    http_port 3128
    coredump_dir /var/spool/squid
    refresh_pattern ^ftp:		1440	20%	10080
    refresh_pattern ^gopher:	1440	0%	1440
    refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
    refresh_pattern \/(Packages|Sources)(|\.bz2|\.gz|\.xz)$ 0 0% 0 refresh-ims
    refresh_pattern \/Release(|\.gpg)$ 0 0% 0 refresh-ims
    refresh_pattern \/InRelease$ 0 0% 0 refresh-ims
    refresh_pattern \/(Translation-.*)(|\.bz2|\.gz|\.xz)$ 0 0% 0 refresh-ims
    refresh_pattern .		0	20%	4320

    ################################## Reverse Proxy To Sandbox ################################
    http_port 8194 accel vhost
    cache_peer dify-sandbox parent 8194 0 no-query originserver
    acl src_all src all
    http_access allow src_all
    EOT
  }
}

resource "kubernetes_config_map" "ssrf_proxy_entrypoint" {
  metadata {
    name      = "ssrf-proxy-entrypoint"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  data = {
    "docker-entrypoint-mount.sh" = <<-EOT
    #!/bin/bash
    echo "[ENTRYPOINT] re-create snakeoil self-signed certificate removed in the build process"
    if [ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]; then
        /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite > /dev/null 2>&1
    fi
    
    tail -F /var/log/squid/access.log 2>/dev/null &
    tail -F /var/log/squid/error.log 2>/dev/null &
    tail -F /var/log/squid/store.log 2>/dev/null &
    tail -F /var/log/squid/cache.log 2>/dev/null &
    
    echo "[ENTRYPOINT] replacing environment variables in the template"
    awk '{
        while(match($$0, /\\$${[A-Za-z_][A-Za-z_0-9]*}/)) {
            var = substr($$0, RSTART+2, RLENGTH-3)
            val = ENVIRON[var]
            $$0 = substr($$0, 1, RSTART-1) val substr($$0, RSTART+RLENGTH)
        }
        print
    }' /etc/squid/squid.conf.template > /etc/squid/squid.conf
    
    /usr/sbin/squid -Nz
    echo "[ENTRYPOINT] starting squid"
    /usr/sbin/squid -f /etc/squid/squid.conf -NYC 1
    EOT
  }
}

resource "kubernetes_deployment" "ssrf" {
  metadata {
    name      = "dify-ssrf"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      app = "dify-ssrf"
    }
  }

  spec {
    replicas = 1
    strategy {
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
      type = "RollingUpdate"
    }

    selector {
      match_labels = {
        app = "dify-ssrf"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-ssrf"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "dify-ssrf"
          image = "ubuntu/squid:latest"

          env {
            name  = "HTTP_PORT"
            value = "3128"
          }
          env {
            name  = "COREDUMP_DIR"
            value = "/var/spool/squid"
          }
          env {
            name  = "REVERSE_PROXY_PORT"
            value = "8194"
          }
          env {
            name  = "SANDBOX_HOST"
            value = "dify-sandbox"
          }
          env {
            name  = "SANDBOX_PORT"
            value = "8194"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
            limits = {
              cpu    = "300m"
              memory = "300Mi"
            }
          }

          port {
            container_port = 3128
            name           = "dify-ssrf"
          }

          volume_mount {
            name       = "ssrf-proxy-config"
            mount_path = "/etc/squid/"
          }
          volume_mount {
            name       = "ssrf-proxy-entrypoint"
            mount_path = "/tmp/"
          }

          command = [
            "sh",
            "-c",
            "cp /tmp/docker-entrypoint-mount.sh /docker-entrypoint.sh && sed -i 's/\\r$$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh && /docker-entrypoint.sh"
          ]
        }

        volume {
          name = "ssrf-proxy-config"
          config_map {
            name = kubernetes_config_map.ssrf_proxy_config.metadata[0].name
          }
        }
        volume {
          name = "ssrf-proxy-entrypoint"
          config_map {
            name = kubernetes_config_map.ssrf_proxy_entrypoint.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "ssrf" {
  metadata {
    name      = "dify-ssrf-svc"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    selector = {
      app = "dify-ssrf"
    }

    port {
      protocol    = "TCP"
      port        = 3128
      target_port = 3128
    }
  }
} 