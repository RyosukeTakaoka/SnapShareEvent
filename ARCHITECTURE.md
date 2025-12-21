# アーキテクチャ詳細 - Cloudinary統合版

## 🏗️ システムアーキテクチャ

### 技術スタック

```
┌─────────────────────────────────────────┐
│           SwiftUI Views                 │
│  (OnboardingView, MainView, etc.)      │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│          ViewModels (MVVM)              │
│   @Published properties + Business      │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│            Services Layer               │
│  ┌───────────────┬──────────────────┐  │
│  │ Firebase      │   Cloudinary     │  │
│  │ Manager       │   Service        │  │
│  ├───────────────┼──────────────────┤  │
│  │ - Auth        │  - Image Upload  │  │
│  │ - Firestore   │  - CDN Delivery  │  │
│  │ - Metadata    │  - Transform     │  │
│  └───────────────┴──────────────────┘  │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│          External Services              │
│  ┌──────────────┬──────────────────┐   │
│  │   Firebase   │   Cloudinary     │   │
│  │   Backend    │   CDN            │   │
│  └──────────────┴──────────────────┘   │
└─────────────────────────────────────────┘
```

## 📊 データフロー

### 写真アップロードフロー

```
1. ユーザーが写真を撮影
   ↓
2. CameraViewModel: エフェクトを適用
   ↓
3. FirebaseManager.uploadPhoto()
   ↓
4. CloudinaryService.uploadImage()
   ├─ 画像圧縮
   ├─ Cloudinaryにアップロード
   └─ URL取得（画像URL、サムネイルURL）
   ↓
5. FirebaseManager: メタデータをFirestoreに保存
   ├─ Photo document作成
   │   ├─ imageURL (Cloudinary URL)
   │   ├─ thumbnailURL (Cloudinary URL)
   │   ├─ uploaderInfo
   │   └─ metadata
   └─ Group documentの photoCount を更新
   ↓
6. Firestoreリスナーが更新を検知
   ↓
7. MemoryViewModel: 写真一覧を更新
   ↓
8. MemoryView: UIを更新
```

### 写真表示フロー

```
1. MemoryView表示
   ↓
2. MemoryViewModel.loadPhotos()
   ↓
3. FirebaseManager.getPhotos()
   ├─ Firestoreからメタデータ取得
   │   └─ imageURL, thumbnailURL (Cloudinary URLs)
   ↓
4. SDWebImageSwiftUI
   ├─ CloudinaryのCDNから画像をダウンロード
   ├─ キャッシュ
   └─ 表示
```

## 🔄 責任分離

### Firebase（メタデータ管理）

**役割**:
- ユーザー認証（匿名認証）
- グループ管理
- 写真のメタデータ管理
- リアルタイム同期

**データ構造**:

```javascript
// Firestore
users/{userId}
  ├─ name: String
  ├─ icon: String
  └─ createdAt: Timestamp

groups/{groupId}
  ├─ name: String
  ├─ createdBy: String
  ├─ createdAt: Timestamp
  ├─ memberIds: [String]
  └─ photoCount: Number

photos/{photoId}
  ├─ groupId: String
  ├─ uploadedBy: String
  ├─ uploaderName: String
  ├─ uploaderIcon: String
  ├─ imageURL: String (Cloudinary URL)
  ├─ thumbnailURL: String (Cloudinary URL)
  ├─ createdAt: Timestamp
  └─ appliedEffect: String?
```

### Cloudinary（画像ストレージ＆CDN）

**役割**:
- 画像の保存
- 画像の配信（CDN）
- 画像の変換（リサイズ、最適化）
- サムネイル生成

**ファイル構造**:

```
snapshare/
  └─ groups/
      └─ {groupId}/
          ├─ {photoId}
          ├─ {photoId}_thumb (自動生成)
          └─ ...
```

**URL例**:

```
// オリジナル画像
https://res.cloudinary.com/{cloud_name}/image/upload/v1234567890/snapshare/groups/{groupId}/{photoId}.jpg

// サムネイル（URL変換）
https://res.cloudinary.com/{cloud_name}/image/upload/w_200,h_200,c_fill,q_auto/v1234567890/snapshare/groups/{groupId}/{photoId}.jpg
```

## 🎯 なぜFirebase + Cloudinary?

### Firebase Storageを使わない理由

