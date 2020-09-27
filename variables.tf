variable "services_domain" {
  type        = string
  description = "The domain under which to serve services on subdomains"
}
variable "postgres_admin_password" {
  type = string
}
variable "auth_middleware_name" {
  type        = string
  default     = "auth-gateway@file"
  description = "The name of the Traefik middleware that injects the api-gateway"
}
variable "postgres_internal_name" {
  type    = string
  default = "postgres.postgres.svc.cluster.local"
}
