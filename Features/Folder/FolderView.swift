import SwiftUI

// MARK: - Entry (탭에서 이걸 불러오면 됨)
struct FolderView: View {
    @StateObject private var manager = FolderManager()
    
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

                // ✅ 네비게이션 바를 '불투명한 흰색'으로 고정
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.white, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)

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
    }
}

// MARK: - 1) 대분류 + 소분류 리스트 (피그마 디자인 최종본)
struct FolderCategoryListView: View {
    @EnvironmentObject private var manager: FolderManager
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
                        .buttonStyle(.plain) // 파란 틴트 방지
                        .padding(.leading, 20)
                    }
                }
                .padding(.top, 16)
            }
            .frame(width: UIScreen.main.bounds.width / 2)
            .background(Color.white) // 왼쪽은 항상 흰색

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
            // ✅ 오른쪽 회색은 타이틀 아래부터 보이도록 (상단 바가 불투명 흰색이므로 자연스레 밑에서 시작됨)
            .background(Color(red: 246/255, green: 248/255, blue: 246/255))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - FolderItemListView 및 FolderItemRow (수정 없음)
struct FolderItemListView: View {
    @EnvironmentObject private var manager: FolderManager
    let category: FolderCategory
    let subcategory: String
    private var filtered: [FolderItem] {
        manager.items.filter { $0.category == category && $0.subcategory == subcategory }
    }
    var body: some View {
        List {
            if filtered.isEmpty { emptyState }
            else {
                ForEach(filtered) { item in
                    FolderItemRow(item: item)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .background(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(subcategory)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { /* 정렬/필터 자리 */ }) { Image(systemName: "line.3.horizontal.decrease.circle") }
                Button(action: { /* 공유 시트 */ }) { Image(systemName: "square.and.arrow.up") }
                Button(action: { /* 아이템 추가 */ }) { Image(systemName: "plus.circle") }
            }
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

private struct FolderItemRow: View {
    let item: FolderItem
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(item.category.rawValue) - \(item.subcategory)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(item.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                if !item.summary.isEmpty {
                    Text(item.summary)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if !item.fields.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(item.fields.keys.prefix(3)), id: \.self) { key in
                            if let value = item.fields[key], !value.isEmpty {
                                Text("\(key): \(value)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                if !item.date.isEmpty {
                    Text(item.date)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 10)
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 64, height: 64)
                .overlay(
                    Group {
                        if let name = item.imageName, !name.isEmpty {
                            Image(name)
                                .resizable().scaledToFill().clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
