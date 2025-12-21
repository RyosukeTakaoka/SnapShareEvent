//
//  Group.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation
import FirebaseFirestore

struct Group: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var createdBy: String // User ID
    var createdAt: Date
    var memberIds: [String] // User IDs
    var photoCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdBy
        case createdAt
        case memberIds
        case photoCount
    }

    init(
        id: String? = nil,
        name: String,
        createdBy: String,
        createdAt: Date = Date(),
        memberIds: [String] = [],
        photoCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.memberIds = memberIds
        self.photoCount = photoCount
    }

    // 12時間ルール: グループ作成から12時間以内かチェック
    var isQRCodeValid: Bool {
        let twelveHoursInSeconds: TimeInterval = Constants.Group.validityHours * 3600
        return Date().timeIntervalSince(createdAt) < twelveHoursInSeconds
    }

    // QRコード用のURL生成
    var qrCodeURL: String {
        guard let groupId = id else { return "" }
        return "\(Constants.Group.qrCodePrefix)group/\(groupId)"
    }

    // Firestoreへの保存用ディクショナリ
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "createdBy": createdBy,
            "createdAt": Timestamp(date: createdAt),
            "memberIds": memberIds,
            "photoCount": photoCount
        ]
    }
}
