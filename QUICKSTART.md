# SnapShare Event - クイックスタート

このガイドでは、SnapShare Eventアプリを最速でセットアップして実行する方法を説明します。

## 🚀 5分でセットアップ

### 1. 前提条件

- macOS 13.0以上
- Xcode 15.0以上
- Homebrew（XcodeGenインストール用）
- Firebaseアカウント（無料）

### 2. XcodeGenのインストール

```bash
brew install xcodegen
```

### 3. Firebase プロジェクトの作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名を入力（例：SnapShare Event）
4. Google アナリティクスは任意（スキップ可）
5. プロジェクトを作成

### 4. iOS アプリの追加

1. Firebase プロジェクトの概要で「iOS」アイコンをクリック
2. 以下の情報を入力：
   - **iOS バンドル ID**: `com.snapshare.event`
   - **アプリのニックネーム**: SnapShare Event（任意）
   - **App Store ID**: 空欄でOK
3. 「アプリを登録」をクリック
4. **GoogleService-Info.plist** をダウンロード
5. ダウンロードしたファイルを `SnapShareEvent` ディレクトリにコピー

```bash
# ダウンロードフォルダから移動する場合
cp ~/Downloads/GoogleService-Info.plist /Users/ryosuke/SnapShareEvent/
```

### 5. Firebase サービスの有効化

#### Authentication（認証）
1. Firebase Console > Authentication
2. 「始める」をクリック
3. 「匿名」を選択して有効化

#### Firestore Database
1. Firebase Console > Firestore Database
2. 「データベースの作成」をクリック
3. 「本番環境モードで開始」を選択
4. ロケーション: `asia-northeast1`（東京）推奨
5. 「ルール」タブで以下のルールを設定：

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

#### Storage
1. Firebase Console > Storage
2. 「始める」をクリック
3. セキュリティルールはデフォルトでOK
4. ロケーション: `asia-northeast1`（東京）推奨
5. 「ルール」タブで以下のルールを設定：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /groups/{groupId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### 6. プロジェクトのセットアップ

```bash
cd /Users/ryosuke/SnapShareEvent
./setup.sh
```

### 7. Xcodeでプロジェクトを開く

```bash
open SnapShareEvent.xcodeproj
```

### 8. 開発チームの設定

1. Xcodeでプロジェクトを選択
2. 「Signing & Capabilities」タブを選択
3. 「Team」ドロップダウンから自分のApple IDを選択
4. 自動署名が有効になっていることを確認

### 9. ビルドして実行

1. シミュレータを選択（iPhone 15 Pro推奨）
2. `⌘ + R` でビルド＆実行
3. 初回起動時はビルドに時間がかかります（依存関係のダウンロード）

---

## ✅ 動作確認

アプリが起動したら、以下を試してください：

1. **オンボーディング**
   - 名前を入力
   - アイコン（絵文字）を選択
   - 「はじめる」をタップ

2. **グループ作成**
   - 右上の「+」アイコンをタップ
   - グループ名を入力（例：家族旅行）
   - 「作成」をタップ

3. **QRコード表示**
   - 作成したグループをロングプレス
   - 「QRコードを表示」を選択
   - QRコードが表示されます

4. **写真撮影**
   - グループをタップ
   - 「写真を撮る」をタップ
   - カメラで写真を撮影
   - エフェクトを選択
   - 「アップロード」をタップ

5. **メモリー表示**
   - グループをタップ
   - 「メモリーを見る」をタップ
   - アップロードした写真が表示されます

---

## 🐛 トラブルシューティング

### ビルドエラー: "GoogleService-Info.plist not found"
- GoogleService-Info.plistがプロジェクトディレクトリにあることを確認
- Xcodeでプロジェクトを再読み込み

### ビルドエラー: "No such module 'Firebase'"
- Xcodeメニュー > File > Packages > Resolve Package Versions
- ビルドを再試行

### カメラが起動しない
- シミュレータではカメラは動作しません
- 実機デバイスでテストしてください

### 写真がアップロードされない
- Firebase Console > Storage が有効化されているか確認
- ネットワーク接続を確認
- Xcodeのコンソールでエラーメッセージを確認

### 認証エラー
- Firebase Console > Authentication > 匿名認証が有効か確認
- GoogleService-Info.plistが正しいか確認

---

## 📱 実機でテスト

1. iPhoneをMacに接続
2. Xcodeでデバイスを選択
3. 「Signing & Capabilities」で開発チームを設定
4. `⌘ + R` でビルド＆実行
5. iPhone上で「設定 > 一般 > VPNとデバイス管理」から開発者を信頼

---

## 🎯 次のステップ

- [README.md](README.md)で詳細な機能説明を確認
- Firebase Consoleでデータベースの内容を確認
- 複数のデバイスでQRコード共有を試す
- Instagram共有機能を追加（今後の拡張）

---

## 💡 ヒント

- **12時間ルール**: グループ作成から12時間経過するとQRコードが無効になります
- **リアルタイム同期**: 複数のデバイスで同じグループを開くと、写真が即座に同期されます
- **エフェクト**: 撮影後にエフェクトを変更できます
- **データ管理**: Firebase Consoleから直接データを確認・削除できます

---

**サポートが必要な場合は、README.mdの詳細ドキュメントを参照してください。**
