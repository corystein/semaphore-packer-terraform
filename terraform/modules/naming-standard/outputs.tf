output "prefix" {
  value = "${var.prefix}-${var.vendor_code}${var.country_code}-${var.subscription_code}-${var.environment_code}"
}

output "storage-account-prefix" {
  value = "${lower(var.prefix)}${lower(var.vendor_code)}${lower(var.country_code)}${lower(var.subscription_code)}${lower(var.environment_code)}"
}
