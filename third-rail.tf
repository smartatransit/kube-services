locals {
  third_rail_build_num   = 132
  scrapedumper_build_num = 312
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

    DB_CONNECTION_STRING = module.third_rail_db.url
    PGPASSWORD           = module.third_rail_db.password
  }
}

module "third_rail_insecure_deployment" {
  source    = "./modules/deployment"
  name      = "third-rail-insecure"
  namespace = kubernetes_namespace.third_rail.metadata.0.name

  image           = "smartatransit/third_rail:build-${local.third_rail_build_num}"
  container_ports = [5000]

  env = {
    SERVICE_DOMAIN        = "third-rail-insecure.${var.services_domain}"
    MARTA_API_KEY         = var.marta_api_key
    TWITTER_CLIENT_ID     = var.third_rail_twitter_client_id
    TWITTER_CLIENT_SECRET = var.third_rail_twitter_client_secret

    DB_CONNECTION_STRING = module.third_rail_db.url
    PGPASSWORD           = module.third_rail_db.password
  }
}

module "third_rail_service" {
  source               = "./modules/subdomain"
  subdomain            = "third-rail"
  namespace            = kubernetes_namespace.third_rail.metadata.0.name
  target_port          = 5000
  services_domain      = var.services_domain
  auth_middleware_name = var.auth_middleware_name

  selector = module.third_rail_deployment.selector
}

module "third_rail_insecure_service" {
  source          = "./modules/subdomain"
  subdomain       = "third-rail-insecure"
  namespace       = kubernetes_namespace.third_rail.metadata.0.name
  target_port     = 5000
  services_domain = var.services_domain

  selector = module.third_rail_insecure_deployment.selector
}


resource "kubernetes_secret" "third-rail-pgpassword" {
  metadata {
    name      = "pgpassword"
    namespace = "third-rail"
  }

  data = {
    password = module.third_rail_db.password
  }

  type = "kubernetes.io/basic-auth"
}

### Deploy the MARTA API daemon
module "scrapedumper_deployment" {
  source    = "./modules/deployment"
  name      = "third-rail-scrapedumper"
  namespace = kubernetes_namespace.third_rail.metadata.0.name

  image = "smartatransit/scrapedumper:build-${local.scrapedumper_build_num}"
  files = {
    "yamlconfig" = {
      target   = "/config.yaml"
      template = "scrapedumper.yaml"
      vars = {
        pg_connection_string = module.third_rail_db.url
      }
    }
  }

  env = {
    POLL_TIME_IN_SECONDS = "15"
    CONFIG_PATH          = "/config.yaml"
    PGPASSWORD           = module.third_rail_db.password
    MARTA_API_KEY        = var.marta_api_key
  }
}

module "scrapereaper_cronjob" {
  source    = "./modules/cron"
  name      = "third-rail-scrapereaper"
  namespace = kubernetes_namespace.third_rail.metadata.0.name

  image = "smartatransit/scrapereaper:build-${local.scrapedumper_build_num}"

  # 8AM UTC is 3AM eastern
  schedule = "0 8 * * *"

  env = {
    POSTGRES_CONNECTION_STRING = module.third_rail_db.url
    PGPASSWORD                 = module.third_rail_db.password
  }
}
