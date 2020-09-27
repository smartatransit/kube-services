terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubernetes-alpha = {
      source = "hashicorp/kubernetes-alpha"
    }
    postgresql = {
      source = "terraform-providers/postgresql"
    }
  }
  required_version = ">= 0.13"
}
