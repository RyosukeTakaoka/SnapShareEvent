//
//  CameraViewModel.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation
import UIKit
import Combine

@MainActor
class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var selectedEffect: PhotoEffect = .none
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var uploadSuccess = false

    let cameraService = CameraService()
    private let imageProcessor = ImageProcessor()
    private let firebaseManager = FirebaseManager.shared
    private var cancellables = Set<AnyCancellable>()

    let group: Group

    init(group: Group) {
        self.group = group
        setupCameraObserver()
    }

    // MARK: - Camera Operations

    private func setupCameraObserver() {
        cameraService.$capturedImage
            .compactMap { $0 }
            .sink { [weak self] image in
                self?.capturedImage = image
                self?.applyEffect()
            }
            .store(in: &cancellables)
    }

    func startCamera() {
        cameraService.startSession()
    }

    func stopCamera() {
        cameraService.stopSession()
    }

    func capturePhoto() {
        cameraService.capturePhoto()
    }

    // MARK: - Effect Operations

    func applyEffect() {
        guard let image = capturedImage else { return }

        if selectedEffect == .none {
            processedImage = image
        } else {
            processedImage = imageProcessor.applyEffect(to: image, effect: selectedEffect)
        }
    }

    func changeEffect(_ effect: PhotoEffect) {
        selectedEffect = effect
        applyEffect()
    }

    // MARK: - Upload Operations

    func uploadPhoto() async {
        guard let image = processedImage ?? capturedImage else {
            errorMessage = "アップロードする画像がありません"
            return
        }

        guard let userId = UserDefaults.standard.userId,
              let userName = UserDefaults.standard.userName,
              let userIcon = UserDefaults.standard.userIcon,
              let groupId = group.id else {
            errorMessage = "ユーザー情報が見つかりません"
            return
        }

        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil

        do {
            // Firebase Storageにアップロード
            _ = try await firebaseManager.uploadPhoto(
                image: image,
                groupId: groupId,
                uploadedBy: userId,
                uploaderName: userName,
                uploaderIcon: userIcon,
                appliedEffect: selectedEffect == .none ? nil : selectedEffect
            )

            // 成功
            isUploading = false
            uploadProgress = 1.0
            uploadSuccess = true

            // リセット
            resetCamera()

        } catch {
            isUploading = false
            errorMessage = "写真のアップロードに失敗しました: \(error.localizedDescription)"
        }
    }

    func resetCamera() {
        capturedImage = nil
        processedImage = nil
        selectedEffect = .none
        uploadSuccess = false
    }

    func retakePhoto() {
        resetCamera()
    }
}