| 項目 | Firebase Storage | Cloudinary |
|------|-----------------|------------|
| CDN配信 | 制限あり | グローバルCDN |
| 画像変換 | なし | URLで自動変換 |
| 最適化 | 手動 | 自動 |
| コスト | 5GB無料 | 25GB無料 |
| 帯域幅 | 1GB/日 | 25GB/月 |
| 管理UI | 基本的 | 高機能 |

### Cloudinaryの利点

1. **高速配信**
   - 世界中のCDNから配信
   - 自動的に最適なサーバーを選択

2. **画像最適化**
   - URLパラメータで自動リサイズ
   - WebP、AVIF対応
   - 品質の自動調整

3. **開発効率**
   - サムネイル生成が不要（URLで変換）
   - 画像処理がサーバー側で完結
   - ダッシュボードで簡単管理

4. **コスト削減**
   - 無料枠が大きい
   - 帯域幅の節約（最適化された画像）

## 🔐 セキュリティ

### 認証フロー

```
1. アプリ起動
   ↓
2. Firebase Anonymous Auth
   ├─ ユーザーID取得
   └─ 認証トークン発行
   ↓
3. Firestore操作
   ├─ セキュリティルールでユーザー検証
   └─ 読み書き権限チェック
   ↓
4. Cloudinary Upload
   ├─ Unsigned Upload Preset使用
   ├─ Public IDはアプリ側で生成
   └─ フォルダ制限（snapshare/groups/）
```

### Firestoreセキュリティルール

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 認証必須
    function isAuthenticated() {
      return request.auth != null;
    }

    // 自分のドキュメントか確認
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // グループメンバーか確認
    function isGroupMember(groupId) {
      return request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.memberIds;
    }

    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }

    match /groups/{groupId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isGroupMember(groupId);
    }

    match /photos/{photoId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow delete: if isOwner(resource.data.uploadedBy);
    }
  }
}
```

### Cloudinary Upload Preset設定

```yaml
Preset Name: snapshare_preset
Signing Mode: Unsigned
Folder: snapshare
Use filename: Yes
Unique filename: No (アプリ側でUUID生成)
Max file size: 10MB
Allowed formats: jpg, png, heic
Auto tagging: Enabled
Backup: Enabled (有料プラン)
```

## 📈 スケーラビリティ

### 現在の構成（MVP）

- **ユーザー数**: 〜1,000人
- **グループ数**: 〜100個
- **写真数**: 〜10,000枚
- **月間アップロード**: 〜1,000枚
- **月間表示**: 〜10,000回

**コスト**: $0（無料枠内）

### スケール時の対応

#### フェーズ1: 〜10,000ユーザー

- Cloudinary: Freeプラン → Plus ($89/月)
- Firebase: Sparkプラン → Blazeプラン（従量課金）
- 推定コスト: $100-150/月

#### フェーズ2: 〜100,000ユーザー

- Cloudinary: Plus → Advanced ($224/月)
- Firebase: 最適化が必要
  - Firestoreクエリの最適化
  - インデックスの追加
  - キャッシング戦略
- 推定コスト: $300-500/月

#### フェーズ3: 100,000+ ユーザー

- Cloudinary: Advanced → Custom
- Firebase:
  - リージョン別シャーディング
  - キャッシュレイヤー追加（Redis）
  - CloudFunctionsで負荷分散
- 推定コスト: $1,000+/月

## 🛠️ 開発者向け情報

### ローカル開発環境

1. **Firebase Emulator（オプション）**
```bash
firebase emulators:start
```

2. **Cloudinary テスト環境**
- 別のCloud Nameを使用
- テスト用Upload Presetを作成

### デバッグ

```swift
// Cloudinaryアップロードのデバッグ
CloudinaryService.shared.uploadImage(image, folder: folder) { progress in
    print("Upload progress: \(progress * 100)%")
}

// Firestoreクエリのデバッグ
db.collection("photos")
    .whereField("groupId", isEqualTo: groupId)
    .addSnapshotListener { snapshot, error in
        print("Snapshot received: \(snapshot?.documents.count ?? 0) documents")
    }
```

### パフォーマンスモニタリング

- Firebase Performance Monitoring
- Cloudinary Analytics Dashboard
- Xcode Instruments

## 📚 参考資料

- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [Cloudinary iOS SDK](https://cloudinary.com/documentation/ios_integration)
- [MVVM in SwiftUI](https://www.swiftbysundell.com/articles/mvvm-in-swift/)
- [Combine Framework](https://developer.apple.com/documentation/combine)

---

**このアーキテクチャは、スケーラビリティ、パフォーマンス、コスト効率を考慮して設計されています。**
