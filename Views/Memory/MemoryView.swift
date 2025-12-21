//
//  MemoryView.swift
//  SnapShareEvent
//
//  Created on 2025-12-21.
//

import SwiftUI
import SDWebImageSwiftUI

struct MemoryView: View {
    let group: Group
    @StateObject private var viewModel: MemoryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedPhoto: Photo?

    init(group: Group) {
        self.group = group
        _viewModel = StateObject(wrappedValue: MemoryViewModel(group: group))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.photos.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    memoryListView
                }

                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadPhotos()
            }
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("写真がありません")
                .font(.headline)

            Text("カメラで写真を撮影してグループに共有しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var memoryListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Stats
                statsView

                // Photos by Date
                ForEach(viewModel.sortedDates(), id: \.self) { date in
                    VStack(alignment: .leading, spacing: 12) {
                        // Date Header
                        Text(viewModel.memoryTitle(for: date))
                            .font(.headline)
                            .padding(.horizontal)

                        // Photo Grid
                        let photosForDate = viewModel.photos(for: date)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                            ForEach(photosForDate) { photo in
                                PhotoThumbnail(photo: photo)
                                    .onTapGesture {
                                        selectedPhoto = photo
                                    }
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var statsView: some View {
        HStack(spacing: 20) {
            VStack {
                Text("\(viewModel.totalPhotoCount)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("写真")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 40)

            VStack {
                Text("\(viewModel.totalDays)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("日間")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 40)

            VStack {
                Text("\(group.memberIds.count)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("メンバー")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnail: View {
    let photo: Photo

    var body: some View {
        WebImage(url: URL(string: photo.thumbnailURL ?? photo.imageURL))
            .resizable()
            .placeholder {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                    )
            }
            .indicator(.activity)
            .transition(.fade)
            .scaledToFill()
            .frame(height: 120)
            .clipped()
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let photo: Photo
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()

                    WebImage(url: URL(string: photo.imageURL))
                        .resizable()
                        .indicator(.activity)
                        .transition(.fade)
                        .scaledToFit()

                    Spacer()

                    // Photo Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(photo.uploaderIcon)
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text(photo.uploaderName)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(formattedDate(photo.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            if let effect = photo.appliedEffect {
                                Text(effect.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct MemoryView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryView(group: Group(name: "テストグループ", createdBy: "user1"))
    }
}
