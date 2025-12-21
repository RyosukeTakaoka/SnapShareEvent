//
//  OnboardingView.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // App Icon
                Text("📸")
                    .font(.system(size: 100))

                // App Name
                Text("SnapShare Event")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("イベントの瞬間を、みんなで共有")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("名前")
                        .font(.headline)

                    TextField("名前を入力", text: $viewModel.userName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 40)

                // Icon Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("アイコン")
                        .font(.headline)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(viewModel.availableIcons, id: \.self) { icon in
                            Text(icon)
                                .font(.system(size: 40))
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(viewModel.selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    viewModel.selectedIcon = icon
                                }
                        }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 40)
                }

                // Continue Button
                Button(action: {
                    Task {
                        await viewModel.completeOnboarding()
                        if UserDefaults.standard.hasCompletedOnboarding {
                            isOnboardingComplete = true
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("はじめる")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingComplete: .constant(false))
    }
}
