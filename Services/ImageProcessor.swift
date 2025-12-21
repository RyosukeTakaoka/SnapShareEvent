//
//  ImageProcessor.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import UIKit
import CoreImage

class ImageProcessor {
    private let context = CIContext()

    // MARK: - エフェクト適用

    /// 指定されたエフェクトを画像に適用
    /// - Parameters:
    ///   - image: 元画像
    ///   - effect: 適用するエフェクト
    /// - Returns: エフェクト適用後の画像
    func applyEffect(to image: UIImage, effect: PhotoEffect) -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }

        let processedImage: CIImage?

        switch effect {
        case .none:
            return image
        case .sepia:
            processedImage = applySepia(to: ciImage)
        case .mono:
            processedImage = applyMono(to: ciImage)
        case .vivid:
            processedImage = applyVivid(to: ciImage)
        case .vintage:
            processedImage = applyVintage(to: ciImage)
        }

        guard let outputImage = processedImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - 個別エフェクト

    /// セピアエフェクト
    private func applySepia(to image: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CISepiaTone") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: kCIInputIntensityKey)
        return filter.outputImage
    }

    /// モノクロエフェクト
    private func applyMono(to image: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage
    }

    /// 鮮やかエフェクト（彩度とコントラストを上げる）
    private func applyVivid(to image: CIImage) -> CIImage? {
        guard let colorFilter = CIFilter(name: "CIColorControls") else { return nil }
        colorFilter.setValue(image, forKey: kCIInputImageKey)
        colorFilter.setValue(1.5, forKey: kCIInputSaturationKey) // 彩度
        colorFilter.setValue(1.2, forKey: kCIInputContrastKey)   // コントラスト

        return colorFilter.outputImage
    }

    /// ビンテージエフェクト（セピア + ビネット）
    private func applyVintage(to image: CIImage) -> CIImage? {
        // セピアを適用
        guard let sepiaImage = applySepia(to: image),
              let vignetteFilter = CIFilter(name: "CIVignette") else {
            return nil
        }

        vignetteFilter.setValue(sepiaImage, forKey: kCIInputImageKey)
        vignetteFilter.setValue(1.5, forKey: kCIInputIntensityKey)
        vignetteFilter.setValue(2.0, forKey: kCIInputRadiusKey)

        return vignetteFilter.outputImage
    }

    // MARK: - 画像圧縮・リサイズ

    /// 画像を圧縮してデータサイズを削減
    /// - Parameters:
    ///   - image: 元画像
    ///   - maxSizeBytes: 最大サイズ（バイト）
    /// - Returns: 圧縮後の画像データ
    func compressImage(_ image: UIImage, maxSizeBytes: Int = Constants.Image.maxImageSizeBytes) -> Data? {
        var compression: CGFloat = Constants.Image.compressionQuality
        var imageData = image.jpegData(compressionQuality: compression)

        // 指定サイズ以下になるまで圧縮率を下げる
        while let data = imageData, data.count > maxSizeBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        return imageData
    }

    /// サムネイル画像を生成
    /// - Parameters:
    ///   - image: 元画像
    ///   - size: サムネイルサイズ
    /// - Returns: サムネイル画像
    func generateThumbnail(from image: UIImage, size: CGFloat = Constants.Image.thumbnailSize) -> UIImage? {
        let scale = size / max(image.size.width, image.size.height)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 画像をリサイズ
    /// - Parameters:
    ///   - image: 元画像
    ///   - targetSize: 目標サイズ
    /// - Returns: リサイズ後の画像
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
