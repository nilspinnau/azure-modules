
output "servers" {
  value = {
    for server in local.servers : server.key => {
      id   = azurerm_mssql_server.default[server.key].id
      name = azurerm_mssql_server.default[server.key].name
    }
  }
}

output "databases" {
  value = {
    for database in var.databases : database.key => merge(database, {
      id   = azurerm_mssql_database.default[database.key].id
      name = azurerm_mssql_database.default[database.key].name
    })
  }
}