output "IDENTITY_PRINCIPAL_ID" {
  value     = length(azurerm_spring_cloud_app.asa_app.identity) == 0 ? "" : azurerm_spring_cloud_app.asa_app.identity.0.principal_id
  sensitive = true
}