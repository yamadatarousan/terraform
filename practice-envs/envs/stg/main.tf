module "app_info" {
  source   = "../../../practice-module/modules/app_info"
  app_name = "sample-stg"
}

output "app_summary" {
  value = module.app_info.app_summary
}
