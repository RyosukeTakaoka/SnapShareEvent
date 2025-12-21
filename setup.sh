#!/bin/bash

# SnapShare Event - Setup Script
# このスクリプトはプロジェクトの初期セットアップを行います

set -e

echo "🚀 SnapShare Event セットアップ開始..."

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. XcodeGenのチェック
echo ""
echo "📋 依存関係のチェック..."
if ! command -v xcodegen &> /dev/null; then
    echo -e "${RED}❌ XcodeGenがインストールされていません${NC}"
    echo "以下のコマンドでインストールしてください:"
    echo "  brew install xcodegen"
    exit 1
fi
echo -e "${GREEN}✅ XcodeGen がインストールされています${NC}"

# 2. GoogleService-Info.plistのチェック
echo ""
echo "🔥 Firebase設定のチェック..."
if [ ! -f "GoogleService-Info.plist" ]; then
    echo -e "${YELLOW}⚠️  GoogleService-Info.plist が見つかりません${NC}"
    echo ""
    echo "Firebase Consoleから GoogleService-Info.plist をダウンロードしてください:"
    echo "  1. https://console.firebase.google.com/ にアクセス"
    echo "  2. プロジェクトを作成または選択"
    echo "  3. iOSアプリを追加"
    echo "  4. Bundle ID: com.snapshare.event"
    echo "  5. GoogleService-Info.plist をダウンロード"
    echo "  6. このディレクトリに配置"
    echo ""
    echo "テンプレートファイルを参考にしてください:"
    echo "  GoogleService-Info.plist.template"
    echo ""
    read -p "続行しますか? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✅ GoogleService-Info.plist が見つかりました${NC}"
fi

# 2.5. Cloudinary設定のチェック
echo ""
echo "☁️  Cloudinary設定のチェック..."
echo -e "${YELLOW}⚠️  Cloudinary環境変数が設定されていることを確認してください${NC}"
echo ""
echo "Xcodeスキームで以下の環境変数を設定する必要があります:"
echo "  CLOUDINARY_CLOUD_NAME"
echo "  CLOUDINARY_API_KEY"
echo "  CLOUDINARY_API_SECRET"
echo "  CLOUDINARY_UPLOAD_PRESET"
echo ""
echo "詳細は CLOUDINARY_SETUP.md を参照してください。"
echo ""

# 3. Xcodeプロジェクトの生成
echo ""
echo "🔨 Xcodeプロジェクトを生成中..."
xcodegen generate
echo -e "${GREEN}✅ Xcodeプロジェクトが生成されました${NC}"

# 4. Swift Package Managerの依存関係を解決
echo ""
echo "📦 依存関係を解決中..."
echo "Xcodeでプロジェクトを開いてください。"
echo "依存関係は自動的にダウンロードされます。"

# 5. 完了メッセージ
echo ""
echo -e "${GREEN}✅ セットアップ完了！${NC}"
echo ""
echo "次のステップ:"
echo "  1. Xcodeでプロジェクトを開く:"
echo "     open SnapShareEvent.xcodeproj"
echo ""
echo "  2. Signing & Capabilitiesで開発チームを設定"
echo ""
echo "  3. Cloudinary環境変数を設定:"
echo "     Product > Scheme > Edit Scheme... > Run > Arguments > Environment Variables"
echo "     詳細: CLOUDINARY_SETUP.md"
echo ""
echo "  4. Firebase Consoleでサービスを有効化:"
echo "     - Authentication (匿名認証)"
echo "     - Firestore Database"
echo ""
echo "  5. Firestoreセキュリティルールを設定 (README.md参照)"
echo ""
echo "  6. Cloudinary Upload Presetを作成 (CLOUDINARY_SETUP.md参照)"
echo ""
echo "  7. ビルドして実行 (⌘ + R)"
echo ""
echo "詳細ドキュメント:"
echo "  - README.md - プロジェクト概要"
echo "  - QUICKSTART.md - 5分セットアップガイド"
echo "  - CLOUDINARY_SETUP.md - Cloudinaryセットアップ"
echo "  - ARCHITECTURE.md - アーキテクチャ詳細"
echo ""
