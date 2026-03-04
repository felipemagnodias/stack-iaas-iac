terraform {
  backend "azurerm" {
    resource_group_name  = "RG-EASTU-NETWORK"
    storage_account_name = "storagebootlrs"
    container_name       = "tfstate"
    key                  = "vm.tfstate"
  }
}
