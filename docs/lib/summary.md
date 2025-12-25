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

このセクションでは、`lib`ディレクトリ内の主要なファイルについて、その目的と機能の概要を説明します。詳細は各ファイルへのリンク先ドキュメントを参照してください。

- **[`main.dart`](main.md)**: アプリケーションの**エントリーポイント**です。各種サービスの初期化、認証状態の監視を行い、ユーザーがログインしているかどうかに応じて適切な初期画面（`AuthPage`または`MainTabPage`）を表示します。

- **[`pages/settings_page.dart`](settings_page.md)**: **設定画面**です。現在はプレースホルダーですが、将来的には通知設定などの機能が実装される予定です。

*(ここに他のファイルの概要を追記していきます)*
