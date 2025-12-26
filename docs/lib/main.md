'''
# `main.dart` - アプリケーションのエントリーポイント

`main.dart`は、Flutterアプリケーション全体の起動と初期化を担当する中心的なファイルです。

## 主要な役割

1.  **初期化処理の実行**: アプリケーションがUIを描画する前に必要な、すべての非同期初期化処理を管理します。
2.  **認証状態の監視**: Firebase Authenticationの認証状態を監視し、ユーザーがログインしているかどうかに基づいて表示する画面を切り替えます。
3.  **トップレベルのエラーハンドリング**: アプリケーションのどのレイヤーで発生したかに関わらず、キャッチされなかった致命的なエラーを捕捉し、記録します。

## 初期化シーケンス (`initializeAndRunApp`)

アプリケーションの起動ロジックは`initializeAndRunApp`関数に集約されており、`main`関数から`runZonedGuarded`を介して安全に呼び出されます。

主な初期化ステップは以下の通りです。

1.  **Flutter Engineのバインディング**: `WidgetsFlutterBinding.ensureInitialized()`を呼び出し、プラグインがネイティブコードと通信できるようにします。
2.  **Firebaseの初期化**: `Firebase.initializeApp()`を実行し、Firebaseサービスを利用可能にします。
3.  **MSAL (Microsoft Authentication Library) の初期化**: `FbAuth.instance.initializeMsal()`を呼び出し、Microsoftサインインの準備をします。 **(注: 現在この機能は互換性の問題で一時的に無効化されています)**
4.  **Crashlyticsの設定**: `FlutterError.onError`と`PlatformDispatcher.instance.onError`をオーバーライドし、Flutterフレームワーク内外で発生したエラーをFirebase Crashlyticsに送信します。
5.  **環境変数のロード**: `.env`ファイルから環境変数（APIキーなど）をロードします。
6.  **写真ライブラリへの権限要求**: `PhotoManager.requestPermissionExtend()`を呼び出し、ギャラリーへのアクセス許可をユーザーに求めます。

### 初期化エラーハンドリング

`try-catch`ブロックを使用して、初期化プロセス中に発生した例外を捕捉します。エラーが発生した場合、通常のアプリ（`MyApp`）の代わりに`InitializationErrorScreen`ウィジェットが描画されます。この画面には、ユーザーが初期化処理を再試行するためのボタンが表示されます。
エラー情報は`FirebaseCrashlytics`にも送信され、開発者が問題を追跡できるようにしています。

## アプリケーション本体 (`MyApp`)

初期化が正常に完了すると、`runApp(const MyApp())`が実行されます。

`MyApp`は`MaterialApp`をルートウィジェットとし、`StreamBuilder`を使用して`FbAuth.instance.authStateChanges`ストリームを監視します。

-   **ストリームがデータを返すまで**: `CircularProgressIndicator`を表示します。
-   **ストリームがエラーを返した場合**: エラーメッセージを表示し、そのエラーをCrashlyticsに記録します。
-   **ストリームがデータを返した場合**:
    -   ユーザーデータが存在する（`snapshot.hasData`が`true`）場合、ログイン済みと判断し、`MainTabPage`を表示します。
    -   ユーザーデータが存在しない場合、未ログインと判断し、`AuthPage`を表示します。

これにより、リアクティブな方法で認証状態の変更に対応し、適切な画面へユーザーを誘導することができます。
'''