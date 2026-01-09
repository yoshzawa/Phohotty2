'''
# `fb_auth.dart` - Firebase Authentication サービスクラス

`fb_auth.dart`は、Firebase Authenticationに関連するすべてのロジックをカプセル化し、UI層から抽象化するためのサービスクラスです。
シングルトンパターン（`FbAuth.instance`）で実装されており、アプリケーションのどこからでも同じインスタンスにアクセスできます。

## 主要な機能

-   **認証状態の提供**: ユーザーのログイン状態が変化したことを通知する`Stream`（`authStateChanges`）を提供します。
-   **サインイン処理**: Googleなどの外部プロバイダを利用したサインイン機能を提供します。
-   **サインアウト処理**: 現在のユーザーをサインアウトさせる機能を提供します。
-   **ユーザー情報の抽象化**: Firebaseの`User`オブジェクトを、よりシンプルなカスタムクラス`FbUser`に変換して提供します。

## クラスとメソッド

### `FbUser` クラス

Firebaseの`User`オブジェクトから必要な情報（UID, 表示名, メールアドレスなど）のみを抽出した、読み取り専用のシンプルなデータクラスです。
UI層は`User`オブジェクトに直接依存せず、この`FbUser`を介してユーザー情報を扱います。

### `FbAuth` クラス

#### プロパティ

-   `Stream<FbUser?> authStateChanges`: 認証状態の変化をストリームで通知します。ユーザーがログイン/ログアウトすると、新しい`FbUser`オブジェクトまたは`null`が流れます。
-   `FbUser? currentUser`: 現在ログインしているユーザーの情報を`FbUser`オブジェクトとして同期的に取得します。

#### メソッド

-   `Future<FbUser?> signInWithGoogle()`: Googleサインインのフローを開始します。成功すると`FbUser`オブジェクトを返し、ユーザーがキャンセルした場合は`null`を返します。

-   `Future<void> signOut()`: Firebaseからのサインアウトと、Googleサインインからのサインアウトを両方実行します。

### 【重要】Microsoft サインインについて

現在、`signInWithMicrosoft`メソッドと、それに必要な`msal_mobile`パッケージの初期化処理（`initializeMsal`）は**コメントアウトされています。**

これは、`msal_mobile`がDart 3のバージョンと互換性がなく、ビルドエラーを引き起こすためです。

今後の改修で、`firebase_auth`が標準で提供する`OAuthProvider`を利用したWebベースの認証フローへの置き換えが推奨されます。詳細な手順については`docs/auth/ios_auth_setup.md`を参照してください。
'''