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

    // ✅ 一度だけ実行を保証するフラグ
    private var hasLoadedGroups = false
    private var listenersSetup = false
    private var qrObserverSetup = false

    var currentUserId: String? {
        UserDefaults.standard.userId
    }

    init() {
        // ✅ init()では何もしない：起動時の処理を最小化
    }

    deinit {
        // deinitは非同期コンテキストではないため、直接リスナーを削除
        groupListeners.values.forEach { $0.remove() }
        groupListeners.removeAll()
    }

    // MARK: - Group Operations

    /// ✅ 段階的にグループを読み込み（起動時のメモリスパイクを防ぐ）
    func loadGroupsGradually() async {
        // ✅ 既に読み込み済みなら何もしない
        guard !hasLoadedGroups else {
            print("⚠️ [MainViewModel] loadGroupsGradually: 既に読み込み済みのためスキップ")
            return
        }

        guard let userId = currentUserId else { return }

        hasLoadedGroups = true
        isLoading = true
        errorMessage = nil

        do {
            print("📝 [MainViewModel] Firestoreからグループ取得開始")

            // ✅ ステップ1: データ取得のみ（リスナーは後で）
            groups = try await firebaseManager.getUserGroups(userId: userId)
            isLoading = false

            print("✅ [MainViewModel] グループ取得完了: \(groups.count)件")

            // ✅ ステップ2: 500ms待機してからリスナー設定（メモリスパイク回避）
            try? await Task.sleep(nanoseconds: 500_000_000)

            // ✅ ステップ3: リアルタイム監視を段階的に設定
            await setupGroupListenersGradually()

            // ✅ QRCodeObserverは最後に設定
            setupQRCodeObserverOnce()

        } catch {
            isLoading = false
            hasLoadedGroups = false  // エラー時はリトライ可能にする
            errorMessage = "グループの読み込みに失敗しました: \(error.localizedDescription)"
            print("❌ [MainViewModel] グループ読み込みエラー: \(error)")
        }
    }

    /// グループ一覧を読み込み（従来版：グループ作成後などに使用）
    func loadGroups() async {
        guard let userId = currentUserId else { return }

        isLoading = true
        errorMessage = nil

        do {
            groups = try await firebaseManager.getUserGroups(userId: userId)
            isLoading = false

            // ✅ リスナーフラグをリセットして再設定
            listenersSetup = false
            setupGroupListeners()
        } catch {
            isLoading = false
            errorMessage = "グループの読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    /// 新しいグループを作成
    func createGroup() async {
        // デバッグ: 認証状態を確認
        print("🔍 [Debug] currentUserId: \(String(describing: currentUserId))")
        print("🔍 [Debug] Firebase Auth currentUser: \(String(describing: firebaseManager.currentUserId))")

        guard let userId = currentUserId else {
            errorMessage = "ユーザーIDが取得できません。再度ログインしてください。"
            print("❌ [Error] currentUserId is nil")
            return
        }

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

            print("📝 [Debug] グループを作成中: \(group.name)")
            print("📝 [Debug] createdBy: \(userId)")

            let groupId = try await firebaseManager.createGroup(group)
            print("✅ [Debug] グループ作成成功: \(groupId)")
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

    /// ✅ QRCodeObserverを一度だけ設定
    private func setupQRCodeObserverOnce() {
        guard !qrObserverSetup else {
            print("⚠️ [MainViewModel] QRCodeObserver: 既に設定済みのためスキップ")
            return
        }

        qrObserverSetup = true
        print("📝 [MainViewModel] QRCodeObserver設定")

        qrCodeService.$scannedCode
            .compactMap { $0 }
            .sink { [weak self] qrString in
                Task {
                    await self?.joinGroupFromQR(qrString: qrString)
                }
            }
            .store(in: &cancellables)
    }

    private func setupQRCodeObserver() {
        setupQRCodeObserverOnce()
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

    /// ✅ リスナーを段階的に設定（起動時のメモリスパイク回避）
    private func setupGroupListenersGradually() async {
        // ✅ 既に設定済みなら何もしない
        guard !listenersSetup else {
            print("⚠️ [MainViewModel] GroupListeners: 既に設定済みのためスキップ")
            return
        }

        listenersSetup = true
        print("📝 [MainViewModel] GroupListeners設定開始")

        // 既存のリスナーを削除
        removeAllListeners()

        // ✅ 各グループのリスナーを順次設定（200msずつ遅延）
        for (index, group) in groups.enumerated() {
            guard let groupId = group.id else { continue }

            print("📝 [MainViewModel] Listener設定中: \(index + 1)/\(groups.count)")

            let listener = firebaseManager.observeGroup(groupId: groupId) { [weak self] updatedGroup in
                guard let self = self, let updatedGroup = updatedGroup else { return }

                Task { @MainActor in
                    if let index = self.groups.firstIndex(where: { $0.id == groupId }) {
                        self.groups[index] = updatedGroup
                    }
                }
            }

            groupListeners[groupId] = listener

            // ✅ 次のリスナー設定まで200ms待機（同時実行を避ける）
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        print("✅ [MainViewModel] GroupListeners設定完了: \(groupListeners.count)件")
    }

    private func removeAllListeners() {
        groupListeners.values.forEach { $0.remove() }
        groupListeners.removeAll()
    }
}
