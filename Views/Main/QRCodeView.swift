//
//  QRCodeView.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import SwiftUI
import AVFoundation

struct QRCodeView: View {
    let group: Group
    @ObservedObject var qrCodeService: QRCodeService

    var body: some View {
        VStack(spacing: 20) {
            Text("グループに招待")
                .font(.title2)
                .fontWeight(.bold)

            Text(group.name)
                .font(.headline)
                .foregroundColor(.secondary)

            if group.isQRCodeValid {
                // QRコード表示
                if let qrImage = qrCodeService.generateQRCode(from: group.qrCodeURL) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }

                // 有効期限の表示
                Text(remainingTimeText())
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("このQRコードをスキャンしてグループに参加")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

            } else {
                // 有効期限切れ
                VStack(spacing: 16) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)

                    Text("QRコードの有効期限が切れました")
                        .font(.headline)

                    Text("グループ作成から12時間が経過しました")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .padding()
    }

    private func remainingTimeText() -> String {
        let twelveHours: TimeInterval = Constants.Group.validityHours * 3600
        let elapsed = Date().timeIntervalSince(group.createdAt)
        let remaining = twelveHours - elapsed

        if remaining <= 0 {
            return "有効期限切れ"
        }

        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)

        return "残り \(hours)時間 \(minutes)分"
    }
}

// MARK: - QR Scanner View
struct QRScannerView: View {
    @ObservedObject var qrCodeService: QRCodeService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // カメラプレビュー
            QRScannerRepresentable(qrCodeService: qrCodeService)
                .edgesIgnoringSafeArea(.all)

            // オーバーレイ
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        qrCodeService.stopScanning()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                }

                Spacer()

                Text("QRコードをスキャン")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)

                Spacer()
            }
        }
        .onAppear {
            qrCodeService.resetScannedCode()
        }
    }
}

// MARK: - UIViewRepresentable for QR Scanner
struct QRScannerRepresentable: UIViewRepresentable {
    @ObservedObject var qrCodeService: QRCodeService

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let session = qrCodeService.setupScanning() {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = UIScreen.main.bounds
            view.layer.addSublayer(previewLayer)

            DispatchQueue.global(qos: .userInitiated).async {
                qrCodeService.startScanning()
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新処理は不要
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // クリーンアップ
    }
}
