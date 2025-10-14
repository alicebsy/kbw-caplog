import SwiftUI

// MARK: - 탭 정의
enum CaplogTab: String, CaseIterable, Identifiable {
    case search, folder, home, share, myPage
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .folder: return "folder.fill"
        case .home:   return "house.fill"
        case .share:  return "square.and.arrow.up"
        case .myPage: return "person.fill"
        }
    }
    var label: String {
        switch self {
        case .search: return "검색"
        case .folder: return "폴더"
        case .home:   return "홈"
        case .share:  return "공유"
        case .myPage: return "마이"
        }
    }
}

// MARK: - 탭 바
struct CaplogTabBar: View {
    let selected: CaplogTab
    let onSelect: (CaplogTab) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 10, y: -1)

            HStack {
                ForEach(CaplogTab.allCases) { tab in
                    Button { onSelect(tab) } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(selected == tab ? .primary : .secondary)
                                .scaleEffect(selected == tab ? 1.1 : 1.0)
                                .animation(.spring(duration: 0.24), value: selected)
                            Text(tab.label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(selected == tab ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
        }
        .frame(height: 64)
        .padding(.horizontal, 22)
        .padding(.bottom, 2)   // 바닥에 더 붙게
    }
}
