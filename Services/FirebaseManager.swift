//
//  FirebaseManager.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let cloudinaryService = CloudinaryService.shared

    private init() {
        // Firebaseの設定は AppDelegate or SceneDelegate で行う
    }

    // MARK: - Authentication

    /// 匿名認証
    func signInAnonymously() async throws -> String {
        let result = try await auth.signInAnonymously()
        return result.user.uid
    }

    /// 現在のユーザーID
    var currentUserId: String? {
        return auth.currentUser?.uid
    }

    // MARK: - User Operations

    /// ユーザーを作成
    func createUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is required"])
        }

        try await db.collection(Constants.Firebase.usersCollection)
            .document(userId)
            .setData(user.toDictionary())
    }

    /// ユーザー情報を取得
    func getUser(userId: String) async throws -> User? {
        let document = try await db.collection(Constants.Firebase.usersCollection)
            .document(userId)
            .getDocument()

        guard document.exists else { return nil }
        return try document.data(as: User.self)
    }

    // MARK: - Group Operations

    /// グループを作成
    func createGroup(_ group: Group) async throws -> String {
        // デバッグログ
        print("📝 [FirebaseManager] createGroup開始")
        print("📝 [FirebaseManager] コレクション名: \(Constants.Firebase.groupsCollection)")
        print("📝 [FirebaseManager] 認証状態: \(String(describing: auth.currentUser?.uid))")
        print("📝 [FirebaseManager] グループデータ: \(group.toDictionary())")

        do {
            let docRef = try await db.collection(Constants.Firebase.groupsCollection)
                .addDocument(data: group.toDictionary())

            print("✅ [FirebaseManager] グループ作成成功: \(docRef.documentID)")
            return docRef.documentID
        } catch {
            print("❌ [FirebaseManager] グループ作成エラー: \(error)")
            print("❌ [FirebaseManager] エラー詳細: \(error.localizedDescription)")
            throw error
        }
    }

    /// グループに参加
    func joinGroup(groupId: String, userId: String) async throws {
        let groupRef = db.collection(Constants.Firebase.groupsCollection).document(groupId)

        try await groupRef.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])

        // UserDefaultsにも保存
        var joinedIds = UserDefaults.standard.joinedGroupIds
        if !joinedIds.contains(groupId) {
            joinedIds.append(groupId)
            UserDefaults.standard.joinedGroupIds = joinedIds
        }
    }

    /// グループ情報を取得
    func getGroup(groupId: String) async throws -> Group? {
        let document = try await db.collection(Constants.Firebase.groupsCollection)
            .document(groupId)
            .getDocument()

        guard document.exists else { return nil }
        return try document.data(as: Group.self)
    }

    /// ユーザーが参加しているグループ一覧を取得
    func getUserGroups(userId: String) async throws -> [Group] {
        // ✅ arrayContains + order by はインデックスが必要なため、order by を削除
        // クライアント側でソートする
        let snapshot = try await db.collection(Constants.Firebase.groupsCollection)
            .whereField("memberIds", arrayContains: userId)
            .getDocuments()

        // ✅ クライアント側で createdAt の降順にソート
        let groups = snapshot.documents.compactMap { try? $0.data(as: Group.self) }
        return groups.sorted { $0.createdAt > $1.createdAt }
    }

    /// グループのリアルタイム監視
    func observeGroup(groupId: String, completion: @escaping (Group?) -> Void) -> ListenerRegistration {
        return db.collection(Constants.Firebase.groupsCollection)
            .document(groupId)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, snapshot.exists else {
                    completion(nil)
                    return
                }

                let group = try? snapshot.data(as: Group.self)
                completion(group)
            }
    }

    // MARK: - Photo Operations

    /// 写真をアップロード（Cloudinaryを使用）
    func uploadPhoto(
        image: UIImage,
        groupId: String,
        uploadedBy: String,
        uploaderName: String,
        uploaderIcon: String,
        appliedEffect: PhotoEffect?
    ) async throws -> Photo {
        // 1. Cloudinaryにアップロード
        let folder = CloudinaryService.folderPath(for: groupId)
        let photoId = UUID().uuidString

        let uploadResult = try await cloudinaryService.uploadImage(
            image,
            folder: folder,
            publicId: photoId
        )

        // 2. Firestoreに写真情報を保存
        let photo = Photo(
            groupId: groupId,
            uploadedBy: uploadedBy,
            uploaderName: uploaderName,
            uploaderIcon: uploaderIcon,
            imageURL: uploadResult.secureUrl,
            thumbnailURL: uploadResult.thumbnailUrl,
            appliedEffect: appliedEffect
        )

        let docRef = try await db.collection(Constants.Firebase.photosCollection)
            .addDocument(data: photo.toDictionary())

        // 3. グループの写真カウントを更新
        let groupRef = db.collection(Constants.Firebase.groupsCollection).document(groupId)
        try await groupRef.updateData([
            "photoCount": FieldValue.increment(Int64(1))
        ])

        var savedPhoto = photo
        savedPhoto.id = docRef.documentID
        return savedPhoto
    }

    /// グループの写真一覧を取得
    func getPhotos(groupId: String, limit: Int = 50) async throws -> [Photo] {
        let snapshot = try await db.collection(Constants.Firebase.photosCollection)
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Photo.self) }
    }

    /// 写真のリアルタイム監視
    func observePhotos(groupId: String, completion: @escaping ([Photo]) -> Void) -> ListenerRegistration {
        return db.collection(Constants.Firebase.photosCollection)
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    completion([])
                    return
                }

                let photos = snapshot.documents.compactMap { try? $0.data(as: Photo.self) }
                completion(photos)
            }
    }

    /// 特定の日付範囲の写真を取得（メモリー機能用）
    func getPhotosByDateRange(groupId: String, startDate: Date, endDate: Date) async throws -> [Photo] {
        let snapshot = try await db.collection(Constants.Firebase.photosCollection)
            .whereField("groupId", isEqualTo: groupId)
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("createdAt", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Photo.self) }
    }
}
