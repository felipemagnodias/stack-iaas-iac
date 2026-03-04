subscription_id = "1a6a11af-b98f-4269-8e50-2e8012bcf8f7"

resource_group = "RG-EASTU-NETWORK"
vnet_rg        = "RG-EASTU-NETWORK"
vnet_name      = "VNET-EASTU-NETWORK"
subnet_name    = "SNET-EASTU-NETWORK"

vm_name  = "vm-app01"
location = "eastus"
availability_zone = "1"

vm_size    = "Standard_D2s_v5"
admin_user = "azureadmin"
admin_pass = "mar@01mar201"

private_ip = null

accelerated_networking = true

os_disk_size = 128
storage_sku  = "Standard_LRS"

boot_diag_storage = "https://storagebootlrs.blob.core.windows.net/"

tags = {
  hostname   = "vm-app01"
  environment = "PRD"
  service     = "Virtual Machine"
  management  = "TAM"
  sistema     = "Linux"
  faturavel   = "Sim"
  CHG         = "CHG123"
  TVT         = "TVT001"
}

data_disks = [
  {
    size_gb = 128
    sku     = "Standard_LRS"
    caching = "None"
    zone    = "1"
  },
  {
    size_gb = 256
    sku     = "StandardSSD_LRS"
    caching = "None"
    zone    = "1"
  }
]
