provider "kubernetes" {}
provider "kubernetes-alpha" {}

terraform {
  backend "kubernetes" {
    secret_suffix     = "kube-services"
    in_cluster_config = true
  }
}
