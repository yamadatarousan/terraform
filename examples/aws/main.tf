locals {
  # 名前を一箇所で組み立てておくと、resourceごとにバラバラな命名になりにくい。
  # 実務では project/environment/role を組み合わせることが多い。
  name_prefix = "${var.project_name}-${var.environment}"

  # 全resourceへ最低限付ける共通タグ。
  # コスト集計、棚卸し、運用時の検索性に効くので、タグ戦略は実務で重要。
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "aws_availability_zones" "available" {
  # 指定リージョンで利用可能なAZ一覧を取得する。
  # subnetを2つ作るので、ここでは先頭2つのAZを使う。
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  # EC2を起動するためのAMIを検索する。
  # 学習用として扱いやすい Amazon Linux 2023 を採用している。
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_vpc" "main" {
  # ネットワークの土台となるVPC。
  # Webサーバ、ALB、DBなどを同じ論理ネットワークに載せるための最上位単位。
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  # public subnetからインターネットへ出るための出口。
  # ALBやpublic IP付きEC2が外部と通信するなら必要になる。
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  # public subnetを2つ作る。
  # ALBは高可用性のため、通常2つ以上のAZにまたがるsubnetが必要になる。
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  # public subnet用のルートテーブル。
  # 0.0.0.0/0 をInternet Gatewayへ向けることで外部通信可能にする。
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  # 作成した各public subnetへpublic用ルートテーブルを紐付ける。
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  # ALB用のSecurity Group。
  # インターネットからHTTPを受ける入口として使う。
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow inbound HTTP from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere for demo purposes"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "app" {
  # Webサーバ用のSecurity Group。
  # ポイントは「インターネットから直接80番を開けない」こと。
  # 代わりに、ALB用SGからの通信だけを許可する。
  name        = "${local.name_prefix}-app-sg"
  description = "Allow inbound app traffic only from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from the ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-sg"
  })
}

resource "aws_iam_role" "ec2_ssm" {
  # EC2へSSM経由で入れるようにするためのIAM Role。
  # 学習用でも、SSH鍵を前提にするよりこちらの方が今の運用に近い。
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-role"
  })
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  # AWSが提供する管理ポリシーをRoleへ付与する。
  # これによりSSM Agent経由の基本的な接続要件を満たせる。
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  # EC2へIAM RoleをアタッチするためのInstance Profile。
  name = "${local.name_prefix}-app-profile"
  role = aws_iam_role.ec2_ssm.name
}

resource "aws_lb" "web" {
  # 外部公開の入口となるApplication Load Balancer。
  # Webの入口をALBに寄せると、後からターゲット追加や証明書追加がしやすい。
  name               = replace("${local.name_prefix}-alb", "_", "-")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "app" {
  # ALBがトラフィックを転送する先。
  # ここではEC2インスタンス1台をターゲットとして登録する。
  name     = replace("${local.name_prefix}-tg", "_", "-")
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    # ALBが「Webサーバが生きているか」を判定する設定。
    # 本番ではアプリ専用のhealth check endpointを用意することが多い。
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-tg"
  })
}

resource "aws_lb_listener" "http" {
  # 80番ポートで受けたHTTPリクエストをTarget Groupへ流す。
  # 本番ではここにHTTPS(443)とACM証明書を追加することが多い。
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_instance" "app" {
  # Webアプリケーション本体を動かすEC2。
  # 実務ではprivate subnet + Auto Scaling Groupが候補になることが多いが、
  # 学習用として「構成要素が読みやすい単一インスタンス」に留めている。
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = true

  user_data = <<-EOT
              #!/bin/bash
              set -euxo pipefail

              dnf update -y
              dnf install -y nginx

              cat > /usr/share/nginx/html/index.html <<'HTML'
              <!doctype html>
              <html>
              <head>
                <meta charset="utf-8">
                <title>Terraform AWS Sample</title>
              </head>
              <body>
                <h1>Terraform AWS Sample</h1>
                <p>This page was generated from EC2 user_data.</p>
                <p>Environment: ${var.environment}</p>
                <p>Project: ${var.project_name}</p>
              </body>
              </html>
              HTML

              systemctl enable nginx
              systemctl restart nginx
              EOT

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-ec2"
    Role = "app"
  })
}

resource "aws_lb_target_group_attachment" "app" {
  # EC2をTarget Groupへ登録する。
  # これで ALB -> Target Group -> EC2 という通信経路が完成する。
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = var.app_port
}

