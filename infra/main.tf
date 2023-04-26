locals {
  tags                         = { azd-env-name : var.environment_name, spring-cloud-azure : true }
  sha                          = base64encode(sha256("${var.environment_name}${var.location}${data.azurerm_client_config.current.subscription_id}"))
  resource_token               = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)
  psql_custom_username         = "CUSTOM_ROLE"
}
# ------------------------------------------------------------------------------------------------------
# Deploy resource Group
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "rg_name" {
  name          = var.environment_name
  resource_type = "azurerm_resource_group"
  random_length = 0
  clean_input   = true
}

resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location

  tags = local.tags
}
## ------------------------------------------------------------------------------------------------------
## Deploy PostgreSQL
## ------------------------------------------------------------------------------------------------------
module "postgresql" {
  source         = "./modules/postgresql"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = azurerm_resource_group.rg.tags
  resource_token = local.resource_token
  client_id      = var.client_id
}
## ------------------------------------------------------------------------------------------------------
## Passwordless setting
## ------------------------------------------------------------------------------------------------------
module "psql-passwordless" {
  source         = "./modules/passwordless"

  pg_custom_role_name_with_aad_identity     =   local.psql_custom_username
  pg_aad_admin_user                         =   module.postgresql.AZURE_POSTGRESQL_ADMIN_USERNAME
  pg_database_name                          =   module.postgresql.AZURE_POSTGRESQL_DATABASE_NAME
  pg_server_fqdn                            =   module.postgresql.AZURE_POSTGRESQL_FQDN
  hosting_service_aad_identity              =   module.asa_api.IDENTITY_PRINCIPAL_ID
}
# ------------------------------------------------------------------------------------------------------
# Deploy Azure Spring Apps
# ------------------------------------------------------------------------------------------------------
module "asa_api" {
  name           = "asa-${local.resource_token}"
  source         = "./modules/springapps"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name

  tags               = merge(local.tags, { azd-service-name : "simple-todo-web" })
}
