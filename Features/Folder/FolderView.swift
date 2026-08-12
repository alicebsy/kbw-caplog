import SwiftUI

// MARK: - Entry (탭에서 이걸 불러오면 됨)
struct FolderView: View {
    @StateObject private var manager = CardManager.shared

    var body: some View {
        NavigationStack {
            FolderCategoryListView()
                .environmentObject(manager)
                // NavigationStack은 바깥에서 준 safeAreaInset을 자기 콘텐츠까지
                // 전달하지 않습니다. 그래서 여백은 반드시 스택 안쪽에서 잡습니다.
                .caplogTabBarInset()
                .navigationTitle("폴더")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(uiColor: .systemGroupedBackground), for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
                // 탭 루트라 돌아갈 화면이 없습니다. 예전엔 dismiss()를 부르는
                // chevron.left가 얹혀 있었는데, 눌러도 아무 일도 일어나지 않았습니다.
                .navigationBarBackButtonHidden(true)
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
    /// 카드로 만든 스크린샷 개수. ScreenshotIndexer는 ObservableObject가 아니라서
    /// 계산 프로퍼티로 두면 값이 바뀌어도 화면이 다시 그려지지 않습니다.
    @State private var screenshotRecognizedCount: Int = 0

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
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(FolderCategory.allCases) { category in
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.18)) {
                                selectedCategory = category
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: category.symbolName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(category.color)
                                    .symbolRenderingMode(.monochrome)
                                    .frame(width: 32, height: 32)
                                    .accessibilityHidden(true)

                                Text(category.displayName)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(
                                        selectedCategory == category
                                        ? category.color
                                        : .primary
                                    )
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        selectedCategory == category
                                        ? category.color.opacity(0.1)
                                        : Color.clear
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .accessibilityLabel(category.displayName)
                        .accessibilityAddTraits(
                            selectedCategory == category ? .isSelected : []
                        )
                    }

                    // 갤러리·인식 정보 + 최근 인식 카드 (왼쪽 맨 아래)
                    VStack(alignment: .leading, spacing: 10) {
                        Divider()
                            .padding(.vertical, 8)
                        if let total = galleryScreenshotCount {
                            Text("갤러리 \(total)장 · 인식 \(screenshotRecognizedCount)장")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.brandTextSub)
                        } else {
                            Text("인식 완료 \(screenshotRecognizedCount)장")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.brandTextSub)
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
                            .foregroundStyle(Color.accentGreenTint)
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
            // 화면 절반. UIScreen.main.bounds는 iOS 16부터 권장되지 않고,
            // 회전이나 분할 화면에서 실제 컨테이너 폭과 어긋납니다.
            .containerRelativeFrame(.horizontal) { width, _ in width * 0.5 }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .onAppear {
                screenshotRecognizedCount = ScreenshotIndexer.shared.processedScreenshotCount
                Task { galleryScreenshotCount = await ScreenshotIndexer.fetchGalleryScreenshotCount() }
            }

            // --- 오른쪽: 소분류 리스트 ---
            List {
                ForEach(orderedGroupKeys, id: \.self) { key in
                    Section {
                        if !key.isEmpty {
                            Text(key)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.brandTextSub)
                                .listRowInsets(EdgeInsets(top: 24, leading: 20, bottom: 8, trailing: 20))
                        }
                        ForEach(groupedSubcategories[key] ?? []) { sub in
                            NavigationLink {
                                FolderItemListView(category: selectedCategory, subcategory: sub.name)
                                    .environmentObject(manager)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: Card.symbolName(forSubcategory: sub.name))
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(selectedCategory.color)
                                        .symbolRenderingMode(.monochrome)
                                        .frame(width: 30, height: 30)
                                        .accessibilityHidden(true)

                                    Text(sub.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color.primary)
                                }
                            }
                            .accessibilityLabel("\(sub.name) 폴더")
                            .listRowInsets(EdgeInsets(top: 9, leading: 20, bottom: 9, trailing: 20))
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
        // 밀어서 들어온 화면도 탭바가 그대로 떠 있으므로 여백이 필요합니다.
        .caplogTabBarInset()
        .navigationTitle(subcategory)
        .navigationBarTitleDisplayMode(.inline)

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
                .foregroundStyle(category.color.opacity(0.7))
            Text("아직 \(subcategory) 항목이 없어요")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            Text("스크린샷을 저장하면 여기에 쌓여요")
                .font(.subheadline)
                .foregroundColor(Color.brandTextSub)
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
                        .foregroundStyle(Color.pointBlue.opacity(0.7))
                    Text("인식된 카드가 없어요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Text("마이페이지에서 스크린샷을 가져와 보세요")
                        .font(.subheadline)
                        .foregroundColor(Color.brandTextSub)
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
        // 밀어서 들어온 화면도 탭바가 그대로 떠 있으므로 여백이 필요합니다.
        .caplogTabBarInset()
        .navigationTitle("최근 인식 카드")
        .navigationBarTitleDisplayMode(.inline)
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
