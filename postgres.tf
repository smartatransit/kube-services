provider "postgresql" {
  host      = var.postgres_internal_name
  username  = "admin"
  password  = var.postgres_admin_password
  sslmode   = "disable"
  superuser = false
}
