# CI/CDセットアップガイド

このドキュメントは、CI/CD環境（例: Codemagic）をセットアップする手順について説明します。

## 環境変数

CI/CD環境では、以下の環境変数を設定する必要があります。

### Firebase

*   `GOOGLE_SERVICE_INFO_BASE64`: Firebaseプロジェクトの`GoogleService-Info.plist`（iOS用）をBase64でエンコードした文字列。
*   `GOOGLE_SERVICES_JSON_BASE64`: Firebaseプロジェクトの`google-services.json`（Android用）をBase64でエンコードした文字列。

これらのファイルは、CI/CDのビルドプロセス中に、以下のスクリプトによってデコードされ、適切な場所に配置されます。

**`scripts/generate_google_service_info.sh` (iOS)**

```sh
echo $GOOGLE_SERVICE_INFO_BASE64 | base64 -d > ios/Runner/GoogleService-Info.plist
```

**`scripts/generate_google_services_json.sh` (Android)**

```sh
echo $GOOGLE_SERVICES_JSON_BASE64 | base64 -d > android/app/google-services.json
```

**重要:** `GoogleService-Info.plist`の出力先は、Xcodeが認識できるよう`ios/Runner/`ディレクトリである必要があります。

### App Store Connect

App Store Connectへのデプロイには、以下の環境変数が必要です。

*   `APP_STORE_CONNECT_KEY_ID`: App Store Connect APIキーのキーID。
*   `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect APIキーの発行者ID。
*   `APP_STORE_CONNECT_PRIVATE_KEY`: App Store Connect APIキーの秘密鍵。
*   `APP_STORE_APPLE_ID`: アプリのApple ID。
