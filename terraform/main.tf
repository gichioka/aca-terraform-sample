terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#==============================
# Resource Group
#==============================
resource "azurerm_resource_group" "rg" {
  name     = "aca-rg"
  location = "japaneast"
}

#==============================
# Azure Container Registry (ACR)
#==============================
resource "azurerm_container_registry" "acr" {
  name                = "myacaregistry1234"   # ※世界でユニークな名前に変更して！
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

#==============================
# Container Apps Environment
#==============================
resource "azurerm_container_app_environment" "env" {
  name                = "aca-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#==============================
# Container App (ACA)
#==============================
resource "azurerm_container_app" "app" {
  name                         = "myapp"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  # 👇 ACRパスワードをSecretとして登録
  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  # 👇 ACRの認証設定（password → password_secret_name に変更済）
  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  # 👇 コンテナ定義
  template {
    container {
      name   = "myapp"
      image  = "${azurerm_container_registry.acr.login_server}/myapp:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  # 👇 外部アクセスを有効化
  ingress {
    external_enabled = true
    target_port      = 8080

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

#==============================
# Output
#==============================
output "container_app_url" {
  value = azurerm_container_app.app.latest_revision_fqdn
}