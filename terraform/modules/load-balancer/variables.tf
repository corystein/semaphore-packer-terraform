variable "prefix" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "resource_group_name" {
  description = "The resource gropu where the virtual network exists."
}

#variable "location" {
#  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
#}

variable "tags" {
  description = "The resource tags."
  type        = "map"
}
