output "hostname" {
  value = "${var.hostname}"
}

/*
output "vm_public_ip" {
  value = "${module.vm.ip_address}"
}

output "vm_fqdn" {
  value = "${module.vm.fqdn}"
}
*/

output "prefix" {
  value = "${module.naming.prefix}"
}

output "storage-account-prefix" {
  value = "${module.naming.storage-account-prefix}"
}

output "admin_username" {
  value = "${var.admin_username}"
}

output "admin_password" {
  value = "${var.admin_password}"
}
