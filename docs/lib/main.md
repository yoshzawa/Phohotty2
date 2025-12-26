# `main.dart`

**ファイルパス:** `lib/main.dart`

## 概要

`main.dart` は、アプリケーション全体の起動シーケンスを管理するエントリーポイントです。
このファイルは、必要なサービスの初期化、エラーハンドリング、そしてユーザーの認証状態に基づいた初期画面の表示を担当します。

## 主要な構成要素

### `main()` 関数

- **役割**: アプリケーションの最上位エントリーポイント。
- **機能**:
    - `runZonedGuarded` を使用して、Flutterフレームワークで捕捉されない未処理のエラー（非同期エラーなど）をグローバルに捕捉し、Crashlyticsに報告します。
    - `initializeAndRunApp()` 関数を呼び出して、アプリの起動処理を開始します。

### `initializeAndRunApp()` 関数

- **役割**: すべての初期化処理を中央集権的に実行します。
- **機能**:
    - `WidgetsFlutterBinding.ensureInitialized()`: Flutterエンジンの準備を保証します。
    - **Firebaseの初期化**: `Firebase.apps.isEmpty` チェックを行い、二重初期化を防止します。
    - **Crashlyticsの設定**: Flutterフレームワーク内で発生したエラーをCrashlyticsに送信するよう設定します。
    - **`.env`ファイルの読み込み**: `flutter_dotenv` を使用して環境変数をロードします。
    - **権限要求**: `photo_manager` を使用して、フォトライブラリへのアクセス許可を要求します。
    - **初期化の成否判定**:
        - すべての初期化が成功した場合、`runApp(const MyApp())` を呼び出してメインアプリを起動します。
        - 初期化中に何らかのエラーが発生した場合、`runApp(InitializationErrorScreen(...))` を呼び出してエラー画面を表示します。

### `MyApp` ウィジェット

- **役割**: メインアプリケーションのルートウィジェット。
- **機能**:
    - `StreamBuilder` を使用して `FbAuth.instance.authStateChanges`（Firebaseの認証状態ストリーム）を監視します。
    - **認証状態に応じた画面遷移**:
        - 認証状態の読み込み中は、`CircularProgressIndicator` を表示します。
        - ユーザーがログインしている場合 (`snapshot.hasData` が `true`)、`MainTabPage` を表示します。
        - ユーザーがログインしていない場合、`AuthPage` を表示して認証を促します。
        - ストリームでエラーが発生した場合は、エラーメッセージを表示し、そのエラーをCrashlyticsに報告します。

### `InitializationErrorScreen` ウィジェット

- **役割**: 初期化プロセスが失敗した際に表示されるフォールバックUI。
- **機能**:
    - アプリの起動に失敗したことをユーザーに通知します。
    - 「Retry」ボタンを提供し、ユーザーが `initializeAndRunApp()` を再実行して初期化を再試行できるようにします。
