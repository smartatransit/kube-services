locals {
  third_rail_build_num = 59
}

resource "kubernetes_namespace" "third_rail" {
  metadata {
    name = "third-rail"
  }
}

module "third_rail_db" {
  source = "./modules/db"
  name   = "third_rail"
}

module "third_rail_deployment" {
  source    = "./modules/deployment"
  name      = "third-rail"
  namespace = kubernetes_namespace.third_rail.metadata.0.name

  image           = "smartatransit/third_rail:build-${local.third_rail_build_num}"
  container_ports = [5000]

  env = {
    MARTA_API_KEY         = var.marta_api_key
    TWITTER_CLIENT_ID     = var.third_rail_twitter_client_id
    TWITTER_CLIENT_SECRET = var.third_rail_twitter_client_secret

    DB_HOST     = module.third_rail_db.host
    DB_PORT     = 5432
    DB_NAME     = module.third_rail_db.db
    DB_USERNAME = module.third_rail_db.username
    DB_PASSWORD = module.third_rail_db.password
  }
}

module "third_rail_service" {
  source               = "./modules/subdomain"
  subdomain            = "third-rail"
  namespace            = kubernetes_namespace.third_rail.metadata.0.name
  target_port          = 5000
  services_domain      = var.services_domain
  auth_middleware_name = var.auth_middleware_name

  selector = module.selector_deployment.selector
}

module "third_rail_insecure_service" {
  source          = "./modules/subdomain"
  subdomain       = "third-rail-insecure"
  namespace       = kubernetes_namespace.third_rail.metadata.0.name
  target_port     = 5000
  services_domain = var.services_domain

  selector = module.selector_deployment.selector
}
