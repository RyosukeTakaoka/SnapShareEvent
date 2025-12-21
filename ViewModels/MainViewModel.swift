//
//  MainViewModel.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class MainViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCreateGroupSheet = false
    @Published var showQRScanner = false
    @Published var newGroupName = ""

    private let firebaseManager = FirebaseManager.shared
    private let qrCodeService = QRCodeService()
    private var cancellables = Set<AnyCancellable>()
    private var groupListeners: [String: ListenerRegistration] = [:]

    var currentUserId: String? {
        UserDefaults.standard.userId
    }

    init() {
        setupQRCodeObserver()
    }

    deinit {
        // deinitは非同期コンテキストではないため、直接リスナーを削除
        groupListeners.values.forEach { $0.remove() }
        groupListeners.removeAll()
    }

    // MARK: - Group Operations

    /// グループ一覧を読み込み
    func loadGroups() async {
        guard let userId = currentUserId else { return }

        isLoading = true
        errorMessage = nil

        do {
            groups = try await firebaseManager.getUserGroups(userId: userId)
            isLoading = false

            // リアルタイム監視を設定
            setupGroupListeners()
        } catch {
            isLoading = false
            errorMessage = "グループの読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    /// 新しいグループを作成
    func createGroup() async {
        guard let userId = currentUserId else { return }
        guard !newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "グループ名を入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            var group = Group(
                name: newGroupName.trimmingCharacters(in: .whitespacesAndNewlines),
                createdBy: userId,
                memberIds: [userId]
            )

            let groupId = try await firebaseManager.createGroup(group)
            group.id = groupId

            // UserDefaultsに保存
            var joinedIds = UserDefaults.standard.joinedGroupIds
            if !joinedIds.contains(groupId) {
                joinedIds.append(groupId)
                UserDefaults.standard.joinedGroupIds = joinedIds
            }

            // グループ一覧を再読み込み
            await loadGroups()

            newGroupName = ""
            showCreateGroupSheet = false
            isLoading = false

        } catch {
            isLoading = false
            errorMessage = "グループの作成に失敗しました: \(error.localizedDescription)"
        }
    }

    /// QRコードからグループに参加
    func joinGroupFromQR(qrString: String) async {
        guard let userId = currentUserId else { return }
        guard let groupId = qrCodeService.extractGroupId(from: qrString) else {
            errorMessage = "無効なQRコードです"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // グループ情報を取得
            guard let group = try await firebaseManager.getGroup(groupId: groupId) else {
                errorMessage = "グループが見つかりません"
                isLoading = false
                return
            }

            // 12時間ルールをチェック
            guard group.isQRCodeValid else {
                errorMessage = "このQRコードは有効期限が切れています（作成から12時間以内のみ有効）"
                isLoading = false
                return
            }

            // 既に参加しているかチェック
            if group.memberIds.contains(userId) {
                errorMessage = "既にこのグループに参加しています"
                isLoading = false
                return
            }

            // グループに参加
            try await firebaseManager.joinGroup(groupId: groupId, userId: userId)

            // グループ一覧を再読み込み
            await loadGroups()

            showQRScanner = false
            isLoading = false

        } catch {
            isLoading = false
            errorMessage = "グループへの参加に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - QR Code

    private func setupQRCodeObserver() {
        qrCodeService.$scannedCode
            .compactMap { $0 }
            .sink { [weak self] qrString in
                Task {
                    await self?.joinGroupFromQR(qrString: qrString)
                }
            }
            .store(in: &cancellables)
    }

    func getQRCodeService() -> QRCodeService {
        return qrCodeService
    }

    // MARK: - Realtime Listeners

    private func setupGroupListeners() {
        // 既存のリスナーを削除
        removeAllListeners()

        // 各グループのリアルタイム監視を設定
        for group in groups {
            guard let groupId = group.id else { continue }

            let listener = firebaseManager.observeGroup(groupId: groupId) { [weak self] updatedGroup in
                guard let self = self, let updatedGroup = updatedGroup else { return }

                Task { @MainActor in
                    if let index = self.groups.firstIndex(where: { $0.id == groupId }) {
                        self.groups[index] = updatedGroup
                    }
                }
            }

            groupListeners[groupId] = listener
        }
    }

    private func removeAllListeners() {
        groupListeners.values.forEach { $0.remove() }
        groupListeners.removeAll()
    }
}
