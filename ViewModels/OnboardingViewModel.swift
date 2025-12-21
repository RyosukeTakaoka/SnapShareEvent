//
//  OnboardingViewModel.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var selectedIcon: String = "📷"
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebaseManager = FirebaseManager.shared

    // 利用可能な絵文字アイコン
    let availableIcons = ["📷", "🎉", "✈️", "🎂", "🏖️", "🎨", "🎭", "🎪", "🎬", "🎸", "⚽️", "🏀"]

    var isFormValid: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// オンボーディングを完了してユーザーを作成
    func completeOnboarding() async {
        guard isFormValid else {
            errorMessage = "名前を入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 1. 匿名認証
            let userId = try await firebaseManager.signInAnonymously()

            // 2. ユーザー作成
            let user = User(
                id: userId,
                name: userName.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: selectedIcon
            )

            try await firebaseManager.createUser(user)

            // 3. UserDefaultsに保存
            UserDefaults.standard.userId = userId
            UserDefaults.standard.userName = user.name
            UserDefaults.standard.userIcon = user.icon
            UserDefaults.standard.hasCompletedOnboarding = true

            isLoading = false

        } catch {
            isLoading = false
            errorMessage = "ユーザーの作成に失敗しました: \(error.localizedDescription)"
        }
    }
}
