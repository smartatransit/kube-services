locals {
  healthcheck_build_num = 15
}

resource "kubernetes_namespace" "healthcheck" {
  metadata {
    name = "healthcheck"
  }
}

module "healthcheck_deployment" {
  source    = "./modules/deployment"
  name      = "healthcheck"
  namespace = kubernetes_namespace.healthcheck.metadata.0.name

  image           = "smartatransit/healthcheck:build-${local.healthcheck_build_num}"
  container_ports = [5000]

  env = {
    CONFIG_PATH           = var.healthcheck_config_path
  }
}
