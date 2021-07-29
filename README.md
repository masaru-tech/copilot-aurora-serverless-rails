## これは何？
Copilot(v1.8.2)を使用して、App Runner,Aurora Serverlessな環境で[Rails Tutorialのアプリ](https://github.com/yasslab/sample_apps) を動かしてみたものです。  
現状、App RunnerからAurora Serverlessに接続するにはData APIを利用するしかないので、[activerecord-aurora-serverless-adapter](https://github.com/customink/activerecord-aurora-serverless-adapter) を利用しています。

## 環境
Copilotによって下記の環境を構築します
* Service
  * app (Request-Driven Web Service)
    * App Runner
  * rails-playground (Backend Service)
    * Aurora Serverless v1 (MySQL)
    * S3バケット
    * ECS
      * countを0にしているのでタスクは何も起動していない状態
* Task
  * rakeタスクなどone shotなコマンド実行のために使用

## 手動設定でやること
基本的にはCopilotが作成したリソースでやりくりしますが、ロールにポリシーを追加する必要があったのでそこは手作業で行ってます
ECSのTaskRoleとApp RunnerのInstanceRoleに下記のポリシーを追加
* AmazonRDSDataFullAccess
* execution-roleオプションのロールにあるインラインポリシー({App}-{Env}-rails-playgroundSecretsPolicy)と同じインラインポリシーを追加
