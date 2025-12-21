# Cloudinary セットアップガイド

SnapShare Eventでは、画像の保存とCDN配信にCloudinaryを使用しています。このガイドでは、Cloudinaryのセットアップ手順を説明します。

## 📋 なぜCloudinary?

- **高速配信**: 世界中のCDNから画像を配信
- **画像変換**: URLパラメータで自動リサイズ・最適化
- **コスト削減**: 無料枠が充実（25GB/月、25GB帯域幅/月）
- **簡単管理**: ダッシュボードで全画像を管理

## 🚀 セットアップ手順

### 1. Cloudinaryアカウントの作成

1. [Cloudinary](https://cloudinary.com/) にアクセス
2. 「Sign Up for Free」をクリック
3. メールアドレス、パスワードを入力して登録
4. メール認証を完了

### 2. Cloud Nameなど認証情報の取得

1. Cloudinaryダッシュボードにログイン
2. 左上の「Dashboard」をクリック
3. 以下の情報をメモ：
   - **Cloud Name**: あなたのクラウド名（例：`dxyz1234`）
   - **API Key**: APIキー（例：`123456789012345`）
   - **API Secret**: APIシークレット（例：`abcdefghijklmnopqrstuvwxyz123`）

### 3. Upload Presetの作成

Upload Presetを作成することで、クライアントから直接画像をアップロードできます（Unsigned Upload）。

1. Cloudinaryダッシュボードで「Settings」（⚙️）をクリック
2. 「Upload」タブを選択
3. 「Upload presets」セクションまでスクロール
4. 「Add upload preset」をクリック
5. 以下の設定を行う：
   - **Preset name**: `snapshare_preset`（任意の名前）
   - **Signing Mode**: 「Unsigned」を選択
   - **Folder**: `snapshare`（オプション）
   - **Use filename or externally defined Public ID**: ON
   - **Unique filename**: OFF（Public IDを使用するため）
6. 「Save」をクリック

### 4. 環境変数の設定（推奨）

#### macOS / Xcode

環境変数を使用することで、認証情報をコードにハードコーディングせずに管理できます。

**方法1: Xcodeスキームで設定**

1. Xcode > Product > Scheme > Edit Scheme...
2. 「Run」を選択
3. 「Arguments」タブをクリック
4. 「Environment Variables」セクションで「+」をクリック
5. 以下の環境変数を追加：

```
CLOUDINARY_CLOUD_NAME = your_cloud_name
CLOUDINARY_API_KEY = your_api_key
CLOUDINARY_API_SECRET = your_api_secret
CLOUDINARY_UPLOAD_PRESET = snapshare_preset
```

**方法2: .envファイルを使用（開発時のみ）**

プロジェクトルートに`.env`ファイルを作成：

```bash
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CLOUDINARY_UPLOAD_PRESET=snapshare_preset
```

注意: `.env`ファイルは`.gitignore`に追加してください。

**方法3: Cloudinary-Config.plistを使用**

1. `Cloudinary-Config.plist.template`をコピーして`Cloudinary-Config.plist`を作成

```bash
cp Cloudinary-Config.plist.template Cloudinary-Config.plist
```

2. `Cloudinary-Config.plist`を編集して、実際の値を設定

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CLOUDINARY_CLOUD_NAME</key>
    <string>your_cloud_name</string>

    <key>CLOUDINARY_API_KEY</key>
    <string>your_api_key</string>

    <key>CLOUDINARY_API_SECRET</key>
    <string>your_api_secret</string>

    <key>CLOUDINARY_UPLOAD_PRESET</key>
    <string>snapshare_preset</string>
</dict>
</plist>
```

3. Xcodeプロジェクトに`Cloudinary-Config.plist`を追加（ドラッグ&ドロップ）

**重要**: このファイルは`.gitignore`に追加されているため、コミットされません。

### 5. CloudinaryConfig.swiftの更新（オプション）

環境変数を使用しない場合は、`CloudinaryConfig.swift`を直接編集できます（非推奨）。

```swift
struct CloudinaryConfig {
    static let cloudName = "your_cloud_name"
    static let apiKey = "your_api_key"
    static let apiSecret = "your_api_secret"
    static let uploadPreset = "snapshare_preset"
}
```

**警告**: この方法は開発時のみ使用し、本番環境では環境変数を使用してください。

## ✅ 動作確認

1. Xcodeでプロジェクトをビルド＆実行
2. オンボーディングを完了
3. グループを作成
4. カメラで写真を撮影
5. アップロードをタップ
6. Cloudinaryダッシュボードで画像が表示されることを確認

### 画像の確認方法

1. Cloudinaryダッシュボード > Media Library
2. `snapshare/groups/` フォルダに画像が保存されている
3. 画像をクリックして詳細を確認

## 🔧 トラブルシューティング

### エラー: "Cloudinaryが設定されていません"

- 環境変数が正しく設定されているか確認
- Xcodeスキームの環境変数を確認
- `CloudinaryConfig.isConfigured`がtrueを返すか確認

### エラー: "Upload failed: Unauthorized"

- API KeyとAPI Secretが正しいか確認
- Upload Presetが「Unsigned」モードになっているか確認
- Upload Preset名が正しいか確認

### エラー: "Upload failed: Invalid signature"

- API Secretが正しいか確認
- Upload PresetのSigning Modeが「Unsigned」になっているか確認

### 画像がアップロードされない

- ネットワーク接続を確認
- Cloudinaryダッシュボードでアカウントの状態を確認
- Xcodeのコンソールでエラーメッセージを確認

## 📊 無料枠の制限

Cloudinaryの無料プランでは以下の制限があります：

- **ストレージ**: 25GB
- **帯域幅**: 25GB/月
- **変換**: 25クレジット/月
- **画像数**: 無制限

MVPとしては十分ですが、本番環境では必要に応じて有料プランへのアップグレードを検討してください。

## 🎯 Cloudinaryの活用

### 画像変換の例

CloudinaryのURLパラメータを使用して、様々な画像変換が可能です：

```swift
// サムネイル生成（200x200、クロップ）
let thumbnailUrl = cloudinaryService.generateThumbnailUrl(publicId: "photo_id")

// 幅800pxにリサイズ
let resizedUrl = cloudinaryService.generateOptimizedUrl(publicId: "photo_id", width: 800)

// 品質自動調整
let optimizedUrl = cloudinaryService.generateOptimizedUrl(publicId: "photo_id", quality: "auto")
```

### ダッシュボードでの操作

- **画像の検索**: タグやフォルダで検索
- **画像の削除**: 不要な画像を削除
- **使用状況の確認**: ストレージと帯域幅の使用状況を確認
- **URL生成**: 変換パラメータを指定してURLを生成

## 🔐 セキュリティ

### 本番環境での注意事項

1. **API Secretの保護**
   - コードにハードコーディングしない
   - 環境変数を使用する
   - Gitにコミットしない

2. **Upload Presetの設定**
   - Unsigned Uploadを使用（クライアントから直接アップロード）
   - フォルダを制限（`snapshare/`のみ）
   - ファイルサイズを制限

3. **アクセス制御**
   - 必要に応じてSigned URLを使用
   - Rate limitingを設定

## 📚 参考リンク

- [Cloudinary公式ドキュメント](https://cloudinary.com/documentation)
- [iOS SDKドキュメント](https://cloudinary.com/documentation/ios_integration)
- [Upload Presetsガイド](https://cloudinary.com/documentation/upload_presets)
- [画像変換リファレンス](https://cloudinary.com/documentation/image_transformations)

---

**セットアップが完了したら、[QUICKSTART.md](QUICKSTART.md)に戻ってアプリの動作確認を行ってください。**
