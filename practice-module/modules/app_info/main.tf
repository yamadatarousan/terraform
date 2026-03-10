variable "app_name" {
  type = string
}

output "app_summary" {
  value = "app=${var.app_name}"
}
