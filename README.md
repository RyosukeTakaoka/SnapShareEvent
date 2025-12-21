# SnapShare Event

特定のイベント（旅行や結婚式）で、その場にいるメンバーとQRコードを通じて即座に写真をリアルタイム共有するiOSアプリのMVP実装。

## 📱 主な機能

### 1. オンボーディング
- 初回起動時にユーザー名とアイコン（絵文字）を設定
- 匿名認証を使用した簡単なサインアップ
- UserDefaultsへのユーザー情報保存

### 2. グループ管理（12時間ルール）
- グループの作成と参加
- 作成から12時間以内のQRコード表示
- QRコードスキャンによるグループ参加
- グループメンバーと写真数の表示

### 3. リアルタイムカメラ & 写真共有
- カスタムカメラUI実装
- 写真エフェクト機能（セピア、モノクロ、鮮やか、ビンテージ）
- Firebase Storageへの自動アップロード
- グループメンバー全員へのリアルタイム共有

### 4. メモリー機能
- 日付ごとの写真表示
- 写真詳細ビュー
- グループ統計情報（写真数、日数、メンバー数）

## 🏗️ アーキテクチャ

### 技術スタック
- **言語**: Swift
- **UI Framework**: SwiftUI
- **アーキテクチャ**: MVVM
- **バックエンド**: Firebase (Firestore, Storage, Authentication)
- **QRコード**: CoreImage (生成) & AVFoundation (スキャン)
- **画像処理**: Core Image

### プロジェクト構造

```
SnapShareEvent/
├── SnapShareEventApp.swift     # アプリケーションエントリーポイント
├── Models/                     # データモデル
│   ├── User.swift
│   ├── Group.swift
│   └── Photo.swift
├── Services/                   # ビジネスロジック層
│   ├── FirebaseManager.swift   # Firebase操作
│   ├── CameraService.swift     # カメラ制御
│   ├── QRCodeService.swift     # QRコード生成/スキャン
│   └── ImageProcessor.swift    # 画像処理
├── ViewModels/                 # ViewModel層
│   ├── OnboardingViewModel.swift
│   ├── MainViewModel.swift
│   ├── CameraViewModel.swift
│   └── MemoryViewModel.swift
├── Views/                      # UI層
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   ├── Main/
│   │   ├── MainView.swift
│   │   └── QRCodeView.swift
│   ├── Camera/
│   │   ├── CameraView.swift
│   │   └── CameraPreview.swift
│   └── Memory/
│       └── MemoryView.swift
├── Utilities/                  # ユーティリティ
│   ├── Constants.swift
│   └── UserDefaultsKeys.swift
├── Info.plist                  # アプリ設定
└── GoogleService-Info.plist    # Firebase設定（要追加）
```

## 🚀 セットアップ手順

### 1. 必要な環境
- Xcode 15.0以上
- iOS 16.0以上
- CocoaPodsまたはSwift Package Manager

### 2. Firebase設定

1. [Firebase Console](https://console.firebase.google.com/)でプロジェクトを作成
2. iOSアプリを追加（Bundle IDを設定）
3. `GoogleService-Info.plist`をダウンロード
4. プロジェクトのルートディレクトリに配置

### 3. Firebaseセキュリティルール

**Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーコレクション
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // グループコレクション
    match /groups/{groupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid in resource.data.memberIds;
    }

    // 写真コレクション
    match /photos/{photoId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth.uid == resource.data.uploadedBy;
    }
  }
}
```

**Storage Rules:**
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

### 4. 依存関係のインストール

**Swift Package Manager (推奨):**

Xcodeで以下のパッケージを追加:
1. File > Add Package Dependencies
2. 以下のURLを追加:
   - Firebase: `https://github.com/firebase/firebase-ios-sdk`
   - SDWebImageSwiftUI: `https://github.com/SDWebImage/SDWebImageSwiftUI`

必要なパッケージ:
- FirebaseAuth
- FirebaseFirestore
- FirebaseStorage
- SDWebImageSwiftUI

**CocoaPods:**

```ruby
# Podfile
platform :ios, '16.0'
use_frameworks!

target 'SnapShareEvent' do
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'SDWebImageSwiftUI'
end
```

インストール:
```bash
pod install
```

### 5. Xcodeプロジェクトの作成

1. Xcodeで新しいプロジェクトを作成
   - Template: iOS > App
   - Interface: SwiftUI
   - Language: Swift
   - Bundle Identifier: `com.yourcompany.snapshare`

2. 本リポジトリのファイルをXcodeプロジェクトに追加

3. `Info.plist`の設定を確認（カメラ権限など）

4. `GoogleService-Info.plist`を追加

5. ビルドして実行

## 📋 主要な機能詳細

### グループの12時間ルール
- グループ作成時から12時間以内のみQRコードが有効
- 有効期限切れ後は新規メンバーの参加不可
- 既存メンバーは引き続きアクセス可能

### 写真エフェクト
- **なし**: オリジナル画像
- **セピア**: 温かみのあるセピアトーン
- **モノクロ**: クラシックな白黒写真
- **鮮やか**: 彩度とコントラストを強調
- **ビンテージ**: セピア + ビネット効果

### リアルタイム同期
- Firestoreのリアルタイムリスナーを使用
- 写真アップロード時に全メンバーへ即時通知
- グループ情報の自動更新

## 🔐 セキュリティ

### 匿名認証
- 複雑なサインアップ不要
- Firebase Anonymous Authenticationを使用
- デバイス固有のユーザーID生成

### データ保護
- Firestoreセキュリティルールによるアクセス制御
- Storage Rulesによる画像アクセス制限
- ユーザー認証必須

## 🎨 UI/UXの特徴

- **SwiftUI**: モダンな宣言的UI
- **ダークモード対応**: システム設定に自動追従
- **レスポンシブデザイン**: 様々な画面サイズに対応
- **アニメーション**: スムーズな画面遷移

## 📱 必要な権限

- **カメラ**: 写真撮影
- **フォトライブラリ**: 写真保存（オプション）

## 🔮 今後の拡張機能候補

### 実装済み
- [x] オンボーディング
- [x] グループ作成・参加
- [x] QRコード生成・スキャン
- [x] カメラ撮影
- [x] 写真エフェクト
- [x] Firebase連携
- [x] メモリー機能

### 今後の追加機能
- [ ] Instagram Story共有
- [ ] Webビューア（ブラウザ対応）
- [ ] 写真へのコメント機能
- [ ] いいね機能
- [ ] プッシュ通知
- [ ] 写真の一括ダウンロード
- [ ] グループ削除機能
- [ ] プロフィール編集

## 📝 ライセンス

MIT License

## 👨‍💻 開発者

SnapShare Event - MVP Implementation
2025年12月21日作成

---

**注意事項:**
- このMVP実装は教育・プロトタイプ目的です
- 本番環境での使用前に、セキュリティとスケーラビリティの追加実装が必要です
- Firebaseの無料枠を超える使用には課金が発生します
