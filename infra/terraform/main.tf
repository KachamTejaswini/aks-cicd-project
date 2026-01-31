resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-${var.environment}"
  location = var.location
}


resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aks-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-aks-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_container_registry" "acr" {
  name                = "acraks${var.environment}123"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
}


resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-${var.environment}"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name           = "system"
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  network_profile {
    network_plugin = "azure"

    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  role_based_access_control_enabled = true
}



resource "azurerm_role_assignment" "aks_acr" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}


resource "azurerm_key_vault" "kv" {
  name                = "kv-aks-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  purge_protection_enabled = true
}
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}



data "azurerm_client_config" "current" {}
