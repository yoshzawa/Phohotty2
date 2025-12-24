# CI/CD とローカル環境のセットアップ

このドキュメントでは、CI/CD環境およびローカル開発環境で `GoogleService-Info.plist` ファイルをセットアップする方法について説明します。

## `GoogleService-Info.plist` のセットアップ

アプリケーションがFirebaseサービスに接続するためには `GoogleService-Info.plist` ファイルが必要ですが、セキュリティ上の理由からGitリポジトリにはチェックインされません。

ビルド時にこのファイルを自動生成するプロセスを自動化するために、`scripts/generate_google_service_info.sh` スクリプトを使用できます。このスクリプトは、環境変数に保存されているBase64エンコードされた `GoogleService-Info.plist` ファイルのバージョンをデコードします。

### 手順

1.  **`GoogleService-Info.plist` ファイルをエンコードします:**

    ```bash
    base64 -i path/to/your/GoogleService-Info.plist
    ```

2.  **環境変数を設定します:**

    Base64エンコードされた文字列をコピーし、CI/CDサービス（例：GitHub Actions, Codemagic）またはローカルの開発環境でシークレット環境変数として設定します。環境変数名は `GOOGLE_SERVICE_INFO_BASE64` である必要があります。

3.  **生成スクリプトを実行します:**

    ビルドプロセスの前に、スクリプトを実行して `GoogleService-Info.plist` ファイルを生成します:

    ```bash
    ./scripts/generate_google_service_info.sh
    ```
