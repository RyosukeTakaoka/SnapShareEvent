//
//  User.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var icon: String // 絵文字
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case createdAt
    }

    init(id: String? = nil, name: String, icon: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
    }

    // Firestoreへの保存用ディクショナリ
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "icon": icon,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
