# Terraform学習メモ

作成日: 2026-03-10

## 目的

Terraformを「触ったことがある」ではなく、実務で最低限使える状態まで持っていくための学習順をまとめる。

## このMacの現状

- `Homebrew 5.0.16` は入っている
- `terraform` は未導入
- CPU は `x86_64` (Intel Mac)

## 最初にやること

公式のMac向け手順に沿ってTerraformを入れる。

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version
terraform -help
```

2026-03-10時点では、HashiCorp公式のInstallページに Terraform `v1.14.5` が表示されている。

## 学習の進め方

### 1. まずはローカルでTerraformの基本を掴む

最初からクラウド料金やIAMで詰まると学習効率が落ちる。  
先に公式の `Docker Get Started` で以下を理解する。

- `init`
- `plan`
- `apply`
- `destroy`
- provider
- resource
- state
- output

ここは「Terraformの操作モデル」を覚える段階。  
実務では、この4コマンドとstateの感覚が最重要。

### 2. 次に1つのクラウドに絞る

職場で使うクラウドが決まっているなら、それを最優先にする。  
未定なら、まず1つに絞って以下を作れるようにする。

- VPCまたはネットワーク
- サブネット
- セキュリティグループまたはファイアウォール
- VMまたはコンテナ実行基盤
- オブジェクトストレージ

ここで覚えるべきはクラウド固有知識ではなく、Terraformでの分割と管理の仕方。

### 3. 実務で必要な論点に入る

基本操作の次は、以下を優先して学ぶ。

- 変数 `variable`
- 出力 `output`
- ローカル値 `locals`
- バージョン制約 `required_version` と `required_providers`
- フォーマットと検証 `terraform fmt` `terraform validate`
- ロックファイル `.terraform.lock.hcl`
- モジュール `module`
- stateの保存場所
- 既存リソースの取り込み `import`

このあたりから「個人学習」ではなく「チームで壊さず運用する」視点になる。

### 4. チーム運用を意識して1段上げる

実務で価値が出るのは、単にapplyできることではなく、変更の安全性を担保できること。

- リポジトリ構成を整理する
- 環境ごとに分ける
- 再利用可能なmoduleを切る
- CIで `fmt` `validate` `plan` を回す
- remote stateを使う
- review前提で差分を読めるようにする

## 学習の順番

### フェーズ1: 1日目

- Terraformをインストールする
- `init / plan / apply / destroy` を1回ずつ動かす
- stateファイルがどう変わるかを見る

### フェーズ2: 2日目から3日目

- 変数とoutputを使う
- provider versionを固定する
- `fmt` と `validate` を習慣化する
- `.terraform` と `.terraform.lock.hcl` の役割を理解する

### フェーズ3: 4日目から7日目

- moduleを1つ切る
- dev/stg/prodの分け方を考える
- backendとstate管理を学ぶ
- `import` を試す

### フェーズ4: 2週目以降

- 実際のクラウドで小さな構成を作る
- 変更差分をレビューできる形にする
- 既存インフラをTerraform管理へ寄せる練習をする

## 実務で特に重要な考え方

### 1. 「applyする」より「planを読める」が大事

事故はapply前に防ぐ。  
差分を読めないまま運用に入ると危ない。

### 2. module化は早すぎても遅すぎてもダメ

最初は単一ファイルでよい。  
重複や責務が見えてから切り出す方が健全。

### 3. stateはTerraformの中心

stateを雑に扱うと壊れる。  
実務ではstateの保存先、排他、バックアップを必ず意識する。

### 4. 既存環境を扱うなら `import` は必須

新規構築だけでなく、既存リソースを管理下に入れる場面が多い。

## 最初の到達目標

以下を自力でできれば、入門はかなり実務寄りになる。

- 新しい環境を `init` できる
- `plan` の差分を説明できる
- `apply` と `destroy` を安全に使える
- 変数とoutputを使って構成を整理できる
- moduleを1つ作れる
- state管理の注意点を説明できる
- 既存リソースを `import` できる

## 次に作るとよい題材

- DockerでNginxコンテナを作る最小構成
- クラウド上に小さなWebサーバを1台立てる構成
- ネットワーク + VM + ストレージをmodule分割した構成
- dev/stg/prodを分けたディレクトリ構成

## 公式リンク

- Install Terraform: https://developer.hashicorp.com/terraform/install
- Get Started Tutorials: https://developer.hashicorp.com/terraform/tutorials
- Docker Get Started: https://developer.hashicorp.com/terraform/tutorials/docker-get-started
- Style Guide: https://developer.hashicorp.com/terraform/language/style
- Import existing infrastructure: https://developer.hashicorp.com/terraform/language/import

## 補足

「どのクラウドから始めるか」は職場や転職先で使うものに合わせるのが最優先。  
それが未定なら、まずはローカル学習でTerraform自体を理解してから、1つのクラウドに絞る進め方が最も無駄が少ない。
