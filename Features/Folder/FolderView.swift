import SwiftUI

// MARK: - Entry (탭에서 이걸 불러오면 됨)
struct FolderView: View {
    @StateObject private var manager = FolderManager()
    var body: some View {
        NavigationStack {
            FolderCategoryListView()
                .environmentObject(manager)
                .navigationTitle("Folder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        }
    }
}

// MARK: - 1) 대분류 리스트 (첫 화면)
struct FolderCategoryListView: View {
    @EnvironmentObject private var manager: FolderManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Category")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(FolderCategory.allCases) { category in
                        NavigationLink {
                            FolderSubcategoryListView(category: category)
                                .environmentObject(manager)
                        } label: {
                            HStack(spacing: 14) {
                                // 이모지/색 포인트
                                Text(category.emoji)
                                    .font(.system(size: 18))

                                Text(category.rawValue)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.primary)

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - 2) 소분류 리스트
struct FolderSubcategoryListView: View {
    @EnvironmentObject private var manager: FolderManager
    let category: FolderCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(spacing: 12) {
                    ForEach(category.subcategories) { sub in
                        NavigationLink {
                            FolderItemListView(category: category, subcategory: sub.name)
                                .environmentObject(manager)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    if let group = sub.group, !group.isEmpty {
                                        Text(group)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(sub.name)
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(Color.primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        // ✅ ToolbarItem을 개별로 사용 + Button(action:) 구문으로 변경
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* 정렬/필터 액션 자리 */ }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* 공유 시트 자리 */ }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* 소분류 추가 액션 자리 */ }) {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Category")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(category.rawValue)
                .font(.system(size: 26, weight: .bold))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - 3) 아이템 리스트 (선택된 카테고리/소분류)
struct FolderItemListView: View {
    @EnvironmentObject private var manager: FolderManager
    let category: FolderCategory
    let subcategory: String

    private var filtered: [FolderItem] {
        manager.items.filter { $0.category == category && $0.subcategory == subcategory }
    }

    var body: some View {
        List {
            Section {
                if filtered.isEmpty {
                    emptyState
                } else {
                    ForEach(filtered) { item in
                        FolderItemRow(item: item)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .background(Color.clear)
                    }
                }
            } header: {
                Text("\(category.rawValue) - \(subcategory)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .navigationTitle(subcategory)
        .navigationBarTitleDisplayMode(.inline)
        // ✅ 여기서도 같은 방식으로 고정
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* 정렬/필터 자리 */ }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* 공유 시트 */ }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* 아이템 추가 */ }) {
                    Image(systemName: "plus.circle")
                }
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

// MARK: - 아이템 카드 (필요 시 카테고리별로 fields 표시 커스터마이즈 가능)
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

                // fields 요약 (상위 2~3개만)
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
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
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
