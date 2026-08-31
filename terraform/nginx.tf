resource "kubernetes_config_map" "nginx" {
  metadata {
    name      = "dify-nginx"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  data = {
    "nginx.conf" = <<-EOT
    user  nginx;
    worker_processes  auto;

    error_log  /var/log/nginx/error.log notice;
    pid        /var/run/nginx.pid;

    events {
        worker_connections  1024;
    }

    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                         '$status $body_bytes_sent "$http_referer" '
                         '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        keepalive_timeout  65;
        client_max_body_size 15M;

        server {
            listen 80;
            server_name _;

            location /console/api {
                proxy_pass http://dify-api-svc:5001;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Port $server_port;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
                proxy_buffering off;
                proxy_read_timeout 3600s;
                proxy_send_timeout 3600s;
            }

            location /api {
                proxy_pass http://dify-api-svc:5001;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Port $server_port;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
                proxy_buffering off;
                proxy_read_timeout 3600s;
                proxy_send_timeout 3600s;
            }

            location /v1 {
                proxy_pass http://dify-api-svc:5001;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Port $server_port;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
                proxy_buffering off;
                proxy_read_timeout 3600s;
                proxy_send_timeout 3600s;
            }

            location /files {
                proxy_pass http://dify-api-svc:5001;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Port $server_port;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
                proxy_buffering off;
                proxy_read_timeout 3600s;
                proxy_send_timeout 3600s;
            }

            location /explore {
                proxy_pass http://dify-web-svc:3000;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Port $server_port;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
                proxy_buffering off;
                proxy_read_timeout 3600s;
                proxy_send_timeout 3600s;
            }

            location /e/ {
                proxy_pass http://dify-plugin-daemon-svc:5002;
                proxy_set_header Dify-Hook-Url ://;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Port $server_port;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
                proxy_buffering off;
                proxy_read_timeout 3600s;
                proxy_send_timeout 3600s;
            }

            location / {
                proxy_pass http://dify-web-svc:3000;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Port $server_port;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
                proxy_buffering off;
                proxy_read_timeout 3600s;
                proxy_send_timeout 3600s;
            }
        }
    }
    EOT
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "dify-nginx"
    namespace = kubernetes_namespace.dify.metadata[0].name
    labels = {
      app = "dify-nginx"
    }
  }

  spec {
    replicas               = 1
    revision_history_limit = 1

    selector {
      match_labels = {
        app = "dify-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "dify-nginx"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }
        automount_service_account_token = false

        container {
          name  = "dify-nginx"
          image = "nginx:stable"

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }

          port {
            container_port = 80
          }

          volume_mount {
            name       = "dify-nginx"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }

          volume_mount {
            name       = "dify-nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }
        }

        volume {
          name = "dify-nginx"
          config_map {
            name = kubernetes_config_map.nginx.metadata[0].name
          }
        }

        volume {
          name = "dify-nginx-config"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = "dify-nginx-svc"
    namespace = kubernetes_namespace.dify.metadata[0].name
  }

  spec {
    selector = {
      app = "dify-nginx"
    }

    port {
      name        = "dify-nginx"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}