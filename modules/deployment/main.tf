variable "name" {
  type = string
}
variable "namespace" {
  type = string
}
variable "image" {
  type = string
}
variable "container_ports" {
  type    = set(number)
  default = []
}
variable "env" {
  type    = map
  default = {}
}

resource "kubernetes_deployment" "deployment" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = { app = var.name }
      }

      spec {
        container {
          image = var.image
          name  = var.name

          dynamic "env" {
            for_each = var.env
            content {
              name  = env.key
              value = env.value
            }
          }

          dynamic "port" {
            for_each = var.container_ports
            content {
              container_port = port.value
            }
          }
        }
      }
    }
  }
}

output "selector" {
  value = {
    app = kubernetes_deployment.deployment.metadata.0.name
  }
}
