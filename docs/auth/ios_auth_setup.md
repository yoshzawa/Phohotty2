'''
# iOS: Google & Microsoft サインイン設定ガイド

このドキュメントは、FlutterアプリケーションでFirebase Authenticationを使用し、iOSプラットフォームでGoogleサインインおよびMicrosoftサインインを実装するための設定手順を解説します。

## 1. 必要なライブラリ

まず、`pubspec.yaml`に必要なライブラリを追加します。

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.30.0
  firebase_auth: ^4.19.0

  # Googleサインイン
  google_sign_in: ^6.2.1
```

**【重要】Microsoftサインインについて**

以前のバージョンでは`msal_mobile`ライブラリを使用していましたが、Dart 3との互換性問題によりビルドエラーが発生します。そのため、現在は`firebase_auth`が標準で提供する`OAuthProvider`を利用したWebベースの認証フローに移行します。これにより、Microsoft認証専用の追加ライブラリは不要になります。


## 2. クラウドプラットフォームでの設定

Firebaseでの認証を有効にする前に、各クラウドプロバイダーのコンソールでアプリケーションの登録と設定が必要です。

### Google Cloud Platform (GCP) の設定

通常、FirebaseでGoogleサインインを有効にすると、必要なGCPプロジェクトの構成（OAuthクライアントIDの作成など）は自動的に行われます。手動で確認・設定する場合は以下の手順を参考にしてください。

1.  **Google Cloud Console**にアクセスし、Firebaseプロジェクトと同じプロジェクトを選択します。
2.  **APIとサービス** > **認証情報** に移動します。
3.  **OAuth 2.0 クライアント ID** のリストに、Firebaseによって自動作成されたiOS用のクライアントIDが存在することを確認します。（もし存在しない場合は、`+ 認証情報を作成` > `OAuthクライアントID` から `iOS アプリケーション` を選択して作成します。）
4.  **APIとサービス** > **OAuth 同意画面** に移動し、アプリ名、サポートメール、ロゴなどの情報を設定します。これはユーザーがGoogleサインインを行う際に表示される画面です。

### Microsoft Azure Active Directory (Azure AD) の設定

Microsoftサインインでは、手動でのアプリ登録が必須です。

1.  **Microsoft Azure Portal**にアクセスし、**Azure Active Directory**に移動します。
2.  **アプリの登録** > **新規登録** を選択します。
3.  アプリケーションに名前を付け（例: `Phototty-Firebase-Auth`）、サポートされているアカウントの種類を選択します（通常は「任意の組織ディレクトリ内のアカウントおよび個人用のMicrosoftアカウント」）。
4.  リダイレクトURIのプラットフォームとして **Web** を選択します。URIの入力フィールドは、**次のセクション（Firebaseの設定）で取得するURLを設定するため、一旦空のまま**で登録します。
5.  登録後、アプリケーションの概要ページに表示される**アプリケーション（クライアント）ID**をコピーします。これがFirebaseで必要になるクライアントIDです。
6.  **証明書とシークレット** > **新しいクライアントシークレット** をクリックし、説明を入力してクライアントシークレットを作成します。**【重要】生成されたシークレットの値は一度しか表示されないため、必ず安全な場所にコピーしてください。**

## 3. Firebase プロジェクトの設定

1.  **Firebaseコンソール**にアクセスし、対象のプロジェクトを選択します。
2.  **Authentication** > **Sign-in method** に移動します。
3.  **Google**を有効にします。プロジェクトのサポートメールを設定してください。
4.  **Microsoft**を有効にします。ここで、前の手順でAzure ADから取得した**クライアントID**と**クライアントシークレット**を貼り付けます。
5.  設定を保存すると、FirebaseがリダイレクトURIを生成します。このURIをコピーします。
6.  再び**Azure Portal**に戻り、先ほど登録したアプリの **認証** > **プラットフォームを追加** > **Web** を選択し、コピーしたFirebaseのリダイレクトURIを貼り付けて保存します。

## 4. iOS固有の設定

### Googleサインインの設定

1.  Firebaseプロジェクトから`GoogleService-Info.plist`ファイルをダウンロードし、Xcodeプロジェクトの`Runner/`ディレクトリに追加します。
2.  Xcodeで`Runner.xcworkspace`を開きます。
3.  `Runner`ターゲットを選択し、**Info**タブを開きます。
4.  **URL Types**のセクションを展開し、`+`ボタンをクリックして新しいURLスキームを追加します。
5.  `GoogleService-Info.plist`ファイル内にある`REVERSED_CLIENT_ID`の値をコピーし、Xcodeの`URL Schemes`の入力フィールドにペーストします。

### Microsoftサインインの設定

`OAuthProvider`を使用する場合、認証はWebビューで行われるため、**アプリ側での特別なURLスキームの追加は不要です。**


## 5. Flutterコードの実装

以下は、`fb_auth.dart`などに実装する際の概念的なコード例です。

### Googleサインインの実装

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FbAuth {
  // ...

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // キャンセルされた場合

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user;
  }

  // ...
}
```

### Microsoftサインインの実装

```dart
import 'package:firebase_auth/firebase_auth.dart';

class FbAuth {
  // ...

  Future<User?> signInWithMicrosoft() async {
    final OAuthProvider provider = OAuthProvider("microsoft.com");

    // (オプション)特定のテナントを指定する場合
    // provider.setCustomParameters({
    //   "tenant": "YOUR_TENANT_ID",
    // });

    final UserCredential userCredential = await FirebaseAuth.instance.signInWithProvider(provider);
    return userCredential.user;
  }

  // ...
}
```

以上で、iOSアプリでのGoogleおよびMicrosoftサインインの実装が可能です。
'''