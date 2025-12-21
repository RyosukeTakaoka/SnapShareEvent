//
//  CameraService.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false
    @Published var isCameraAvailable = false
    @Published var errorMessage: String?

    private let session = AVCaptureSession()
    private var videoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var currentPhotoSettings: AVCapturePhotoSettings?

    override init() {
        super.init()
        checkCameraPermission()
    }

    // カメラ権限チェック
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAvailable = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAvailable = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            isCameraAvailable = false
            errorMessage = "カメラへのアクセスが拒否されています。設定から許可してください。"
        @unknown default:
            isCameraAvailable = false
        }
    }

    // カメラのセットアップ
    private func setupCamera() {
        session.beginConfiguration()

        // セッション品質の設定
        session.sessionPreset = .photo

        // カメラデバイスの取得
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            errorMessage = "カメラデバイスが見つかりません"
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }

            session.commitConfiguration()
        } catch {
            errorMessage = "カメラの設定に失敗しました: \(error.localizedDescription)"
            session.commitConfiguration()
        }
    }

    // セッション開始
    func startSession() {
        guard !session.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }

    // セッション停止
    func stopSession() {
        guard session.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }

    // 写真撮影
    func capturePhoto() {
        let settings: AVCapturePhotoSettings

        // HEVCが利用可能な場合はHEVCを使用、そうでない場合はデフォルト
        if videoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }

        currentPhotoSettings = settings
        videoOutput.capturePhoto(with: settings, delegate: self)
    }

    // プレビューレイヤーの取得
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    // フラッシュモード切替
    func toggleFlash(enabled: Bool) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = enabled ? .on : .off
            device.unlockForConfiguration()
        } catch {
            errorMessage = "フラッシュの設定に失敗しました"
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            errorMessage = "写真の撮影に失敗しました: \(error.localizedDescription)"
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            errorMessage = "画像データの処理に失敗しました"
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
        }
    }
}
