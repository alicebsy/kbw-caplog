import SwiftUI

// MARK: - Entry (탭에서 이걸 불러오면 됨)
struct FolderView: View {
    @StateObject private var manager = CardManager.shared
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            FolderCategoryListView()
                .environmentObject(manager)
                .navigationTitle("Folder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(uiColor: .systemGroupedBackground), for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
        }
        // 하단 커스텀 탭바 높이만큼 여백을 둬서 폴더 콘텐츠가 가려지지 않도록 처리
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: 76)
        }
        .onAppear {
            Task {
                await manager.loadAllCards()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cardUpdated)) { _ in
            Task {
                await manager.loadAllCards()
            }
        }
    }
}

// MARK: - 1) 대분류 + 소분류 리스트 (피그마 디자인 최종본)
struct FolderCategoryListView: View {
    @EnvironmentObject private var manager: CardManager
    @State private var selectedCategory: FolderCategory = .info
    /// 갤러리에 있는 스크린샷 전체 개수 (폴더 보일 때마다 갱신)
    @State private var galleryScreenshotCount: Int?

    private var screenshotRecognizedCount: Int {
        ScreenshotIndexer.shared.processedScreenshotCount
    }

    private var groupedSubcategories: [String: [FolderSubcategory]] {
        Dictionary(grouping: selectedCategory.subcategories, by: { $0.displayGroup })
    }
    
    private var orderedGroupKeys: [String] {
        var keys: [String] = []
        for subcategory in selectedCategory.subcategories {
            if !keys.contains(subcategory.displayGroup) {
                keys.append(subcategory.displayGroup)
            }
        }
        return keys
    }

    var body: some View {
        HStack(spacing: 0) {
            // --- 왼쪽: 대분류 리스트 + 하단 갤러리/최근 인식 ---
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(FolderCategory.allCases) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(selectedCategory == category ? Color.myPageSectionGreen : Color.clear)
                                    .frame(width: 4, height: 24)

                                Text("\(category.emoji) \(category.rawValue)")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(
                                        selectedCategory == category
                                        ? Color.myPageSectionGreen
                                        : .primary
                                    )
                                    .lineLimit(1)

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 20)
                    }

                    // 갤러리·인식 정보 + 최근 인식 카드 (왼쪽 맨 아래)
                    VStack(alignment: .leading, spacing: 10) {
                        Divider()
                            .padding(.vertical, 8)
                        if let total = galleryScreenshotCount {
                            Text("갤러리 \(total)장 · 인식 \(screenshotRecognizedCount)장")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("인식 완료 \(screenshotRecognizedCount)장")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        NavigationLink {
                            FolderRecentCardsView()
                                .environmentObject(manager)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 12))
                                Text("최근 인식 카드")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(Color.myPageSectionGreen)
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
            .frame(width: UIScreen.main.bounds.width / 2)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .onAppear {
                Task { galleryScreenshotCount = await ScreenshotIndexer.fetchGalleryScreenshotCount() }
            }

            // --- 오른쪽: 소분류 리스트 ---
            List {
                ForEach(orderedGroupKeys, id: \.self) { key in
                    Section {
                        if !key.isEmpty {
                            Text(key)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.gray)
                                .listRowInsets(EdgeInsets(top: 24, leading: 20, bottom: 8, trailing: 20))
                        }
                        ForEach(groupedSubcategories[key] ?? []) { sub in
                            NavigationLink {
                                FolderItemListView(category: selectedCategory, subcategory: sub.name)
                                    .environmentObject(manager)
                            } label: {
                                Text("\(Card.emoji(forSubcategory: sub.name)) \(sub.name)")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(Color.primary)
                            }
                            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

// MARK: - FolderItemListView 및 FolderItemRow
struct FolderItemListView: View {
    @EnvironmentObject private var manager: CardManager
    let category: FolderCategory
    let subcategory: String
    
    @State private var selectedCard: Card? = nil
    @State private var editingCard: Card? = nil
    @State private var fullscreenImage: String? = nil
    
    private var filtered: [Card] {
        manager.cards(for: category, subcategory: subcategory)
    }
    
    var body: some View {
        List {
            if filtered.isEmpty {
                emptyState
                    .listRowSeparator(.hidden)
            }
            else {
                ForEach(filtered) { item in
                    UnifiedCardView(
                        card: item,
                        style: .row,
                        onTap: { selectedCard = item },
                        onMore: { editingCard = item },
                        onTapImage: {
                            if let first = item.screenshotURLs.first {
                                fullscreenImage = first
                            } else {
                                fullscreenImage = item.thumbnailName
                            }
                            CardManager.shared.markCardAsViewed(item)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                    .id("\(item.id)-\(item.updatedAt.timeIntervalSince1970)")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(subcategory)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                    .background(Color.black.opacity(0.12))
                Rectangle()
                    .fill(Color(.systemBackground))
                    .frame(height: 12)
            }
        }
        
        .sheet(item: $editingCard) { card in
            CardEditSheet(card: card) {
                // 카드 저장 후 폴더 뷰 갱신
                Task {
                    await manager.loadAllCards()
                }
            }
        }
        
        .fullScreenCover(isPresented: Binding(
            get: { fullscreenImage != nil },
            set: { if !$0 { fullscreenImage = nil } }
        )) {
            if let name = fullscreenImage {
                HomeImagePopupView(imageName: name)
            }
        }
        .navigationDestination(item: $selectedCard) { card in
            CardDetailView(card: card)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 44))
                .foregroundStyle(Color.myPageSectionGreen.opacity(0.5))
            Text("아직 \(subcategory) 항목이 없어요")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            Text("스크린샷을 저장하면 여기에 쌓여요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
    }
}

// MARK: - 최근 인식 카드 한눈에 보기 (인식된 N개를 카테고리 없이 전체 목록으로)
struct FolderRecentCardsView: View {
    @EnvironmentObject private var manager: CardManager
    @State private var selectedCard: Card? = nil
    @State private var editingCard: Card? = nil
    @State private var fullscreenImage: String? = nil
    
    private var recentCards: [Card] {
        manager.recommendedCards(limit: 50)
    }
    
    var body: some View {
        List {
            if recentCards.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.myPageSectionGreen.opacity(0.5))
                    Text("인식된 카드가 없어요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Text("마이페이지에서 스크린샷을 가져와 보세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            } else {
                ForEach(recentCards) { item in
                    UnifiedCardView(
                        card: item,
                        style: .row,
                        onTap: { selectedCard = item },
                        onMore: { editingCard = item },
                        onTapImage: {
                            if let first = item.screenshotURLs.first {
                                fullscreenImage = first
                            } else {
                                fullscreenImage = item.thumbnailName
                            }
                            CardManager.shared.markCardAsViewed(item)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                    .id("\(item.id)-\(item.updatedAt.timeIntervalSince1970)")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("최근 인식 카드")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                    .background(Color.black.opacity(0.12))
                Rectangle()
                    .fill(Color(.systemBackground))
                    .frame(height: 12)
            }
        }
        .sheet(item: $editingCard) { card in
            CardEditSheet(card: card) {
                Task { await manager.loadAllCards() }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { fullscreenImage != nil },
            set: { if !$0 { fullscreenImage = nil } }
        )) {
            if let name = fullscreenImage {
                HomeImagePopupView(imageName: name)
            }
        }
        .navigationDestination(item: $selectedCard) { card in
            CardDetailView(card: card)
        }
    }
}
