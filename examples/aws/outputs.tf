output "vpc_id" {
  description = "作成対象となるVPCのID。ネットワークの最上位IDとしてよく参照する。"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "ALBを配置しているpublic subnetのID一覧。"
  value       = aws_subnet.public[*].id
}

output "alb_dns_name" {
  description = "ALBのDNS名。実際にapplyした場合はここへHTTPアクセスすることになる。"
  value       = aws_lb.web.dns_name
}

output "app_instance_id" {
  description = "Webサーバとして動くEC2のインスタンスID。"
  value       = aws_instance.app.id
}

