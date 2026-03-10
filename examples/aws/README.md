# AWS Web Application Sample

このディレクトリは、TerraformでAWS上のWebアプリケーション基盤をどう表現するかを学ぶためのサンプルです。

実装している主な構成要素:

- VPC
- 2つのpublic subnet
- Internet Gateway
- Route Table
- Application Load Balancer
- Webサーバ用EC2
- Security Group
- EC2用IAM Role / Instance Profile

設計意図:

- ALBをインターネット公開し、アプリサーバはALB経由でのみ到達できるようにする
- SSHを前提にせず、SSM Roleを付ける
- 学習しやすいようにpublic subnet中心で組む

実務との差分:

- 本番ではアプリサーバをprivate subnetに置くことが多い
- private subnet運用ではNAT GatewayやVPC Endpointなどの設計が必要になる
- 本番ではASG、RDS、WAF、ACM、Route 53、CloudWatch、Secrets Managerなども検討対象になる

apply前提ではないが、読む順番は以下がよい。

1. `versions.tf`
2. `variables.tf`
3. `main.tf`
4. `outputs.tf`

