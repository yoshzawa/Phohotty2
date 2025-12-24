# `lib`ディレクトリのドキュメント

このドキュメントは`lib`ディレクトリ内のファイルとその機能の概要をまとめたものです。

**重要:** `lib`ディレクトリ内の`.dart`ファイルを修正した場合は、必ず対応する`docs/lib`内のMarkdownドキュメントも更新してください。これにより、コードとドキュメントの同期が保たれ、プロジェクトの保守性が向上します。

## ファイル構成

```
lib
├── main.dart
├── firebase_options.dart
├── pages
│   ├── album_page.dart
│   ├── auth_page.dart
│   ├── gallery_page.dart
│   ├── home_page.dart
│   ├── main_tab_page.dart
│   ├── map_page.dart
│   ├── settings_page.dart
│   ├── sns_page.dart
│   ├── tag_lens_page.dart
│   └── user_create_page.dart
├── services
│   ├── fb_auth.dart
│   ├── google_vision.dart
│   └── local_storage.dart
└── widgets
    └── tag_chip.dart
```

## ファイル概要

*   [`main.dart`](main.md): アプリケーションのエントリーポイント。Firebaseの初期化、写真ライブラリへの権限要求、認証状態に応じた画面遷移（認証ページまたはメインタブページ）を行います。
*   [`firebase_options.dart`](#): Firebaseのプラットフォーム別設定ファイル（自動生成）。
*   [`pages/album_page.dart`](album_page.md): 特定のアルバム内の写真一覧を表示するページ。
*   [`pages/auth_page.dart`](auth_page.md): メール/パスワード、Google、Microsoftアカウントによるサインイン・新規登録を行う認証ページ。
*   [`pages/gallery_page.dart`](gallery_page.md): デバイスのフォトギャラリー全体を表示し、アルバムへのアクセスも提供するページ。
*   [`pages/home_page.dart`](home_page.md): アプリケーションのメインページ。現在はプレースホルダー的な内容。
*   [`pages/main_tab_page.dart`](main_tab_page.md): `HomePage`, `GalleryPage`, `MapPage` などを切り替えるための下部ナビゲーションタブを持つメインページ。
*   [`pages/map_page.dart`](map_page.md): 写真が撮影された位置情報を地図上に表示するページ。
*   [`pages/settings_page.dart`](settings_page.md): ユーザー設定（例: ログアウト）を行うページ。
*   [`pages/sns_page.dart`](sns_page.md): SNS連携機能用のページ（現在未使用または開発中）。
*   [`pages/tag_lens_page.dart`](tag_lens_page.md): 写真に写っているものをAI（Google Vision）で解析し、タグを提案・表示するページ。
*   [`pages/user_create_page.dart`](user_create_page.md): 新規ユーザー登録ページ（`AuthPage`に統合されたため、現在直接は使用されていない可能性あり）。
*   [`services/fb_auth.dart`](fb_auth.md): Firebase Authenticationに関するロジック（サインイン、サインアウト、ユーザー状態の監視など）をまとめたサービスクラス。
*   [`services/google_vision.dart`](google_vision.md): Google Cloud Vision APIと連携し、画像からラベル情報を取得するためのサービスクラス。
*   [`services/local_storage.dart`](local_storage.md): Shared Preferencesを利用して、キーバリュー形式でデータを永続化するためのサービスクラス。
*   [`widgets/tag_chip.dart`](tag_chip.md): 写真に付与されたタグをスタイリッシュに表示するためのカスタムUIウィジェット。
