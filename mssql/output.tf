
output "servers" {
  value = {
    for k, server in local.servers : k => {
      id   = azurerm_mssql_server.default[k].id
      name = azurerm_mssql_server.default[k].name
    }
  }
}

output "databases" {
  value = {
    for k, database in var.databases : k => merge(database, {
      id   = azurerm_mssql_database.default[k].id
      name = azurerm_mssql_database.default[k].name
    })
  }
}