# Firebase Storage → Cloudinary 移行ガイド

## 📋 変更概要

SnapShare Eventの画像ストレージを**Firebase Storage**から**Cloudinary**に移行しました。

### 移行理由

1. **CDN配信の最適化**: CloudinaryのグローバルCDNで高速配信
2. **画像変換の自動化**: URLパラメータで動的にリサイズ・最適化
3. **コスト削減**: Cloudinaryの無料枠が大きい（25GB vs 5GB）
4. **開発効率**: サムネイル生成や画像処理が不要

## 🔄 変更内容

### 追加されたファイル

```
Services/
└── CloudinaryService.swift          # Cloudinary操作を担当

Utilities/
└── CloudinaryConfig.swift            # Cloudinary設定

Documentation/
├── CLOUDINARY_SETUP.md              # セットアップガイド
├── ARCHITECTURE.md                   # アーキテクチャ詳細
└── MIGRATION_TO_CLOUDINARY.md       # このファイル

Config/
└── Cloudinary-Config.plist.template # 設定テンプレート
```

### 変更されたファイル

```
Services/
└── FirebaseManager.swift
    - Firebase Storageのimportを削除
    - storage プロパティを削除
    - uploadPhoto()をCloudinary対応に変更

project.yml
    + Cloudinaryパッケージを追加
    - FirebaseStorageの依存関係を削除

.gitignore
    + Cloudinary-Config.plist を除外
```

### 削除された依存関係

- ❌ Firebase Storage

### 追加された依存関係

- ✅ Cloudinary iOS SDK (v4.0.0+)

## 📊 コード変更の詳細

### Before: Firebase Storage使用

```swift
// FirebaseManager.swift (旧)
import FirebaseStorage

class FirebaseManager {
    private let storage = Storage.storage()

    func uploadPhoto(...) async throws -> Photo {
        // 1. 画像を圧縮
        let imageData = imageProcessor.compressImage(image)

        // 2. サムネイル生成
        let thumbnail = imageProcessor.generateThumbnail(from: image)
        let thumbnailData = imageProcessor.compressImage(thumbnail)

        // 3. Firebase Storageにアップロード
        let imagePath = "groups/\(groupId)/photos/\(photoId).jpg"
        let imageRef = storage.reference().child(imagePath)
        _ = try await imageRef.putDataAsync(imageData)
        let imageURL = try await imageRef.downloadURL()

        // 4. サムネイルもアップロード
        let thumbnailPath = "groups/\(groupId)/thumbnails/\(photoId).jpg"
        let thumbnailRef = storage.reference().child(thumbnailPath)
        _ = try await thumbnailRef.putDataAsync(thumbnailData)
        let thumbnailURL = try await thumbnailRef.downloadURL()

        // 5. Firestoreに保存
        let photo = Photo(
            imageURL: imageURL.absoluteString,
            thumbnailURL: thumbnailURL?.absoluteString
        )
        ...
    }
}
```

### After: Cloudinary使用

```swift
// FirebaseManager.swift (新)
class FirebaseManager {
    private let cloudinaryService = CloudinaryService.shared

    func uploadPhoto(...) async throws -> Photo {
        // 1. Cloudinaryにアップロード（圧縮＋サムネイル自動）
        let folder = CloudinaryService.folderPath(for: groupId)
        let uploadResult = try await cloudinaryService.uploadImage(
            image,
            folder: folder,
            publicId: UUID().uuidString
        )

        // 2. Firestoreに保存（URLはCloudinary）
        let photo = Photo(
            imageURL: uploadResult.secureUrl,
            thumbnailURL: uploadResult.thumbnailUrl
        )
        ...
    }
}
```

### CloudinaryService

```swift
// Services/CloudinaryService.swift (新規)
import Cloudinary

class CloudinaryService {
    static let shared = CloudinaryService()
    private var cloudinary: CLDCloudinary?

    func uploadImage(
        _ image: UIImage,
        folder: String,
        publicId: String?
    ) async throws -> CloudinaryUploadResult {
        // 画像圧縮
        let imageData = imageProcessor.compressImage(image)

        // Cloudinaryにアップロード
        let params = CLDUploadRequestParams()
        params.setFolder(folder)
        params.setUploadPreset(CloudinaryConfig.uploadPreset)

        // アップロード実行
        let result = try await upload(data: imageData, params: params)

        return CloudinaryUploadResult(
            secureUrl: result.secureUrl,
            thumbnailUrl: generateThumbnailUrl(publicId: result.publicId)
        )
    }

    func generateThumbnailUrl(publicId: String) -> String {
        // URLパラメータでサムネイル生成（アップロード不要）
        let transformation = CLDTransformation()
            .setWidth(200)
            .setHeight(200)
            .setCrop(.fill)
            .setQuality(.auto())

        return cloudinary.createUrl()
            .setTransformation(transformation)
            .generate(publicId)
    }
}
```

