variable "services_domain" {
  type        = string
  description = "The domain under which to serve services on subdomains"
  default     = "services.smartatrasit.com"
}
variable "postgres_hostname" {
  type    = string
  default = "postgres.postgres.svc.cluster.local"
}
variable "postgres_admin_password" {
  type = string
}
variable "auth_middleware_name" {
  type        = string
  default     = "auth-gateway@file"
  description = "The name of the Traefik middleware that injects the api-gateway"
}
variable "marta_api_key" {
  type = string
}
variable "third_rail_twitter_client_id" {
  type = string
}
variable "third_rail_twitter_client_secret" {
  type = string
}

variable "healthcheck_config_path" {
  type = string
  default = "./config.yaml"
}
