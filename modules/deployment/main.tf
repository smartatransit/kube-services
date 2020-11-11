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
variable "files" {
  type = map(object({
    target   = string
    template = string
    vars     = map(string)
  }))
  default = {}
}

resource "kubernetes_config_map" "files" {
  for_each = var.files

  metadata {
    name      = "files-${var.name}-${each.key}"
    namespace = var.namespace
  }

  data = {
    "file" = templatefile("templates/${each.value.template}", each.value.vars)
  }
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

          dynamic "volume_mount" {
            for_each = var.files
            content {
              name       = volume_mount.key
              mount_path = volume_mount.value.target
              sub_path   = basename(volume_mount.value.target)
            }
          }
        }

        dynamic "volume" {
          for_each = var.files
          content {
            name = volume.key
            config_map {
              name = kubernetes_config_map.files[volume.key].metadata.0.name
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
