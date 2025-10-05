terraform {
  required_version = ">= 1.9.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.109.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "7e18b982-9600-4203-966d-41ecbbe194e8"
}

resource "azurerm_resource_group" "rg" {
  name     = "aca-rg"
  location = "japaneast"
}

resource "azurerm_container_registry" "acr" {
  name                = "myacaregistry1234"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app_environment" "env" {
  name                = "myapp-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_container_app" "app" {
  name                         = "myapp"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  template {
    container {
      name   = "myapp"
      image  = "nginx:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
  }
  traffic_weight {
    latest_revision = true
    percentage      = 100
  }
  tags = {
    environment = "dev"
  }
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "container_app_name" {
  value = azurerm_container_app.app.name
}

output "container_app_rg" {
  value = azurerm_resource_group.rg.name
}

output "container_app_env_id" {
  value = azurerm_container_app_environment.env.id
}