variable "aws_region" {
  description = "AWS providerが操作対象とするリージョン。例: ap-northeast-1"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "タグやリソース名の接頭辞として使うプロジェクト名。"
  type        = string
  default     = "sample-webapp"
}

variable "environment" {
  description = "環境名。dev, stg, prodのような単位で切り替える想定。"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC全体で使うCIDR。学習用なので小さすぎず分割しやすい範囲にしている。"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "ALB用に2AZへまたがるpublic subnetを作るためのCIDR一覧。"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_type" {
  description = "Webサーバとして動かすEC2のインスタンスタイプ。"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Webアプリケーションがlistenするポート。ここではNginxの80番を使う。"
  type        = number
  default     = 80
}

