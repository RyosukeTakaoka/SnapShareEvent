//
//  UserDefaultsKeys.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation

enum UserDefaultsKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let userId = "userId"
    static let userName = "userName"
    static let userIcon = "userIcon" // 絵文字として保存
    static let joinedGroupIds = "joinedGroupIds"
}

// UserDefaultsの便利なExtension
extension UserDefaults {
    var hasCompletedOnboarding: Bool {
        get { bool(forKey: UserDefaultsKeys.hasCompletedOnboarding) }
        set { set(newValue, forKey: UserDefaultsKeys.hasCompletedOnboarding) }
    }

    var userId: String? {
        get { string(forKey: UserDefaultsKeys.userId) }
        set { set(newValue, forKey: UserDefaultsKeys.userId) }
    }

    var userName: String? {
        get { string(forKey: UserDefaultsKeys.userName) }
        set { set(newValue, forKey: UserDefaultsKeys.userName) }
    }

    var userIcon: String? {
        get { string(forKey: UserDefaultsKeys.userIcon) }
        set { set(newValue, forKey: UserDefaultsKeys.userIcon) }
    }

    var joinedGroupIds: [String] {
        get { stringArray(forKey: UserDefaultsKeys.joinedGroupIds) ?? [] }
        set { set(newValue, forKey: UserDefaultsKeys.joinedGroupIds) }
    }
}
