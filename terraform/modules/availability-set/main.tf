//----------------------------------------------------------------------
// General
//----------------------------------------------------------------------

data "azurerm_resource_group" "rg" {
  name = "${var.resource_group_name}"
}

//----------------------------------------------------------------------

resource "azurerm_availability_set" "av_set" {
  name                = "${var.prefix}-av-set"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  managed = true

  tags = "${var.tags}"
}
