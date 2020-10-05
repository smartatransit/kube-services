locals {
  feedback_build_num = "22"
}

# Most resources in Kubernetes exist within a "namespace" -
# it'll make the most sense for us to have one namespace
# per microservice
resource "kubernetes_namespace" "feedback" {
  metadata {
    name = "feedback"
  }
}

# This module creates a postgres database and installs the pgcrypto
# extension so that we can use the UUID type in postgres. It also
# creates an owner user with the same name as the database. Its outputs
# are a connection URI and a password for the new user.
module "feedback_db" {
  source = "./modules/db"
  name   = "feedback"

  extensions = ["pgcrypto"]
}

# Where a docker service manages creating a set of identical containers and routing
# traffic to them, Kubernetes manages these with two separate entities. 

# The Kubernetes "deployment" is a collection of identical containers. For this
# module, we just specify the namespace, image, environement, and any ports that
# we might want to route traffic to on the container.
# NOTE: If you need to mount a volume, we'll have to modify the module a bit, but
# we can figure that out.
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

# This module creates a Kubernetes "service" and "ingress" resource. The service
# can receive traffic and forward it to the deployment's containers. The ingress
# resource then creates the necessary records for Traefik to route requests to it.
#
# Anywhere within the cluster, we can address any service using the hostname:
#   <svcname>.<namespace>.svc.cluster.local
# All pods are connected to a shared DNS resolver that allows them to address eachother.
module "feedback_service" {
  source               = "./modules/subdomain"
  subdomain            = "feedback"
  namespace            = kubernetes_namespace.feedback.metadata.0.name
  target_port          = 8080
  services_domain      = var.services_domain
  auth_middleware_name = var.auth_middleware_name

  selector = module.feedback_deployment.selector
}
