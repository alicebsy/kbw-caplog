import SwiftUI

// MARK: - Entry (탭에서 이걸 불러오면 됨)
struct FolderView: View {
    @StateObject private var manager = CardManager()
    
    // ✅ dismiss 환경 변수 추가
    @Environment(\.dismiss) private var dismiss
    
    // 탭 선택 및 화면 전환을 위한 상태 변수
    @State private var selectedTab: CaplogTab = .folder
    @State private var goHome = false
    @State private var goSearch = false
    @State private var goShare  = false
    @State private var goMyPage = false

    var body: some View {
        // ✅ 여기는 NavigationStack 유지 (Folder 내부 네비게이션용)
        NavigationStack {
            FolderCategoryListView()
                .environmentObject(manager)
                .navigationTitle("Folder")
                .navigationBarTitleDisplayMode(.inline)

                // ✅ 네비게이션 바를 '불투명한 흰색'으로 고정
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.white, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
                
                // ✅ 커스텀 백버튼 (아이콘만)
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

                .safeAreaInset(edge: .bottom) {
                    CaplogTabBar(selected: selectedTab) { tab in
                        selectedTab = tab
                        switch tab {
                        case .home:   goHome = true
                        case .search: goSearch = true
                        case .share:  goShare = true
                        case .myPage: goMyPage = true
                        case .folder: break
                        }
                    }
                }

                .navigationDestination(isPresented: $goHome)   { HomeView() }
                .navigationDestination(isPresented: $goSearch) { SearchView() }
                .navigationDestination(isPresented: $goShare)  { ShareView() }
                .navigationDestination(isPresented: $goMyPage) { MyPageView() }
                
                // ✅ 데이터 로드
                .onAppear {
                    Task {
                        await manager.loadAllCards()
                    }
                }
        }
    }
}

// MARK: - 1) 대분류 + 소분류 리스트 (피그마 디자인 최종본)
struct FolderCategoryListView: View {
    @EnvironmentObject private var manager: CardManager
    @State private var selectedCategory: FolderCategory = .info

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
            // --- 왼쪽: 대분류 리스트 ---
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(FolderCategory.allCases) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(selectedCategory == category ? category.color : Color.clear)
                                    .frame(width: 4, height: 24)

                                Text("\(category.emoji) \(category.rawValue)")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(
                                        selectedCategory == category
                                        ? .homeGreenDark
                                        : .black
                                    )
                                    .lineLimit(1)

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 20)
                    }
                }
                .padding(.top, 16)
            }
            .frame(width: UIScreen.main.bounds.width / 2)
            .background(Color.white)

            // --- 오른쪽: 소분류 리스트 ---
            List {
                ForEach(orderedGroupKeys, id: \.self) { key in
                    Section {
                        ForEach(groupedSubcategories[key] ?? []) { sub in
                            NavigationLink {
                                FolderItemListView(category: selectedCategory, subcategory: sub.name)
                                    .environmentObject(manager)
                            } label: {
                                Text(sub.name)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(Color.primary)
                            }
                            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                        }
                    } header: {
                        if !key.isEmpty {
                            Text(key)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.gray)
                                .padding(.leading, 20)
                                .padding(.bottom, 4)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .background(Color(red: 246/255, green: 248/255, blue: 246/255))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - FolderItemListView 및 FolderItemRow
struct FolderItemListView: View {
    @EnvironmentObject private var manager: CardManager
    let category: FolderCategory
    let subcategory: String
    
    // ✅ 상세/공유/편집/이미지 팝업 상태
    @State private var selectedCard: Card? = nil
    @State private var shareTarget: Card? = nil
    @State private var editingCard: Card? = nil
    @State private var fullscreenImage: String? = nil
    
    // ✅ FriendManager 사용
    @StateObject private var friendManager = FriendManager.shared
    
    private var filtered: [Card] {
        let result = manager.cards(for: category, subcategory: subcategory)
        print("📁 FolderItemListView - category: \(category.rawValue), subcategory: \(subcategory)")
        print("📁 Filtered cards: \(result.count)개")
        print("📁 All cards in manager: \(manager.allCards.count)개")
        return result
    }
    var body: some View {
        List {
            if filtered.isEmpty { emptyState }
            else {
                ForEach(filtered) { item in
                    UnifiedCardView(
                        card: item,
                        style: .row,  // ✅ compact → row로 변경
                        onTap: { selectedCard = item },  // ✅ 상세 화면
                        onShare: { shareTarget = item }, // ✅ 공유
                        onMore: { editingCard = item },  // ✅ 편집
                        onTapImage: {  // ✅ 이미지 전체보기
                            if let first = item.screenshotURLs.first {
                                fullscreenImage = first
                            } else {
                                fullscreenImage = item.thumbnailName
                            }
                        }
                    )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .background(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(subcategory)
        .navigationBarTitleDisplayMode(.inline)
        
        // ✅ 공유 시트
        .sheet(item: $shareTarget) { target in
            ShareSheetView(
                target: target,
                friends: friendManager.friends  // ✅ FriendManager 사용
            ) { ids, msg in
                print("Folder 공유 → 대상: \(ids), 메시지: \(msg)")
            }
            .presentationDetents([.height(350)])
        }
        
        // ✅ 편집 시트
        .sheet(item: $editingCard) { card in
            CardEditSheet(card: card) { updated in
                print("업데이트: \(updated)")
            }
            .presentationDetents([.medium, .large])
        }
        
        // ✅ 전체 이미지 팝업
        .fullScreenCover(isPresented: Binding(
            get: { fullscreenImage != nil },
            set: { if !$0 { fullscreenImage = nil } }
        )) {
            if let name = fullscreenImage {
                HomeImagePopupView(imageName: name)
            }
        }
        
        // ✅ 상세 화면 이동
        .navigationDestination(item: $selectedCard) { card in
            CardDetailView(card: card)
        }
    }
    private var emptyState: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(.secondary)
            Text("아직 \(subcategory) 항목이 없어요")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - FolderItemRow 삭제됨
// → UnifiedCardView(style: .compact) 사용
