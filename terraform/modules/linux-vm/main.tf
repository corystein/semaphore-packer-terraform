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
  name                         = "${var.prefix}-pip"
  location                     = "${data.azurerm_resource_group.rg.location}"
  resource_group_name          = "${data.azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"

  idle_timeout_in_minutes = 30

  tags = "${var.tags}"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  //network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.pip.id}"

    load_balancer_backend_address_pools_ids = ["${var.load_balancer_backend_address_pools_ids}"]
  }
  tags = "${var.tags}"
}

//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Storage
//----------------------------------------------------------------------

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${data.azurerm_resource_group.rg.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${data.azurerm_resource_group.rg.name}"
  location                 = "${data.azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = "${var.tags}"
}

//----------------------------------------------------------------------

//----------------------------------------------------------------------
// VM
//----------------------------------------------------------------------
data "azurerm_image" "image" {
  name                = "${var.managed_image}"
  resource_group_name = "${var.managed_image_resource_group}"
}

resource "azurerm_managed_disk" "managed_disk" {
  name                 = "${var.prefix}-managed-disk"
  location             = "${data.azurerm_resource_group.rg.location}"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "512"
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.prefix}-vm"
  location              = "${data.azurerm_resource_group.rg.location}"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]
  vm_size               = "${var.vm_size}"

  availability_set_id = "${var.availability_set_id}"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.image.id}"
  }

  storage_os_disk {
    name              = "${var.prefix}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "128"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.managed_disk.name}"
    managed_disk_id = "${azurerm_managed_disk.managed_disk.id}"
    create_option   = "Attach"
    lun             = "1"
    disk_size_gb    = "${azurerm_managed_disk.managed_disk.disk_size_gb}"
  }

  os_profile {
    computer_name  = "${var.hostname}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
  }

  tags = "${var.tags}"

  depends_on = ["azurerm_storage_account.mystorageaccount", "azurerm_managed_disk.managed_disk", "azurerm_network_interface.nic"]
}

data "azurerm_public_ip" "get-ip" {
  name                = "${azurerm_public_ip.pip.name}"
  resource_group_name = "${azurerm_virtual_machine.vm.resource_group_name}"
}

resource "null_resource" "partition-disks" {
  connection {
    type     = "ssh"
    host     = "${data.azurerm_public_ip.get-ip.ip_address}"
    user     = "${var.admin_username}"
    password = "${var.admin_password}"
  }

  provisioner "remote-exec" {
    # Bootstrap script check disk is resized
    inline = [
      "df -h",
      "ls /install",
      "fdisk -l",
      "bash /install/autopart.sh",
      "df -h",
    ]
  }

  depends_on = ["azurerm_virtual_machine.vm", "data.azurerm_public_ip.get-ip"]
}

//----------------------------------------------------------------------

