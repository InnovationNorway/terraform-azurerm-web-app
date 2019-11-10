resource "random_id" "test" {
  byte_length = 4
}

resource "azurerm_resource_group" "test" {
  name     = format("test-%s", random_id.test.hex)
  location = "southindia"
}

module "web_app" {
  source = "../"

  name = format("test-%s", random_id.test.hex)

  resource_group_name = azurerm_resource_group.test.name

  runtime = {
    name    = "ASP.NET"
    version = "4.7"
  }

  plan = {
    sku_size = "D1"
  }
}

data "azurerm_app_service" "test" {
  name                = module.web_app.name
  resource_group_name = azurerm_resource_group.test.name
}

module "test_assertions" {
  source = "innovationnorway/assertions/test"
  equals = [
    {
      name = "has expected runtime"
      got  = data.azurerm_app_service.test.site_config.0.linux_fx_version
      want = "DOTNETCORE|2.2"
    }
  ]
}