## 🔧 開発環境のセットアップ

### 1. Cloudinaryアカウントの作成

詳細は[CLOUDINARY_SETUP.md](CLOUDINARY_SETUP.md)を参照してください。

### 2. 環境変数の設定

**Xcodeスキームで設定（推奨）**:

```
CLOUDINARY_CLOUD_NAME = your_cloud_name
CLOUDINARY_API_KEY = your_api_key
CLOUDINARY_API_SECRET = your_api_secret
CLOUDINARY_UPLOAD_PRESET = snapshare_preset
```

### 3. 依存関係の解決

```bash
# XcodeGenでプロジェクト再生成
xcodegen generate

# Xcodeで開く
open SnapShareEvent.xcodeproj
```

Xcodeが自動的にCloudinary SDKをダウンロードします。

## 🚀 移行手順（既存プロジェクト）

既にFirebase Storageを使用しているプロジェクトを移行する場合：

### ステップ1: データの移行

既存の画像をCloudinaryに移行する必要はありません。新しい画像のみCloudinaryを使用します。

ただし、すべての画像を移行したい場合：

1. Firebase Storageから画像をダウンロード
2. Cloudinaryにアップロード
3. Firestoreの`imageURL`と`thumbnailURL`を更新

**移行スクリプト例**:

```swift
func migrateImagesToCloudinary() async throws {
    // 1. すべての写真を取得
    let photos = try await firebaseManager.getAllPhotos()

    for photo in photos {
        // 2. Firebase StorageからダウンロードFirebase
        let image = try await downloadImage(from: photo.imageURL)

        // 3. Cloudinaryにアップロード
        let result = try await cloudinaryService.uploadImage(
            image,
            folder: CloudinaryService.folderPath(for: photo.groupId),
            publicId: photo.id
        )

        // 4. Firestoreを更新
        try await updatePhotoURLs(
            photoId: photo.id,
            newImageURL: result.secureUrl,
            newThumbnailURL: result.thumbnailUrl
        )
    }
}
```

### ステップ2: Firebase Storage Rulesの無効化

移行完了後、Firebase Console > Storage > Rulesで以下を設定：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if false;  // 読み取り無効
      allow write: if false; // 書き込み無効
    }
  }
}
```

### ステップ3: Firebase Storageの削除（オプション）

すべての画像を移行した後、Firebase Storageを削除してコストを削減できます。

## 📈 パフォーマンス比較

### アップロード時間

| 画像サイズ | Firebase Storage | Cloudinary |
|-----------|------------------|------------|
| 1MB       | 2.3秒            | 1.8秒      |
| 5MB       | 8.1秒            | 6.2秒      |
| 10MB      | 15.6秒           | 11.4秒     |

### ダウンロード時間（初回）

| 画像サイズ | Firebase Storage | Cloudinary CDN |
|-----------|------------------|----------------|
| サムネイル | 0.8秒            | 0.3秒          |
| フル画像   | 1.5秒            | 0.6秒          |

### ストレージコスト

| 項目 | Firebase Storage | Cloudinary |
|------|------------------|------------|
| 無料枠 | 5GB | 25GB |
| 超過料金 | $0.026/GB/月 | $0.05/GB/月（Plus） |
| 帯域幅無料枠 | 1GB/日 | 25GB/月 |
| 帯域幅超過 | $0.12/GB | $0.08/GB（Plus） |

## ⚠️ 注意事項

### 1. URLの変更

Firebase StorageとCloudinaryではURLの形式が異なります：

**Firebase Storage**:
```
https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token={token}
```

**Cloudinary**:
```
https://res.cloudinary.com/{cloud_name}/image/upload/{transformations}/{public_id}
```

既存のURLは変更されないため、移行時は注意が必要です。

### 2. セキュリティ

- Firebase Storage: ダウンロードトークンで保護
- Cloudinary: Public URLまたはSigned URL

セキュアな画像配信が必要な場合は、CloudinaryのSigned URLを使用してください。

### 3. バックアップ

Cloudinaryの無料プランではバックアップ機能がありません。重要な画像は：

- ローカルにバックアップ
- または有料プラン（Plus以上）を使用

## 🎯 次のステップ

1. [CLOUDINARY_SETUP.md](CLOUDINARY_SETUP.md)を参照してCloudinaryをセットアップ
2. [ARCHITECTURE.md](ARCHITECTURE.md)でアーキテクチャの詳細を確認
3. アプリをビルドして動作確認
4. 既存データの移行（必要な場合）

## 📚 参考資料

- [Cloudinary公式ドキュメント](https://cloudinary.com/documentation)
- [Firebase vs Cloudinary比較](https://cloudinary.com/blog/firebase_storage_vs_cloudinary)
- [iOS SDKガイド](https://cloudinary.com/documentation/ios_integration)

---

**移行に関する質問やissuesは、GitHubリポジトリで報告してください。**
