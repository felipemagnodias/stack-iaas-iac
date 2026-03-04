variable "subscription_id" {}
variable "resource_group" {}
variable "vnet_rg" {}
variable "vnet_name" {}
variable "subnet_name" {}

variable "vm_name" {}
variable "location" {}
variable "availability_zone" {
  default = null
}

variable "vm_size" {}
variable "admin_user" {}
variable "admin_pass" {
  sensitive = true
}

variable "private_ip" {
  default = null
}

variable "accelerated_networking" {
  type    = bool
  default = false
}

variable "os_disk_size" {}
variable "storage_sku" {}

variable "boot_diag_storage" {}

variable "tags" {
  type = map(string)
}

variable "data_disks" {
  type = list(object({
    size_gb = number
    sku     = string
    caching = string
    zone    = optional(string)
  }))
  default = []
}
