# 無料で進めるTerraform練習メニュー

作成日: 2026-03-10

## 目的

クラウド課金を避けつつ、Terraformを実務で使うための基礎を身につける。

## 方針

- 最初はクラウドを使わない
- ローカルで `init` `plan` `apply` `destroy` を繰り返す
- `apply` より `plan` と `state` の理解を優先する
- 実務で重要な `variable` `output` `module` `validate` を早めに触る

## 事前確認

最初に以下を確認する。

```bash
terraform version
docker version
pwd
```

Dockerを使う練習では、Docker Desktopが起動していることも確認する。

## まず覚える基本コマンド

```bash
terraform init
terraform plan
terraform apply
terraform output
terraform show
terraform state list
terraform destroy
```

意味:

- `init`: providerを取得して作業ディレクトリを初期化する
- `plan`: 何が変わるかを確認する
- `apply`: 実際に作成・変更する
- `output`: output値を表示する
- `show`: stateの内容を人間向けに表示する
- `state list`: 管理対象一覧を表示する
- `destroy`: 作ったものを削除する

## 練習メニュー

### 1. Dockerで最小構成を作る

題材:

- Nginxコンテナを1つ作る
- ポート公開する
- コンテナ名を変数化する
- 接続URLをoutputで出す

身につくこと:

- provider
- resource
- output
- `terraform init`
- `terraform plan`
- `terraform apply`
- `terraform destroy`

最初の到達点:

- `plan` の差分を読める
- `apply` 後にブラウザで動作確認できる
- `destroy` で消せる

実際に打つコマンド:

```bash
cd /Users/user/Development/terraform/learn-terraform-docker-container
terraform init
terraform plan
terraform apply
terraform output
terraform state list
terraform show
terraform destroy
```

途中で聞かれること:

- `terraform apply` では最後に `Enter a value:` が出るので `yes` を入力する
- `terraform destroy` でも同じく `yes` を入力する

確認ポイント:

- `terraform plan` で `Plan: 2 to add` のような件数が出る
- `terraform apply` 後に `container_id` などのoutputが見える
- ブラウザで `http://localhost:8000` を開くとNginxが見える
- `terraform state list` で `docker_container.nginx` などが出る

変数を変えてもう1回試す:

```bash
terraform plan -var 'container_name=MyNginxContainer'
terraform apply -var 'container_name=MyNginxContainer'
```

学ぶこと:

- 変数を変えると差分がどう出るか
- `plan` と `apply` の結果がどうつながるか

## 2. `local` providerでファイル生成を試す

題材:

- `local_file` で設定ファイルを生成する
- 変数を使って出力内容を変える
- `locals` を使って文字列を組み立てる

身につくこと:

- `variable`
- `locals`
- `output`
- 差分更新の見方

ポイント:

クラウドやDockerがなくても、Terraformの宣言と差分管理の感覚を掴める。

実際に作る手順:

```bash
cd /Users/user/Development/terraform
mkdir -p practice-local-file
cd practice-local-file
```

`main.tf` を作る:

```hcl
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
```

打つコマンド:

```bash
terraform init
terraform plan
terraform apply
cat sample.txt
terraform output
terraform plan -var 'message=updated by terraform'
terraform apply -var 'message=updated by terraform'
cat sample.txt
terraform destroy
```

確認ポイント:

- `sample.txt` が生成される
- 変数を変えるとファイル内容が差し替わる
- Dockerやクラウドがなくても差分管理を体験できる

## 3. `random` providerで命名規則を作る

題材:

- `random_pet` や `random_string` を使って名前を生成する
- `local_file` と組み合わせて設定値を書き出す

身につくこと:

- provider追加の流れ
- resource間の参照
- stateに値が保持される感覚

ポイント:

「毎回ランダムに変わる」のではなく、「stateに保持されるから同じ値を再利用する」というTerraformらしさを理解しやすい。

`main.tf` の差し替え例:

```hcl
terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

resource "random_pet" "name" {
  length = 2
}

resource "local_file" "sample" {
  filename = "${path.module}/generated-name.txt"
  content  = random_pet.name.id
}

output "generated_name" {
  value = random_pet.name.id
}
```

打つコマンド:

```bash
terraform init
terraform plan
terraform apply
cat generated-name.txt
terraform output
terraform plan
terraform destroy
```

確認ポイント:

- 1回目の `apply` で名前が生成される
- その後の `plan` では、何も変えなければ差分が出ない
- stateが値を保持していることが分かる

## 4. moduleを1つ切る

題材:

- `modules/app_info` のような小さいmoduleを作る
- 変数を受け取り、ファイル生成や値のoutputを行う
- ルートmoduleから呼び出す

身につくこと:

- moduleの基本
- input/outputの設計
- 再利用の考え方

ポイント:

最初から大きく分割しない。  
1つの責務だけ持つmoduleを作る。

実際に作る手順:

```bash
cd /Users/user/Development/terraform
mkdir -p practice-module/modules/app_info
cd practice-module
```

