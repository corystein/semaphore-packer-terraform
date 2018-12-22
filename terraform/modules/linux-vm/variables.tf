variable "prefix" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "resource_group_name" {
  description = "The resource gropu where the virtual network exists."
}

#variable "location" {
#  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
#}

variable "subnet_id" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "availability_set_id" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "managed_image" {}

variable "managed_image_resource_group" {}

variable "hostname" {
  description = "VM name referenced also in storage-related names. This is also used as the label for the Domain Name and to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system."
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine. This must be the same as the vm image from which you are copying."
  default     = "Standard_DS1_v2"
}

variable "admin_username" {
  description = "administrator user name"

  #default     = "vmadmin"
}

variable "admin_password" {
  description = "The Password for the account specified in the 'admin_username' field. We recommend disabling Password Authentication in a Production environment."
}

variable "tags" {
  description = "The resource tags."
  type        = "map"
}

//----------------------------------------------------------------------
// Load Balancer
//----------------------------------------------------------------------
variable "load_balancer_backend_address_pools_ids" {
  description = "The resource tags."
}

//----------------------------------------------------------------------

