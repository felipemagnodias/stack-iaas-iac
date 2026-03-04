provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_subnet" "existing" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group

  accelerated_networking_enabled = var.accelerated_networking

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.existing.id
    private_ip_address_allocation = var.private_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_user
  admin_password      = var.admin_pass

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  zone = var.availability_zone

  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_sku
    disk_size_gb         = var.os_disk_size
  }

  boot_diagnostics {
    storage_account_uri = var.boot_diag_storage
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = var.tags
}

# ==========================
# DATA DISKS
# ==========================

resource "azurerm_managed_disk" "data" {
  for_each = {
    for idx, disk in var.data_disks :
    idx => disk
  }

  name                 = "${var.vm_name}-datadisk-${each.key}"
  location             = var.location
  resource_group_name  = var.resource_group
  storage_account_type = each.value.sku
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb
  zone                 = try(each.value.zone, null)
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach" {
  for_each = azurerm_managed_disk.data

  managed_disk_id    = each.value.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = tonumber(each.key)
  caching            = var.data_disks[tonumber(each.key)].caching
}
