locals {
  feedback_build_num = "22"
}

resource "kubernetes_namespace" "feedback" {
  metadata {
    name = "feedback"
  }
}

module "feedback_db" {
  source = "./modules/db"
  name   = "feedback"

  // for the UUID type
  extensions = ["pgcrypto"]
}

module "feedback_deployment" {
  source    = "./modules/deployment"
  name      = "feedback"
  namespace = kubernetes_namespace.feedback.metadata.0.name

  image           = "smartatransit/feedback:build-${local.feedback_build_num}"
  container_ports = [8080]

  env = {
    POSTGRES_URL = module.feedback_db.postgres_url
    PGPASSWORD   = module.feedback_db.postgres_password
  }
}

module "feedback_service" {
  source               = "./modules/subdomain"
  subdomain            = "feedback"
  namespace            = kubernetes_namespace.feedback.metadata.0.name
  target_port          = 8080
  services_domain      = var.services_domain
  auth_middleware_name = var.auth_middleware_name

  selector = module.feedback_deployment.selector
}
