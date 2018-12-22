//----------------------------------------------------------------------
// VNet
//----------------------------------------------------------------------
data "azurerm_virtual_network" "vnet" {
  name                = "${var.vnet_name}"
  resource_group_name = "${var.vnet_resource_group_name}"
}

//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Subnet
//----------------------------------------------------------------------
data "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  virtual_network_name = "${data.azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${data.azurerm_virtual_network.vnet.resource_group_name}"
}

//----------------------------------------------------------------------

