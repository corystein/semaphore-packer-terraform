//----------------------------------------------------------------------
// General
//----------------------------------------------------------------------
variable "resource_group_name" {
  description = "Resource group name into which your deployment will"
}

variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "East US"
}

variable "prefix" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "default_tags" {
  type = "map"

  default = {
    environment = "dev"
    billing     = ""
    owner       = "TBD"
  }
}

//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Network
//----------------------------------------------------------------------

variable "vnet_resource_group_name" {
  description = "The resource gropu where the virtual network exists."
}

variable "vnet_name" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "my-vnet"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/24"
}

variable "subnet_name" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "my-subnet"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.0.0/24"
}

//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Storage
//----------------------------------------------------------------------

/*
variable "storage_account_name" {
  description = "The name of the storage account in which the image from which you are cloning resides."
}

variable "storage_account_type" {
  description = "Defines the type of storage account to be created. Valid options are Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS. Changing this is sometimes valid - see the Azure documentation for more information on which types of accounts can be converted into other types."
  default     = "Premium_LRS"
}
*/

//----------------------------------------------------------------------

//----------------------------------------------------------------------
// VM
//----------------------------------------------------------------------

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

variable "managed_image" {
  description = "The Password for the account specified in the 'admin_username' field. We recommend disabling Password Authentication in a Production environment."
}

variable "managed_image_resource_group" {
  description = "The Password for the account specified in the 'admin_username' field. We recommend disabling Password Authentication in a Production environment."
}

//----------------------------------------------------------------------

