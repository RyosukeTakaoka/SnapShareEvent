//
//  CloudinaryConfig.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation

struct CloudinaryConfig {
    // Cloudinaryの設定
    // 本番環境では環境変数やSecure Storageから読み込むことを推奨
    static let cloudName = ProcessInfo.processInfo.environment["CLOUDINARY_CLOUD_NAME"] ?? "YOUR_CLOUD_NAME"
    static let apiKey = ProcessInfo.processInfo.environment["CLOUDINARY_API_KEY"] ?? "YOUR_API_KEY"
    static let apiSecret = ProcessInfo.processInfo.environment["CLOUDINARY_API_SECRET"] ?? "YOUR_API_SECRET"

    // アップロードプリセット（Unsigned Upload用）
    // Cloudinary Consoleで設定が必要
    static let uploadPreset = ProcessInfo.processInfo.environment["CLOUDINARY_UPLOAD_PRESET"] ?? "snapshare_preset"

    // Cloudinaryの設定URL
    static var cloudinaryURL: String {
        return "cloudinary://\(apiKey):\(apiSecret)@\(cloudName)"
    }

    // 設定が有効かチェック
    static var isConfigured: Bool {
        return cloudName != "YOUR_CLOUD_NAME" &&
               apiKey != "YOUR_API_KEY" &&
               uploadPreset != "snapshare_preset"
    }
}
