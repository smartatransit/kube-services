variable "subdomain" {
  type = string
}
variable "namespace" {
  type = string
}
variable "selector" {
  type = map(string)
}
variable "target_port" {
  type = number
}
variable "services_domain" {
  type = string
}
variable "auth_middleware_name" {
  type    = string
  default = ""
}

locals {
  api_gateway_labels = {
    "traefik.ingress.kubernetes.io/router.middlewares" = var.auth_middleware_name
  }
}
resource "kubernetes_service" "service" {
  metadata {
    name      = var.subdomain
    namespace = var.namespace
  }

  spec {
    selector         = var.selector
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = var.target_port
    }
  }
}
resource "kubernetes_ingress" "ingress" {
  metadata {
    name      = var.subdomain
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"

      "traefik.ingress.kubernetes.io/router.entrypoints"        = "web-secure"
      "traefik.ingress.kubernetes.io/router.tls.certresolver"   = "main"
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "${var.subdomain}.${var.services_domain}"
      # TODO 
      # "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "dashboard.${san}"

      "traefik.ingress.kubernetes.io/router.middlewares" = var.auth_middleware_name
    }
  }

  spec {
    rule {
      host = "${var.subdomain}.${var.services_domain}"
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.service.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
}
