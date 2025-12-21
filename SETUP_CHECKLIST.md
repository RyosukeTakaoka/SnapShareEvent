# セットアップチェックリスト

このチェックリストに従って、SnapShare Eventアプリを正しくセットアップしてください。

## 📋 事前準備

- [ ] macOS 13.0以上
- [ ] Xcode 15.0以上
- [ ] Homebrewインストール済み
- [ ] Firebaseアカウント（無料）
- [ ] Cloudinaryアカウント（無料）

## 🔧 セットアップ手順

### 1. XcodeGenのインストール

```bash
brew install xcodegen
```

- [ ] XcodeGenインストール完了

### 2. Firebase設定

#### 2.1 Firebaseプロジェクト作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名: `SnapShare Event`（任意）
4. Google アナリティクス: オフでOK
5. プロジェクト作成

- [ ] Firebaseプロジェクト作成完了

#### 2.2 iOSアプリ追加

1. プロジェクト概要 > iOSアイコンをクリック
2. **Bundle ID**: `com.snapshare.event`
3. アプリ登録
4. **GoogleService-Info.plist** をダウンロード
5. プロジェクトルートに配置

```bash
# ダウンロードフォルダから移動
cp ~/Downloads/GoogleService-Info.plist /Users/ryosuke/SnapShareEvent/
```

- [ ] GoogleService-Info.plist配置完了

#### 2.3 Firebase Authentication有効化

1. Firebase Console > Authentication
2. 「始める」をクリック
3. 「匿名」を選択
4. 有効化

- [ ] 匿名認証有効化完了

#### 2.4 Firestore Database作成

1. Firebase Console > Firestore Database
2. 「データベースの作成」
3. **本番環境モード**を選択
4. ロケーション: `asia-northeast1`（東京）
5. 作成完了

- [ ] Firestore Database作成完了

#### 2.5 Firestoreセキュリティルール設定

「ルール」タブで以下を設定:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /groups/{groupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid in resource.data.memberIds;
    }
    match /photos/{photoId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth.uid == resource.data.uploadedBy;
    }
  }
}
```

- [ ] Firestoreセキュリティルール設定完了

### 3. Cloudinary設定

#### 3.1 Cloudinaryアカウント作成

1. [Cloudinary](https://cloudinary.com/) にアクセス
2. 「Sign Up for Free」
3. メール認証完了

- [ ] Cloudinaryアカウント作成完了

#### 3.2 認証情報取得

Dashboardから以下をメモ:

- **Cloud Name**: `_____________`
- **API Key**: `_____________`
- **API Secret**: `_____________`

- [ ] Cloudinary認証情報取得完了

#### 3.3 Upload Preset作成

1. Settings（⚙️）> Upload > Upload presets
2. 「Add upload preset」
3. 設定:
   - **Preset name**: `snapshare_preset`
   - **Signing Mode**: **Unsigned**
   - **Folder**: `snapshare`（任意）
   - **Use filename**: ON
   - **Unique filename**: OFF
4. Save

- [ ] Upload Preset作成完了

### 4. プロジェクトセットアップ

#### 4.1 セットアップスクリプト実行

```bash
cd /Users/ryosuke/SnapShareEvent
./setup.sh
```

- [ ] セットアップスクリプト実行完了

#### 4.2 Xcodeで開く

```bash
open SnapShareEvent.xcodeproj
```

- [ ] Xcodeプロジェクト起動完了

#### 4.3 開発チーム設定

1. プロジェクトナビゲータでプロジェクトを選択
2. Signing & Capabilities
3. Team: 自分のApple IDを選択
4. Automatically manage signing: ON

- [ ] 開発チーム設定完了

#### 4.4 Cloudinary環境変数設定

1. Xcode > Product > Scheme > Edit Scheme...
2. Run > Arguments タブ
3. Environment Variables で「+」をクリック
4. 以下を追加:

| Name | Value |
|------|-------|
| CLOUDINARY_CLOUD_NAME | あなたのCloud Name |
| CLOUDINARY_API_KEY | あなたのAPI Key |
| CLOUDINARY_API_SECRET | あなたのAPI Secret |
| CLOUDINARY_UPLOAD_PRESET | snapshare_preset |

- [ ] Cloudinary環境変数設定完了

### 5. 依存関係の解決

1. Xcodeメニュー > File > Packages > Resolve Package Versions
2. パッケージのダウンロードを待つ（初回は数分かかる）

依存関係:
- ✅ Firebase (Auth, Firestore)
- ✅ Cloudinary
- ✅ SDWebImageSwiftUI

- [ ] 依存関係解決完了

### 6. ビルド＆実行

1. シミュレータを選択（iPhone 15 Pro推奨）
2. `⌘ + R` でビルド＆実行
3. 初回ビルドは5-10分かかる場合があります

- [ ] ビルド成功
- [ ] アプリ起動成功

### 7. 動作確認

#### 7.1 オンボーディング

- [ ] 名前入力できる
- [ ] アイコン選択できる
- [ ] 「はじめる」でメイン画面に遷移

#### 7.2 グループ作成

- [ ] 右上「+」でグループ作成
- [ ] グループ名入力
- [ ] グループが一覧に表示される

#### 7.3 QRコード表示

- [ ] グループをロングプレス
- [ ] 「QRコードを表示」選択
- [ ] QRコードが表示される
- [ ] 有効期限が表示される

#### 7.4 写真撮影（実機のみ）

- [ ] グループをタップ
- [ ] 「写真を撮る」をタップ
- [ ] カメラが起動
- [ ] 写真撮影
- [ ] エフェクト選択
- [ ] アップロード成功

#### 7.5 メモリー表示

- [ ] グループをタップ
- [ ] 「メモリーを見る」をタップ
- [ ] アップロードした写真が表示される

#### 7.6 Cloudinary確認

1. Cloudinary Dashboard > Media Library
2. `snapshare/groups/` フォルダに画像がある

- [ ] Cloudinaryに画像がアップロードされている

#### 7.7 Firebase確認

1. Firebase Console > Firestore Database
2. コレクション確認:
   - users/
   - groups/
   - photos/

- [ ] Firestoreにデータが保存されている

## ✅ セットアップ完了！

すべてのチェックが完了したら、アプリの使用準備が整いました。

## 🐛 トラブルシューティング

### ビルドエラー

#### "GoogleService-Info.plist not found"
- GoogleService-Info.plistがプロジェクトルートにあるか確認
- Xcodeでプロジェクトを再読み込み

#### "No such module 'Firebase'"
- File > Packages > Resolve Package Versions
- ビルドを再試行

#### "No such module 'Cloudinary'"
- File > Packages > Resolve Package Versions
- ビルドを再試行

### 実行時エラー

#### "Cloudinaryが設定されていません"
- Xcodeスキームの環境変数を確認
- 値が正しいか確認

#### "Upload failed: Unauthorized"
- API KeyとAPI Secretが正しいか確認
- Upload Presetが「Unsigned」か確認

#### "Firebase authentication failed"
- GoogleService-Info.plistが正しいか確認
- Firebase Consoleで匿名認証が有効か確認

## 📚 次のステップ

- [ ] 複数デバイスでQRコード共有を試す
- [ ] 写真のエフェクトを試す
- [ ] メモリー機能を活用する
- [ ] ドキュメントを読む
  - README.md
  - ARCHITECTURE.md
  - CLOUDINARY_SETUP.md

---

**セットアップが完了したら、アプリを楽しんでください！🎉**
