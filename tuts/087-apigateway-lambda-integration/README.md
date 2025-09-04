# API Gateway Lambda Integration Tutorial

AWS CLIを使用してLambdaプロキシ統合でREST APIを作成するチュートリアルです。

## ファイル

- `apigateway-lambda-integration.md` - ステップバイステップのチュートリアル
- `apigateway-lambda-integration.sh` - 自動実行スクリプト

## 実行方法

### チュートリアルに従って手動実行
```bash
# チュートリアルを読んで手動でコマンドを実行
cat apigateway-lambda-integration.md
```

### スクリプトで自動実行
```bash
# 全手順を自動実行
chmod +x apigateway-lambda-integration.sh
./apigateway-lambda-integration.sh
```

## 前提条件

- AWS CLI設定済み
- 適切なIAM権限

## 作成されるリソース

- Lambda関数
- API Gateway REST API
- IAMロール

スクリプト実行後、すべてのリソースは自動的にクリーンアップされます。
