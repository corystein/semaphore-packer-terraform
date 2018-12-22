output "load_balancer_backend_address_pools_ids" {
  value = "${azurerm_lb_backend_address_pool.lb-backend.id}"
}
