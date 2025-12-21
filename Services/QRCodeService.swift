//
//  QRCodeService.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import CoreImage
import UIKit
import AVFoundation
import Combine

class QRCodeService: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var errorMessage: String?

    private var captureSession: AVCaptureSession?
    private let metadataOutput = AVCaptureMetadataOutput()

    // MARK: - QRコード生成

    /// QRコード画像を生成する
    /// - Parameters:
    ///   - string: QRコードに埋め込む文字列
    ///   - size: 画像サイズ
    /// - Returns: QRコード画像
    func generateQRCode(from string: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        let data = string.data(using: .utf8)

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // 高い誤り訂正レベル

        guard let ciImage = filter.outputImage else {
            return nil
        }

        // スケーリング
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - QRコードスキャン

    /// QRコードスキャンのセットアップ
    func setupScanning() -> AVCaptureSession? {
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video) else {
            errorMessage = "カメラデバイスが見つかりません"
            return nil
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }

            captureSession = session
            return session

        } catch {
            errorMessage = "カメラの設定に失敗しました: \(error.localizedDescription)"
            return nil
        }
    }

    /// スキャン開始
    func startScanning() {
        guard let session = captureSession, !session.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async {
                self?.isScanning = true
            }
        }
    }

    /// スキャン停止
    func stopScanning() {
        guard let session = captureSession, session.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.stopRunning()
            DispatchQueue.main.async {
                self?.isScanning = false
            }
        }
    }

    /// スキャン結果をリセット
    func resetScannedCode() {
        scannedCode = nil
    }

    // MARK: - Helper

    /// QRコードからグループIDを抽出
    /// - Parameter qrString: QRコードの文字列 (例: "snapshare://group/abc123")
    /// - Returns: グループID
    func extractGroupId(from qrString: String) -> String? {
        guard qrString.hasPrefix(Constants.Group.qrCodePrefix) else {
            return nil
        }

        let components = qrString.components(separatedBy: "/")
        guard components.count >= 3,
              components[components.count - 2] == "group" else {
            return nil
        }

        return components.last
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRCodeService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // 既にスキャン済みの場合は処理しない
        if scannedCode != nil { return }

        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let stringValue = metadataObject.stringValue else {
            return
        }

        // QRコードを検出したら停止
        scannedCode = stringValue
        stopScanning()
    }
}
