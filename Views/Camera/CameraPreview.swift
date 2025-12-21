//
//  CameraPreview.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = cameraService.getPreviewLayer()
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // フレームの更新
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}
