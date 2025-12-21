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
    @State private var isOnboardingComplete = UserDefaults.standard.hasCompletedOnboarding

    var body: some Scene {
        WindowGroup {
            if isOnboardingComplete {
                MainView()
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
            }
        }
    }
}
