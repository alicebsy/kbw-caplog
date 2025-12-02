import SwiftUI

// MARK: - Entry (탭에서 이걸 불러오면 됨)
struct FolderView: View {
    @StateObject private var manager = CardManager.shared
    
    @Environment(\.dismiss) private var dismiss
    
    // 탭 선택 및 화면 전환을 위한 상태 변수
    @State private var selectedTab: CaplogTab = .folder
    @State private var goHome = false
    @State private var goSearch = false
    @State private var goShare  = false
    @State private var goMyPage = false

    var body: some View {
        NavigationStack {
            FolderCategoryListView()
                .environmentObject(manager)
                .navigationTitle("Folder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.white, for: .navigationBar)
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
        .onAppear {
            Task {
                await manager.loadAllCards()
            }
        }
        .navigationDestination(isPresented: $goHome)   { HomeView() }
        .navigationDestination(isPresented: $goSearch) { SearchView() }
        .navigationDestination(isPresented: $goShare)  { ShareView() }
        .navigationDestination(isPresented: $goMyPage) { MyPageView() }
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
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(FolderCategory.allCases) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(selectedCategory == category ? category.color : Color.clear)
                                    .frame(width: 4, height: 24)

                                Text("\(category.emoji) \(category.rawValue)")
                                    .font(.system(size: 18, weight: .bold))
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
                                Text(sub.name)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(Color.primary)
                            }
                            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .background(Color(red: 246/255, green: 248/255, blue: 246/255))
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
    
    @State private var selectedTab: CaplogTab = .folder
    @State private var goHome = false
    @State private var goSearch = false
    @State private var goShare  = false
    @State private var goMyPage = false
    
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
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .background(Color.clear)
                }
            }
        }
        .listStyle(.plain)
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
