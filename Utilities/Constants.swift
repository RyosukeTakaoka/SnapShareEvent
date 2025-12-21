//
//  Constants.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation

enum Constants {
    // Firebase
    enum Firebase {
        static let usersCollection = "users"
        static let groupsCollection = "groups"
        static let photosCollection = "photos"
    }

    // Group
    enum Group {
        static let validityHours: TimeInterval = 12 // 12時間ルール
        static let qrCodePrefix = "snapshare://"
    }

    // Image
    enum Image {
        static let maxImageSizeBytes: Int = 5 * 1024 * 1024 // 5MB
        static let thumbnailSize: CGFloat = 200
        static let compressionQuality: CGFloat = 0.8
    }

    // App
    enum App {
        static let name = "SnapShare Event"
        static let version = "1.0.0"
    }
}
