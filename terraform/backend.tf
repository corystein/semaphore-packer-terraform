terraform {
  backend "azurerm" {
    resource_group_name  = "PZI-GXUS-G-RGP-PADM-P001"
    storage_account_name = "pzigxusgrgppadmp001"
    container_name       = "tfstate"
    key                  = "dev.semaphore.tfstate"
  }
}