ルートの `main.tf`:

```hcl
module "app_info" {
  source   = "./modules/app_info"
  app_name = "nginx"
}

output "app_summary" {
  value = module.app_info.app_summary
}
```

`modules/app_info/main.tf`:

```hcl
variable "app_name" {
  type = string
}

output "app_summary" {
  value = "app=${var.app_name}"
}
```

打つコマンド:

```bash
terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```

確認ポイント:

- moduleに値を渡せる
- moduleのoutputをルートで受けられる
- input/output設計の最小形が分かる

## 5. 環境分離を真似する

題材:

- `envs/dev`
- `envs/stg`
- `envs/prod`

のようにディレクトリを分ける。

身につくこと:

- 環境ごとの変数管理
- ディレクトリ構成の考え方
- 実務に近い整理方法

ポイント:

同じmoduleを環境ごとに呼び分ける構成を作ると、実務への接続がかなり良くなる。

実際に作る手順:

```bash
cd /Users/user/Development/terraform
mkdir -p practice-envs/envs/dev
mkdir -p practice-envs/envs/stg
mkdir -p practice-envs/modules/app_info
cd practice-envs
```

`modules/app_info/main.tf`:

```hcl
variable "app_name" {
  type = string
}

output "app_summary" {
  value = "app=${var.app_name}"
}
```

`envs/dev/main.tf`:

```hcl
module "app_info" {
  source = "../../../practice-module/modules/app_info"
  app_name = "sample-dev"
}

output "app_summary" {
  value = module.app_info.app_summary
}
```

`envs/stg/main.tf`:

```hcl
module "app_info" {
  source = "../../../practice-module/modules/app_info"
  app_name = "sample-stg"
}

output "app_summary" {
  value = module.app_info.app_summary
}
```

打つコマンド:

```bash
cd envs/dev
terraform init
terraform apply
terraform output
terraform destroy

cd ../stg
terraform init
terraform apply
terraform output
terraform destroy
```

確認ポイント:

- 同じmoduleでも環境ごとに出力が変わる
- ディレクトリで環境を分ける感覚が掴める

## 6. `fmt` と `validate` を習慣化する

毎回やること:

```bash
terraform fmt -recursive
terraform validate
```

打つ場所:

- 各練習ディレクトリの直下
- 複数ディレクトリをまとめて整えたいときはリポジトリルート

身につくこと:

- 構文の早期検出
- コードスタイルの統一
- CIに載せる前提の運用

## 7. stateを観察する

見るもの:

- `terraform.tfstate`
- `terraform.tfstate.backup`
- `terraform show`
- `terraform state list`

身につくこと:

- Terraformが何を記録しているか
- 差分判定の仕組み
- stateが壊れると危ない理由

ポイント:

無料学習でも、state理解は最優先。

打つコマンド:

```bash
terraform show
terraform state list
cat terraform.tfstate
```

見るポイント:

- resource名がどう保存されているか
- idやattributesがどう保持されているか
- `plan` がこのstateと設定ファイルを比較していること

## 8. `import` を1回試す

題材:

- Dockerやローカルで既存対象をTerraform管理に入れる
- import後にコードとstateの関係を確認する

身につくこと:

- 既存リソース管理の流れ
- 新規作成だけではないTerraformの使い方

ポイント:

実務では新規作成より、既存環境の取り込みの方が難しいことが多い。

最初は無理にやらなくてよい。  
Dockerの基本と `local` provider の差分管理に慣れてから試す。

進め方のイメージ:

```bash
terraform import <resource address> <real resource id>
terraform state list
terraform show
```

注意:

- resource addressはTerraformコード側の名前
- real resource idは実際の対象のID
- import後は「コード」と「state」が一致しているかを確認する

## 2週間のおすすめ進行

### 1週目

- 1日目: Dockerで `init` `plan` `apply` `destroy`
- 2日目: `variable` `output` `locals`
- 3日目: `local_file` と `random` provider
- 4日目: state観察
- 5日目: `fmt` `validate` を習慣化

### 2週目

- 1日目: 小さいmoduleを作る
- 2日目: `dev/stg/prod` の分離
- 3日目: `import` を試す
- 4日目: ディレクトリ構成を整理する
- 5日目: 自分で最小構成をゼロから作り直す

## 実務寄りにするための意識

- 変更前に必ず `plan` を読む
- outputは必要な値だけ出す
- moduleは小さく切る
- 命名規則を揃える
- 変数の責務を曖昧にしない
- stateを雑に扱わない

## 無料学習で避けること

- いきなりAWSやGCPで広い構成を作る
- 無料枠を前提に放置する
- `apply` だけ繰り返して `plan` を読まない
- moduleを早すぎる段階で複雑化する

## 次の一歩

このリポジトリですぐやるなら、次は以下がよい。

1. `learn-terraform-docker-container/` のコードを読み直す
2. 変数を1つ追加する
3. outputを1つ追加する
4. `plan` の差分を説明できるようにする
5. 同じ題材を自力で別ディレクトリに作り直す
