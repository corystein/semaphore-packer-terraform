//----------------------------------------------------------------------
// General
//----------------------------------------------------------------------

data "azurerm_resource_group" "rg" {
  name = "${var.resource_group_name}"
}

//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Network
//----------------------------------------------------------------------
resource "azurerm_public_ip" "pip" {
  name                         = "${var.prefix}-lb-pip"
  location                     = "${data.azurerm_resource_group.rg.location}"
  resource_group_name          = "${data.azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "static"

  tags = "${var.tags}"
}

//----------------------------------------------------------------------

resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.pip.id}"
  }

  tags = "${var.tags}"
}

resource "azurerm_lb_backend_address_pool" "lb-backend" {
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "HTTPS" {
  name                           = "HTTPS"
  resource_group_name            = "${data.azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  protocol                       = "Tcp"
  frontend_port                  = "443"
  backend_port                   = "443"
  probe_id                       = "${azurerm_lb_probe.lb_probe_https.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.lb-backend.id}"
}

resource "azurerm_lb_rule" "RedirectHTTP" {
  name                = "RedirectHTTP"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  loadbalancer_id                = "${azurerm_lb.lb.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "443"
}

resource "azurerm_lb_probe" "lb_probe_https" {
  name                = "https-running-probe"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  port                = "443"
}
