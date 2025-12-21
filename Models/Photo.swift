//
//  Photo.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation
import FirebaseFirestore

struct Photo: Codable, Identifiable {
    @DocumentID var id: String?
    var groupId: String
    var uploadedBy: String // User ID
    var uploaderName: String // 表示用
    var uploaderIcon: String // 表示用
    var imageURL: String // Firebase Storage URL
    var thumbnailURL: String? // サムネイル画像のURL
    var createdAt: Date
    var appliedEffect: PhotoEffect?

    enum CodingKeys: String, CodingKey {
        case id
        case groupId
        case uploadedBy
        case uploaderName
        case uploaderIcon
        case imageURL
        case thumbnailURL
        case createdAt
        case appliedEffect
    }

    init(
        id: String? = nil,
        groupId: String,
        uploadedBy: String,
        uploaderName: String,
        uploaderIcon: String,
        imageURL: String,
        thumbnailURL: String? = nil,
        createdAt: Date = Date(),
        appliedEffect: PhotoEffect? = nil
    ) {
        self.id = id
        self.groupId = groupId
        self.uploadedBy = uploadedBy
        self.uploaderName = uploaderName
        self.uploaderIcon = uploaderIcon
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
        self.appliedEffect = appliedEffect
    }

    // Firestoreへの保存用ディクショナリ
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "groupId": groupId,
            "uploadedBy": uploadedBy,
            "uploaderName": uploaderName,
            "uploaderIcon": uploaderIcon,
            "imageURL": imageURL,
            "createdAt": Timestamp(date: createdAt)
        ]

        if let thumbnailURL = thumbnailURL {
            dict["thumbnailURL"] = thumbnailURL
        }

        if let effect = appliedEffect {
            dict["appliedEffect"] = effect.rawValue
        }

        return dict
    }
}

// 写真エフェクトの種類
enum PhotoEffect: String, Codable, CaseIterable {
    case none = "none"
    case sepia = "sepia"
    case mono = "mono"
    case vivid = "vivid"
    case vintage = "vintage"

    var displayName: String {
        switch self {
        case .none: return "なし"
        case .sepia: return "セピア"
        case .mono: return "モノクロ"
        case .vivid: return "鮮やか"
        case .vintage: return "ビンテージ"
        }
    }
}
