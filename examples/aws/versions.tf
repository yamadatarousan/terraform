terraform {
  # Terraform本体のバージョン制約。
  # チーム開発では「誰が実行しても同じ挙動になりやすい」ように、
  # 少なくともメジャーバージョンを跨がない制約を置くことが多い。
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      # HashiCorp公式のAWS provider。
      # 実務ではproviderのメジャーバージョン差分が大きいことがあるので、
      # バージョン制約は明示しておく方が安全。
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  # 実際にapplyする場合は、ここで指定したリージョンに全リソースが作られる。
  # 学習用なので最小限の指定だけにしている。
  region = var.aws_region
}

