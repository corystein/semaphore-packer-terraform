//----------------------------------------------------------------------
// General
//----------------------------------------------------------------------

terraform {
  required_version = ">= 0.11.9"
}

# Configure the Azure Provider
provider "azurerm" {}

// Generate resource naming standard
module "naming" {
  source            = "modules/naming-standard/"
  prefix            = "PZI"
  vendor_code       = "GX"
  country_code      = "US"
  subscription_code = "D"
  environment_code  = "D"
}

//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Network
//----------------------------------------------------------------------

module "network" {
  source = "modules/network/"

  vnet_resource_group_name = "${var.vnet_resource_group_name}"
  vnet_name                = "${var.vnet_name}"
  subnet_name              = "${var.subnet_name}"
}

//----------------------------------------------------------------------

//----------------------------------------------------------------------
// VM
//----------------------------------------------------------------------

module "resource-group" {
  source              = "modules/resource-group/"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"

  tags = "${var.default_tags}"
}

module "load-balancer" {
  source              = "modules/load-balancer/"
  prefix              = "${module.naming.prefix}"
  resource_group_name = "${module.resource-group.resource_group_name}"

  #location            = "${module.resource-group.location}"

  tags = "${var.default_tags}"
}

module "av-set" {
  source              = "modules/availability-set/"
  prefix              = "${module.naming.prefix}"
  resource_group_name = "${module.resource-group.resource_group_name}"

  #location            = "${module.resource-group.location}"

  tags = "${var.default_tags}"
}

module "vm" {
  source              = "modules/linux-vm/"
  prefix              = "${module.naming.prefix}"
  resource_group_name = "${module.resource-group.resource_group_name}"

  #location            = "${module.resource-group.location}"
  subnet_id = "${module.network.subnet_id}"

  availability_set_id = "${module.av-set.availability_set_id}"

  managed_image                = "${var.managed_image}"
  managed_image_resource_group = "${var.managed_image_resource_group}"

  hostname       = "${var.hostname}"
  vm_size        = "${var.vm_size}"
  admin_username = "${var.admin_username}"
  admin_password = "${var.admin_password}"

  load_balancer_backend_address_pools_ids = "${module.load-balancer.load_balancer_backend_address_pools_ids}"

  tags = "${var.default_tags}"
}

//----------------------------------------------------------------------

