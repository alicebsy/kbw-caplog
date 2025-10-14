import SwiftUI
import Combine

struct FolderView: View {
    @StateObject private var manager = FolderManager()
    @State private var selectedCategory: FolderCategory = .info
    @State private var selectedSub: String? = nil
    @State private var showCategory = false
    @State private var showShare = false
    @State private var showAdd = false

    // 공유 상태
    @State private var selectedItem: FolderItem? = nil

    // 탭 라우팅 상태
    @State private var goHome = false
    @State private var goSearch = false
    @State private var goShare  = false
    @State private var goMyPage = false

    var filteredItems: [FolderItem] {
        manager.items.filter {
            $0.category == selectedCategory && (selectedSub == nil || $0.subcategory == selectedSub)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // 헤더
                HStack {
                    Text("\(selectedCategory.rawValue) \(selectedSub ?? "")")
                        .font(.system(size: 22, weight: .semibold))
                    Spacer()
                    Button { showCategory.toggle() } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    Button { showShare.toggle() } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button { showAdd.toggle() } label: {
                        Image(systemName: "plus.circle")
                    }
                }
                .padding()
                Divider()

                // 카드 리스트
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredItems) { item in
                            FolderCardView(item: item)
                                .onTapGesture {
                                    selectedItem = item
                                    showShare = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .sheet(isPresented: $showCategory) {
                FolderCategorySheet(selectedCategory: $selectedCategory, selectedSub: $selectedSub)
            }
            .sheet(isPresented: $showShare) {
                if let selected = selectedItem {
                    ShareSheetView(
                        target: selected,
                        friends: [
                            .init(id: UUID(), name: "다혜", avatar: "avatar1"),
                            .init(id: UUID(), name: "서연", avatar: "avatar2"),
                            .init(id: UUID(), name: "민하", avatar: "avatar3")
                        ]
                    ) { ids, msg in
                        print("폴더 공유 → \(ids), \(msg)")
                    }
                    .presentationDetents([.height(350)])
                }
            }
            .sheet(isPresented: $showAdd) { FolderAddSheet() }
            .navigationTitle("Folder")
            .navigationBarTitleDisplayMode(.inline)

            // ✅ 하단 탭
            .safeAreaInset(edge: .bottom) {
                CaplogTabBar(selected: .folder) { tab in
                    switch tab {
                    case .home:   goHome = true
                    case .search: goSearch = true
                    case .share:  goShare = true
                    case .mypage: goMyPage = true
                    case .folder: break
                    }
                }
            }

            // 라우팅 목적지
            .navigationDestination(isPresented: $goHome)   { HomeView() }
            .navigationDestination(isPresented: $goSearch) { SearchView { _ in } }
            .navigationDestination(isPresented: $goShare)  { ShareView  { _ in } }
            .navigationDestination(isPresented: $goMyPage) { MyPageView() }
        }
    }
}
