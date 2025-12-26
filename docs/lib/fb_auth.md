# `fb_auth.dart` - Firebase認証サービス

`fb_auth.dart`は、Firebase Authenticationを利用したユーザー認証機能を一元管理するシングルトンクラス`FbAuth`を提供します。

## 主な機能

- **ユーザー認証状態の監視:**
  - `authStateChanges`ストリームを通じて、ユーザーのログイン状態（サインイン、サインアウト）の変更をリアルタイムで監視します。

- **多様なサインイン方法:**
  - **Googleサインイン:** `signInWithGoogle()`メソッドにより、ユーザーはGoogleアカウントを使用してアプリにサインインできます。
  - **Microsoftサインイン:** `signInWithMicrosoft()`メソッドにより、ユーザーはMicrosoftアカウント（Azure Active Directory）を使用してアプリにサインインできます。この機能は`msal_mobile`ライブラリを利用して実装されています。

- **サインアウト:**
  - `signOut()`メソッドは、Firebaseからのサインアウトと、GoogleやMicrosoftなど連携しているプロバイダからのサインアウトを両方行います。

- **ユーザー情報の取得:**
  - `currentUser`ゲッターを通じて、現在ログインしているユーザーの情報を`FbUser`オブジェクトとして取得できます。

## `FbUser`クラス

`FbUser`は、Firebaseの`User`オブジェクトをラップし、アプリケーションで使いやすいように整形したカスタムクラスです。以下の情報を含みます。

- `uid`: ユーザーの一意なID
- `displayName`: 表示名
- `email`: メールアドレス
- `photoUrl`: プロフィール写真のURL
- `providers`: 認証に使用されたプロバイダのリスト（例: `google.com`, `microsoft.com`）

## Microsoftサインインの実装詳細

Microsoftサインインは、OAuth 2.0認証フローを`msal_mobile`ライブラリを使用して実装しています。

1.  **初期化:** アプリ起動時に`main.dart`から`initializeMsal()`が呼び出され、クライアントIDやリダイレクトURIなどの設定を持つ`PublicClientApplication`が初期化されます。

2.  **トークン取得:** `signInWithMicrosoft()`が呼び出されると、`acquireToken()`メソッドが実行され、ユーザーにMicrosoftの認証画面が表示されます。認証に成功すると、アクセストークンが返されます。

3.  **Firebaseへの連携:** 取得したアクセストークンを使って`OAuthProvider`のクレデンシャル（資格情報）を作成し、`FirebaseAuth.instance.signInWithCredential()`を呼び出すことでFirebaseへのサインインを実現します。

## 注意事項

- **クライアントIDの設定:** Microsoftサインインを正しく機能させるには、Azure ADで発行されたクライアントIDを`fb_auth.dart`内の`_clientId`定数と、iOSプロジェクトの`Info.plist`に正しく設定する必要があります。
