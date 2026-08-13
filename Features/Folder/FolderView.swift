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

// MARK: - 1) 대분류 칩 + 소분류 그룹 리스트
/// 예전 구현은 화면을 좌우로 반 갈라 왼쪽에 대분류, 오른쪽에 소분류를 담았습니다.
/// 390pt 화면에서는 양쪽 다 160pt밖에 안 돼서 이름이 잘리고, 어느 대분류에 무엇이
/// 들어 있는지는 눌러 보기 전까지 알 수 없었습니다(좌우 분할은 아이패드 문법입니다).
/// 대분류는 칩으로 항상 띄우고, 소분류는 전체 폭을 쓰는 그룹 리스트로 내리고
/// 개수를 오른쪽에 붙였습니다. 목록을 훑는 것만으로 카테고리가 읽힙니다.
struct FolderCategoryListView: View {
    @EnvironmentObject private var manager: CardManager
    /// 로그인·서버 없이 화면만 확인할 때 쓰는 카드 목록. nil이면 실제 카드를 씁니다.
    var previewCards: [Card]? = nil

    @State private var selectedCategory: FolderCategory = .info
    /// 갤러리에 있는 스크린샷 전체 개수 (폴더 보일 때마다 갱신)
    @State private var galleryScreenshotCount: Int?
    /// 카드로 만든 스크린샷 개수. ScreenshotIndexer는 ObservableObject가 아니라서
    /// 계산 프로퍼티로 두면 값이 바뀌어도 화면이 다시 그려지지 않습니다.
    @State private var screenshotRecognizedCount: Int = 0
    @State private var isImporting = false

    private var cards: [Card] { previewCards ?? manager.allCards }

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

    /// 선택한 대분류의 소분류별 카드 개수. 한 번만 훑고 사전으로 들고 있습니다.
    private var countsBySubcategory: [String: Int] {
        var counts: [String: Int] = [:]
        for card in cards where card.category == selectedCategory {
            counts[card.subcategory, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                categoryChips

                ForEach(orderedGroupKeys, id: \.self) { key in
                    if !key.isEmpty {
                        CapSectionHeader(key)
                    } else {
                        Spacer().frame(height: 8)
                    }
                    subcategoryGroup(for: key)
                }

                galleryNote
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("폴더")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink {
                    FolderRecentCardsView()
                        .environmentObject(manager)
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.homeGreenTint)
                }
                .accessibilityLabel("최근 인식 카드")

                if isImporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        importScreenshots()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.homeGreenTint)
                    }
                    .accessibilityLabel("스크린샷에서 카드 가져오기")
                }
            }
        }
        .onAppear {
            screenshotRecognizedCount = ScreenshotIndexer.shared.processedScreenshotCount
            Task { galleryScreenshotCount = await ScreenshotIndexer.fetchGalleryScreenshotCount() }
        }
    }

    // MARK: 대분류 칩
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(FolderCategory.allCases) { category in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            selectedCategory = category
                        }
                    } label: {
                        CapChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(category.displayName)
                    .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .padding(.bottom, 8)
    }

    // MARK: 소분류 그룹
    private func subcategoryGroup(for key: String) -> some View {
        let subcategories = groupedSubcategories[key] ?? []
        let counts = countsBySubcategory

        return CapGroup {
            ForEach(Array(subcategories.enumerated()), id: \.element.id) { index, sub in
                let count = counts[sub.name] ?? 0

                NavigationLink {
                    FolderItemListView(category: selectedCategory, subcategory: sub.name)
                        .environmentObject(manager)
                } label: {
                    CapRow(
                        title: sub.name,
                        value: "\(count)",
                        showsChevron: false,
                        isDimmed: count == 0
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(sub.name) 폴더, \(count)개")

                if index < subcategories.count - 1 {
                    CapSeparator()
                }
            }
        }
    }

    // MARK: 갤러리·인식 각주
    private var galleryNote: some View {
        Group {
            if let total = galleryScreenshotCount {
                Text("갤러리 \(total)장 · 인식 \(screenshotRecognizedCount)장")
            } else {
                Text("인식 완료 \(screenshotRecognizedCount)장")
            }
        }
        .font(.system(size: 13))
        .foregroundStyle(Color.brandTextSub)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
        .padding(.top, 12)
    }

    private func importScreenshots() {
        guard !isImporting else { return }
        isImporting = true
        Task {
            await ScreenshotIndexer.shared.forceImportRecentScreenshots(limit: 20)
            await manager.loadAllCards()
            screenshotRecognizedCount = ScreenshotIndexer.shared.processedScreenshotCount
            galleryScreenshotCount = await ScreenshotIndexer.fetchGalleryScreenshotCount()
            isImporting = false
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

#if DEBUG
// MARK: - 로그인·서버 없이 폴더 화면만 확인하는 통로
/// 백엔드가 내려가 있으면 로그인 화면을 지나갈 수 없어서 폴더를 볼 방법이 없습니다.
/// Xcode 캔버스(아래 #Preview)로 보거나, 실행 인자에 `-CaplogFolderPreview`를 넣고
/// 앱을 켜면 이 화면으로 바로 들어갑니다. DEBUG 빌드에만 들어갑니다.
struct FolderPreviewHost: View {
    var body: some View {
        NavigationStack {
            FolderCategoryListView(previewCards: Card.sampleCards)
                .environmentObject(CardManager.shared)
        }
    }
}

#Preview("폴더 · 칩 + 소분류") {
    FolderPreviewHost()
}
#endif
