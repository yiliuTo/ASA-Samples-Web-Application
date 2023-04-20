output "AZURE_POSTGRESQL_ENDPOINT" {
  value     = module.postgresql.AZURE_POSTGRESQL_FQDN
  sensitive = true
}

output "AZURE_LOCATION" {
  value = var.location
}