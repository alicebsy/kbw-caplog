import SwiftUI

// MARK: - 5탭 정의 (search, folder, home, share, mypage)
enum CaplogTab: String, CaseIterable, Identifiable {
    case search, folder, home, share, mypage
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .folder: return "folder.fill"
        case .home:   return "house.fill"
        case .share:  return "square.and.arrow.up"
        case .mypage: return "person.fill"
        }
    }
    var label: String {
        switch self {
        case .search: return "검색"
        case .folder: return "보관함"
        case .home:   return "홈"
        case .share:  return "공유"
        case .mypage: return "마이"
        }
    }
}

struct CaplogTabBar: View {
    var selected: CaplogTab
    var onSelect: (CaplogTab) -> Void

    var body: some View {
        ZStack {
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .black.opacity(0.05), radius: 8, y: -1)

            HStack {
                ForEach(CaplogTab.allCases) { tab in
                    Button { onSelect(tab) } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(selected == tab ? Brand.accent : Brand.textSub)
                                .scaleEffect(selected == tab ? 1.1 : 1.0)
                                .animation(.spring(duration: 0.25), value: selected)
                            Text(tab.label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(selected == tab ? Brand.accent : Brand.textSub)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
        }
        .frame(height: 60)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

// UIKit blur 래퍼
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
