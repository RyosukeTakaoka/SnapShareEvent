//
//  MemoryViewModel.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class MemoryViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebaseManager = FirebaseManager.shared
    private var photoListener: ListenerRegistration?

    let group: Group

    init(group: Group) {
        self.group = group
    }

    deinit {
        photoListener?.remove()
    }

    // MARK: - Photo Operations

    /// 写真一覧を読み込み
    func loadPhotos() async {
        guard let groupId = group.id else { return }

        isLoading = true
        errorMessage = nil

        do {
            photos = try await firebaseManager.getPhotos(groupId: groupId)
            isLoading = false

            // リアルタイム監視を設定
            setupPhotoListener()
        } catch {
            isLoading = false
            errorMessage = "写真の読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    /// リアルタイム監視を設定
    private func setupPhotoListener() {
        guard let groupId = group.id else { return }

        photoListener?.remove()

        photoListener = firebaseManager.observePhotos(groupId: groupId) { [weak self] updatedPhotos in
            Task { @MainActor in
                self?.photos = updatedPhotos
            }
        }
    }

    // MARK: - Memory Features

    /// 日付ごとにグループ化された写真を取得
    func photosByDate() -> [Date: [Photo]] {
        var grouped: [Date: [Photo]] = [:]

        for photo in photos {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: photo.createdAt)
            guard let date = calendar.date(from: dateComponents) else { continue }

            if grouped[date] == nil {
                grouped[date] = []
            }
            grouped[date]?.append(photo)
        }

        return grouped
    }

    /// ソート済みの日付一覧を取得
    func sortedDates() -> [Date] {
        return Array(photosByDate().keys).sorted(by: >)
    }

    /// 特定の日付の写真を取得
    func photos(for date: Date) -> [Photo] {
        return photosByDate()[date] ?? []
    }

    /// メモリーカードのタイトルを生成
    func memoryTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    /// 写真の総数
    var totalPhotoCount: Int {
        return photos.count
    }

    /// 日数
    var totalDays: Int {
        return photosByDate().count
    }
}
