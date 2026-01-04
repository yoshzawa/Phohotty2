# Flutterプロジェクトにおける共通部分とOS依存部分の分析

このドキュメントは、Flutterプロジェクトにおける「共通部分（OS非依存）」と「OS依存部分（Android/iOSでの個別設定が必要）」を明確化し、特にiOSで問題が発生した際のチェックリストを提供します。

## 共通部分 (OS非依存)

以下の要素は、OSに関わらず共通のコードと設定で構成されます。

-   **UIレイアウトとビジネスロジック (Dart):**
    -   `lib/` ディレクトリ内にDartで記述されるほとんどのコード。
    -   状態管理、API通信のロジック、UIコンポーネントなど。
-   **Flutterプラグイン (Dart API):**
    -   `firebase_auth`, `google_sign_in`, `google_maps_flutter`, `geolocator`, `path_provider`, `shared_preferences` などのプラグインが提供するDartのAPI。開発者はこれらのAPIを呼び出すだけで、OSごとの差異を意識せずに機能を利用できます。
-   **クラウドサービスの設定:**
    -   FirebaseコンソールやGCP, Azure AD上でのプロジェクト設定。

## OS依存部分 (Android/iOSで個別設定が必要)

以下の要素は、ターゲットプラットフォームごとに固有の設定が必要です。iOSでの不具合は、これらの設定の不備が原因であることが多いです。

### 1. プロジェクト設定ファイル

-   **Android:** `android/app/build.gradle`, `AndroidManifest.xml`, `google-services.json`
-   **iOS:** `ios/Runner.xcworkspace`, `Info.plist`, `GoogleService-Info.plist`, `Podfile`

### 2. 権限 (パーミッション) の設定

-   **対象機能:** 位置情報、カメラ、フォトライブラリ、外部ストレージアクセスなど。
-   **設定場所:**
    -   **Android:** `AndroidManifest.xml`
    -   **iOS:** `Info.plist` (UsageDescriptionの記述が必須)

### 3. APIキーとサービス設定

-   **対象機能:** Google Maps, Googleサインインなど。
-   **設定場所:**
    -   **Android:** `AndroidManifest.xml`
    -   **iOS:** `AppDelegate.swift` (コード内での設定), `Info.plist` (URLスキームなど)

### 4. ファイルとデータの扱い

-   **対象機能:** 画像などのファイル保存。
-   **考慮点:** iCloud/Google Driveへの自動バックアップの要否。これを制御するには、ネイティブ側の設定（iOSのファイル属性設定など）が必要になる場合があります。

### 5. ビルドと互換性の問題

-   **例:** `msal_mobile` のように、特定のネイティブライブラリがOSのバージョンやDartのバージョンと互換性がない場合、ビルドエラーが発生します。この場合、代替ライブラリの検討や、OS固有の修正が必要になります。

---

## 各OSの設定ファイルと評価 (2024/XX/XX時点)

### Android: `android/app/src/main/AndroidManifest.xml`

#### 評価: ✅ **概ね正しい**
-   必要な権限（インターネット、位置情報、メディアアクセス）は宣言されています。
-   Google MapsのAPIキーも設定されています。

### iOS: `ios/Runner/Info.plist`

#### 評価: ⚠️ **設定不備あり**
-   **OK:** フォトライブラリ (`NSPhotoLibraryUsageDescription`) と位置情報 (`NSLocationWhenInUseUsageDescription`) の権限設定は存在します。
-   **OK:** Googleサインイン用のURLスキームも正しく設定されています。
-   **NG:** **カメラ利用の権限 (`NSCameraUsageDescription`) がありません。** 詳細は後述の「権限が必要な理由と該当コード」セクションを参照してください。

### iOS: `ios/Runner/AppDelegate.swift`

#### 評価: ❌ **致命的な設定漏れ**
-   **NG:** **Google MapsのAPIキーが設定されていません。** `google_maps_flutter` プラグインをiOSで動作させるためには、`didFinishLaunchingWithOptions` 内で `GMSServices.provideAPIKey("YOUR_API_KEY")` を呼び出す必要があります。この設定がないため、iOSでは地図が表示されません。

---

## 権限が必要な理由と該当コード

`Info.plist` での権限設定がなぜ必要なのか、具体的なコード上の該当箇所を以下に示します。

### 位置情報権限 (`NSLocation...UsageDescription`)

**必須。** この権限がないと地図機能が正常に動作しません。

-   **ファイル:** `lib/pages/map_page.dart`
-   **パッケージ:** `geolocator`, `google_maps_flutter`

#### 理由1: 権限の要求ダイアログ表示
ユーザーに位置情報利用の許可を求めるために必須です。`Info.plist` に記述した説明文が、このダイアログに表示されます。これが無いとアプリはクラッシュします。
-   **コード:** `lib/pages/map_page.dart` (22行目)
    ```dart
    permission = await Geolocator.requestPermission();
    ```

#### 理由2: 現在地の座標取得
ユーザーの現在地の緯度・経度を取得し、地図をその場所に移動させるために使用します。
-   **コード:** `lib/pages/map_page.dart` (33行目)
    ```dart
    final position = await Geolocator.getCurrentPosition(...);
    ```

#### 理由3: 地図上の現在地マーカー表示
地図上にユーザーの現在地を示す青い点を表示する `myLocationEnabled` 機能を有効にするために必要です。
-   **コード:** `lib/pages/map_page.dart` (55行目)
    ```dart
    body: GoogleMap(
      myLocationEnabled: true, 
      // ...
    ),
    ```

### カメラ権限 (`NSCameraUsageDescription`)

**現在は不要、しかし将来的に推奨。**

-   **ファイル:** `lib/pages/tag_lens_page.dart`
-   **パッケージ:** `image_picker`

#### 理由
現在の実装では、`image_picker` はフォトライブラリから画像を選択するためにのみ使用されています。
-   **コード:** `lib/pages/tag_lens_page.dart` (59行目)
    ```dart
    final picked = await picker.pickImage(source: ImageSource.gallery);
    ```
`ImageSource.camera` を使用するコードはまだありません。しかし、将来「カメラで撮影してタグ付けする」機能を追加する可能性は高く、その際には `NSCameraUsageDescription` の設定が**必須**となります。設定がないままカメラを呼び出すとアプリがクラッシュするため、予防的に追加しておくことを強く推奨します。

---

## 【チェックリスト】iOS版の不具合調査

以上の分析に基づき、チェックリストを更新します。

1.  **`ios/Runner/AppDelegate.swift` の修正:**
    -   [ ] `import GoogleMaps` を追加する。
    -   [ ] `GMSServices.provideAPIKey("YOUR_API_KEY")` を `didFinishLaunchingWithOptions` 内に追加する。
2.  **`ios/Runner/Info.plist` の修正:**
    -   [ ] `<key>NSCameraUsageDescription</key>` と、その説明文を予防的に追加する。
    -   [ ] Googleサインイン用のURLスキーム (`REVERSED_CLIENT_ID`) が正しいか再確認する。
3.  **`ios/Runner/GoogleService-Info.plist` の確認:**
    -   [ ] Firebaseコンソールからダウンロードした最新のものが正しく配置されているか確認する。
4.  **CocoaPods の確認:**
    -   [ ] `ios` ディレクトリで `pod install --repo-update` を実行し、依存関係が正しくインストールされるか確認する。
