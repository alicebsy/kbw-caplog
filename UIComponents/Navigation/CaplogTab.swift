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
        case .myPage: return "마이페이지"
        }
    }
}

// MARK: - 탭 바 치수
/// NavigationStack은 바깥에서 준 safeAreaInset을 자기 콘텐츠까지 전달하지 않습니다.
/// 그래서 탭 화면들은 각자 하단 여백을 잡아야 하는데, 그 값이 화면마다
/// 76 / 72처럼 제각각 박혀 있었습니다. 여기 한 곳에서만 관리합니다.
enum CaplogTabBarMetrics {
    /// 탭바가 실제로 차지하는 높이(홈 인디케이터 영역 제외)
    static let height: CGFloat = 58
    /// 콘텐츠가 탭바에 닿지 않도록 두는 간격
    static let gap: CGFloat = 12
    /// 탭 화면이 하단에 확보해야 하는 여백
    static var contentInset: CGFloat { height + gap }
}

extension View {
    /// 탭바에 가리지 않도록 하단 여백을 확보합니다. 탭 루트 화면에만 붙입니다.
    func caplogTabBarInset() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: CaplogTabBarMetrics.contentInset)
        }
    }
}

// MARK: - 탭 바
struct CaplogTabBar: View {
    let selected: CaplogTab
    let onSelect: (CaplogTab) -> Void

    var body: some View {
        HStack {
            ForEach(CaplogTab.allCases) { tab in
                Button { onSelect(tab) } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(selected == tab ? Color.accentGreenTint : Color.brandTextSub)
                            .scaleEffect(selected == tab ? 1.08 : 1.0)
                            .animation(.spring(duration: 0.24), value: selected)
                        Text(tab.label)
                            .font(.system(size: 11, weight: .medium))
                            // .secondary는 흰 면에서 3.26:1이라 11pt 글자로는 AA 미달입니다.
                            .foregroundStyle(selected == tab ? Color.accentGreenTint : Color.brandTextSub)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        // 예전엔 좌우 22pt를 띄운 알약 모양에 .ultraThinMaterial을 채웠습니다.
        // 그러면 바 자체가 반투명한 데다 좌우 여백과 홈 인디케이터 영역으로
        // 스크롤 콘텐츠가 그대로 보여서, 탭바가 화면과 겹친 것처럼 읽혔습니다.
        // 화면 폭을 다 쓰고 아래 끝까지 불투명하게 덮습니다.
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
