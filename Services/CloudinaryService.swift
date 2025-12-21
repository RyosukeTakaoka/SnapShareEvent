//
//  CloudinaryService.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation
import UIKit
import Cloudinary

class CloudinaryService {
    static let shared = CloudinaryService()

    private var cloudinary: CLDCloudinary?
    private let imageProcessor = ImageProcessor()

    private init() {
        setupCloudinary()
    }

    // MARK: - Setup

    private func setupCloudinary() {
        let config = CLDConfiguration(
            cloudName: CloudinaryConfig.cloudName,
            apiKey: CloudinaryConfig.apiKey,
            apiSecret: CloudinaryConfig.apiSecret,
            secure: true
        )

        cloudinary = CLDCloudinary(configuration: config)
    }

    // MARK: - Upload

    /// 画像をCloudinaryにアップロード
    /// - Parameters:
    ///   - image: アップロードする画像
    ///   - folder: Cloudinary上のフォルダパス（例: "groups/groupId"）
    ///   - publicId: 画像の公開ID（指定しない場合は自動生成）
    /// - Returns: アップロード結果（画像URL、サムネイルURL、公開ID）
    func uploadImage(
        _ image: UIImage,
        folder: String,
        publicId: String? = nil
    ) async throws -> CloudinaryUploadResult {
        guard let cloudinary = cloudinary else {
            throw CloudinaryError.notConfigured
        }

        // 画像を圧縮
        guard let imageData = imageProcessor.compressImage(image) else {
            throw CloudinaryError.compressionFailed
        }

        // アップロードパラメータを設定
        let params = CLDUploadRequestParams()
        params.setFolder(folder)
        params.setResourceType(.image)

        if let publicId = publicId {
            params.setPublicId(publicId)
        } else {
            // UUIDを使用して一意のIDを生成
            params.setPublicId(UUID().uuidString)
        }

        // Unsigned Upload用のプリセットを使用（推奨）
        params.setUploadPreset(CloudinaryConfig.uploadPreset)

        // アップロードを実行
        return try await withCheckedThrowingContinuation { continuation in
            let request = cloudinary.createUploader().upload(
                data: imageData,
                uploadPreset: CloudinaryConfig.uploadPreset,
                params: params
            ) { result, error in
                if let error = error {
                    continuation.resume(throwing: CloudinaryError.uploadFailed(error.localizedDescription))
                    return
                }

                guard let result = result else {
                    continuation.resume(throwing: CloudinaryError.uploadFailed("No result returned"))
                    return
                }

                // アップロード結果を作成
                let uploadResult = CloudinaryUploadResult(
                    publicId: result.publicId ?? "",
                    secureUrl: result.secureUrl ?? "",
                    url: result.url ?? "",
                    thumbnailUrl: self.generateThumbnailUrl(publicId: result.publicId ?? ""),
                    width: result.width ?? 0,
                    height: result.height ?? 0,
                    format: result.format ?? "jpg"
                )

                continuation.resume(returning: uploadResult)
            }

            // プログレス監視（オプション）
            request.progress { progress in
                // プログレスを処理する場合はここに実装
                print("Upload progress: \(progress.fractionCompleted * 100)%")
            }
        }
    }

    /// サムネイル画像をアップロード
    /// - Parameters:
    ///   - image: 元画像
    ///   - folder: フォルダパス
    ///   - publicId: 公開ID
    /// - Returns: サムネイルのURL
    func uploadThumbnail(
        _ image: UIImage,
        folder: String,
        publicId: String
    ) async throws -> String {
        guard let thumbnail = imageProcessor.generateThumbnail(from: image) else {
            throw CloudinaryError.thumbnailGenerationFailed
        }

        let thumbnailPublicId = "\(publicId)_thumb"
        let result = try await uploadImage(thumbnail, folder: folder, publicId: thumbnailPublicId)

        return result.secureUrl
    }

    // MARK: - URL Generation

    /// サムネイルURLを生成（Cloudinaryの変換機能を使用）
    /// - Parameter publicId: 画像の公開ID
    /// - Returns: サムネイルURL
    func generateThumbnailUrl(publicId: String) -> String {
        guard let cloudinary = cloudinary else {
            return ""
        }

        // Cloudinaryの変換パラメータを使用してサムネイルURLを生成
        let transformation = CLDTransformation()
            .setWidth(Int(Constants.Image.thumbnailSize))
            .setHeight(Int(Constants.Image.thumbnailSize))
            .setCrop(.fill)
            .setQuality(.auto())

        return cloudinary.createUrl()
            .setTransformation(transformation)
            .generate(publicId) ?? ""
    }

    /// 最適化された画像URLを生成
    /// - Parameters:
    ///   - publicId: 画像の公開ID
    ///   - width: 幅（オプション）
    ///   - quality: 品質（オプション）
    /// - Returns: 最適化されたURL
    func generateOptimizedUrl(
        publicId: String,
        width: Int? = nil,
        quality: String = "auto"
    ) -> String {
        guard let cloudinary = cloudinary else {
            return ""
        }

        var transformation = CLDTransformation()
            .setQuality(quality)

        if let width = width {
            transformation = transformation.setWidth(width)
        }

        return cloudinary.createUrl()
            .setTransformation(transformation)
            .generate(publicId) ?? ""
    }

    // MARK: - Delete

    /// 画像を削除
    /// - Parameter publicId: 削除する画像の公開ID
    func deleteImage(publicId: String) async throws {
        guard let cloudinary = cloudinary else {
            throw CloudinaryError.notConfigured
        }

        // Note: Cloudinary iOS SDKのuploaderにはdestroyメソッドがないため、
        // 削除機能はバックエンドAPIまたはCloudinary Admin APIを使用する必要があります
        // ここでは簡易実装として、削除機能をスキップします
        // 本番環境では、サーバーサイドで削除処理を実装することを推奨
        throw CloudinaryError.deleteFailed("Delete feature not implemented in iOS SDK")
    }

    // MARK: - Helper Methods

    /// フォルダパスを生成
    /// - Parameter groupId: グループID
    /// - Returns: フォルダパス
    static func folderPath(for groupId: String) -> String {
        return "snapshare/groups/\(groupId)"
    }
}

// MARK: - Models

struct CloudinaryUploadResult {
    let publicId: String
    let secureUrl: String
    let url: String
    let thumbnailUrl: String
    let width: Int
    let height: Int
    let format: String
}

enum CloudinaryError: LocalizedError {
    case notConfigured
    case compressionFailed
    case thumbnailGenerationFailed
    case uploadFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Cloudinaryが設定されていません。CloudinaryConfig.swiftを確認してください。"
        case .compressionFailed:
            return "画像の圧縮に失敗しました。"
        case .thumbnailGenerationFailed:
            return "サムネイルの生成に失敗しました。"
        case .uploadFailed(let message):
            return "アップロードに失敗しました: \(message)"
        case .deleteFailed(let message):
            return "削除に失敗しました: \(message)"
        }
    }
}
