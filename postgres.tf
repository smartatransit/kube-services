provider "postgresql" {
  host      = var.postgres_hostname
  username  = "admin"
  password  = var.postgres_admin_password
  sslmode   = "disable"
  superuser = false
}
