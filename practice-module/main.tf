module "app_info" {
  source   = "./modules/app_info"
  app_name = "nginx"
}

output "app_summary" {
  value = module.app_info.app_summary
}
