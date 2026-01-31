terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaksproj"
    container_name       = "tfstate"
    key                  = "aks-cicd.tfstate"
  }
}
