terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

variable "message" {
  type    = string
  default = "hello from terraform"
}

locals {
  file_body = "message = ${var.message}\n"
}

resource "local_file" "sample" {
  filename = "${path.module}/sample.txt"
  content  = local.file_body
}

output "created_file" {
  value = local_file.sample.filename
}