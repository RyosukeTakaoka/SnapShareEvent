//
//  MainView.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedGroup: Group?
    @State private var showQRCodeSheet = false
    @State private var navigateToCamera = false
    @State private var navigateToMemory = false

    var body: some View {
        NavigationView {
            ZStack {
                // Group List
                if viewModel.groups.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    groupListView
                }

                // Loading Indicator
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("マイグループ")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.showQRScanner = true
                    }) {
                        Image(systemName: "qrcode.viewfinder")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showCreateGroupSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateGroupSheet) {
                createGroupSheet
            }
            .sheet(isPresented: $viewModel.showQRScanner) {
                QRScannerView(qrCodeService: viewModel.getQRCodeService())
            }
            .sheet(isPresented: $showQRCodeSheet) {
                if let group = selectedGroup {
                    QRCodeView(group: group, qrCodeService: QRCodeService())
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                await viewModel.loadGroups()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("グループがありません")
                .font(.headline)

            Text("新しいグループを作成するか、\nQRコードをスキャンして参加しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var groupListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.groups) { group in
                    GroupCard(group: group)
                        .onTapGesture {
                            selectedGroup = group
                        }
                        .contextMenu {
                            if group.isQRCodeValid {
                                Button(action: {
                                    selectedGroup = group
                                    showQRCodeSheet = true
                                }) {
                                    Label("QRコードを表示", systemImage: "qrcode")
                                }
                            }
                        }
                }
            }
            .padding()
        }
        .sheet(item: $selectedGroup) { group in
            GroupDetailView(group: group)
        }
    }

    private var createGroupSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("グループ情報")) {
                    TextField("グループ名", text: $viewModel.newGroupName)
                }

                Section {
                    Button(action: {
                        Task {
                            await viewModel.createGroup()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("作成")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.newGroupName.isEmpty || viewModel.isLoading)
                }
            }
            .navigationTitle("新規グループ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        viewModel.newGroupName = ""
                        viewModel.showCreateGroupSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Group Card
struct GroupCard: View {
    let group: Group

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(group.name)
                    .font(.headline)

                Spacer()

                if group.isQRCodeValid {
                    Image(systemName: "qrcode")
                        .foregroundColor(.blue)
                }
            }

            HStack(spacing: 16) {
                Label("\(group.memberIds.count)人", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("\(group.photoCount)枚", systemImage: "photo.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formattedDate(group.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Group Detail View
struct GroupDetailView: View {
    let group: Group
    @Environment(\.dismiss) var dismiss
    @State private var showCamera = false
    @State private var showMemory = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Group Info
                VStack(spacing: 8) {
                    Text(group.name)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack(spacing: 20) {
                        Label("\(group.memberIds.count)人", systemImage: "person.2.fill")
                        Label("\(group.photoCount)枚", systemImage: "photo.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()

                // Actions
                VStack(spacing: 16) {
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("写真を撮る")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        showMemory = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("メモリーを見る")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(group: group)
            }
            .fullScreenCover(isPresented: $showMemory) {
                MemoryView(group: group)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
