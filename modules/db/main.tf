variable "name" {
  type = string
}
variable "extensions" {
  type    = set(string)
  default = []
}
variable "postgres_host" {
  type    = string
  default = "postgres.postgres.svc.cluster.local"
}

resource "random_password" "pw" {
  length = 64
}
resource "postgresql_role" "role" {
  name     = var.name
  login    = true
  password = random_password.pw.result
}
resource "postgresql_database" "db" {
  name  = var.name
  owner = postgresql_role.role.name
}
resource "postgresql_extension" "ext" {
  for_each = var.extensions
  name     = each.value
  database = postgresql_database.db.name
}

output "postgres_url" {
  value = "postgres://${postgresql_role.role.name}@${var.postgres_host}/${postgresql_database.db.name}?sslmode=disable"
}
output "postgres_password" {
  value = random_password.pw.result
}
