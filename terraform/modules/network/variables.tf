variable "vnet_resource_group_name" {
  description = "The resource gropu where the virtual network exists."
}

variable "vnet_name" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "my-vnet"
}

variable "subnet_name" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "my-subnet"
}
