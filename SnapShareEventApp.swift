//
//  SnapShareEventApp.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase初期化
        FirebaseApp.configure()
        return true
    }
}

@main
struct SnapShareEventApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // ✅ 起動時の処理を最小化：初期値のみ設定、遅延評価
    @State private var isOnboardingComplete = false
    @State private var isInitialized = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !isInitialized {
                    // ✅ 起動時は最小限のシンプルなView
                    ProgressView()
                        .task {
                            // ✅ UserDefaults読み込みを遅延
                            await Task.yield() // 1フレーム待機
                            isOnboardingComplete = UserDefaults.standard.hasCompletedOnboarding
                            isInitialized = true
                        }
                } else if isOnboardingComplete {
                    MainView()
                } else {
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                }
            }
        }
    }
}
