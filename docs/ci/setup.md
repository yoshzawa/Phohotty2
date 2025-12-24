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

### Codemagicでの設定例

Codemagicでこの仕組みを利用する場合、以下の手順で設定します。

1.  **`GoogleService-Info.plist` のBase64エンコード**:
    ローカルマシンで上記の手順1を実行し、`GoogleService-Info.plist` ファイルのBase64エンコード文字列を取得します。

2.  **Codemagicの環境変数に設定**:
    - Codemagicのプロジェクトダッシュボードに移動します。
    - "Environment variables" タブを開きます。
    - `GOOGLE_SERVICE_INFO_BASE64` という名前の環境変数を追加します。
    - "Value" に、先ほどコピーしたBase64文字列を貼り付けます。
    - **"Secure"** チェックボックスを必ずオンにしてください。

3.  **ビルドスクリプトの追加**:
    - "Pre-build scripts" セクションに、以下のコマンドを追加します。これにより、ビルドが開始される前に `GoogleService-Info.plist` が生成されます。

    ```bash
    #!/bin/sh
    ./scripts/generate_google_service_info.sh
    ```
    または、`codemagic.yaml` を使用している場合は、`scripts` セクションに追加します。
    ```yaml
    scripts:
      - name: Generate GoogleService-Info.plist
        script: | 
          ./scripts/generate_google_service_info.sh
      - name: ... other build steps
        script: | 
          ...
    ```

これで、Codemagicでのビルド時に `GoogleService-Info.plist` が安全に配置されます。
