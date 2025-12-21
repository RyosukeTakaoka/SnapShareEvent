//
//  CameraView.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import SwiftUI

struct CameraView: View {
    let group: Group
    @StateObject private var viewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss

    init(group: Group) {
        self.group = group
        _viewModel = StateObject(wrappedValue: CameraViewModel(group: group))
    }

    var body: some View {
        ZStack {
            // Camera Preview or Captured Image
            if let processedImage = viewModel.processedImage ?? viewModel.capturedImage {
                capturedImageView(image: processedImage)
            } else {
                cameraPreviewView
            }

            // Controls Overlay
            VStack {
                // Top Bar
                HStack {
                    Button(action: {
                        viewModel.stopCamera()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }

                    Spacer()

                    Text(group.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)

                    Spacer()

                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 30, height: 30)
                }
                .padding()

                Spacer()

                // Bottom Controls
                if viewModel.capturedImage == nil {
                    // Capture Button
                    Button(action: {
                        viewModel.capturePhoto()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 4)
                                    .frame(width: 80, height: 80)
                            )
                    }
                    .padding(.bottom, 40)
                } else {
                    // Effect Selection & Upload Controls
                    capturedControlsView
                }
            }

            // Upload Progress
            if viewModel.isUploading {
                uploadProgressView
            }

            // Success Message
            if viewModel.uploadSuccess {
                successView
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Subviews

    private var cameraPreviewView: some View {
        CameraPreview(cameraService: viewModel.cameraService)
            .edgesIgnoringSafeArea(.all)
    }

    private func capturedImageView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
    }

    private var capturedControlsView: some View {
        VStack(spacing: 20) {
            // Effect Selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PhotoEffect.allCases, id: \.self) { effect in
                        Button(action: {
                            viewModel.changeEffect(effect)
                        }) {
                            Text(effect.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedEffect == effect ? Color.blue : Color.white.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Action Buttons
            HStack(spacing: 40) {
                // Retake
                Button(action: {
                    viewModel.retakePhoto()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 30))
                        Text("撮り直す")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                }

                // Upload
                Button(action: {
                    Task {
                        await viewModel.uploadPhoto()
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 50))
                        Text("アップロード")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .disabled(viewModel.isUploading)
            }
            .padding(.bottom, 40)
        }
    }

    private var uploadProgressView: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("アップロード中...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }

    private var successView: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("アップロード完了!")
                    .foregroundColor(.white)
                    .font(.headline)

                Button(action: {
                    viewModel.resetCamera()
                }) {
                    Text("もう一枚撮る")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    viewModel.stopCamera()
                    dismiss()
                }) {
                    Text("閉じる")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
    }
}
