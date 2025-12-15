import SwiftUI

struct SearchFilterChips: View {
    @Binding var selected: CategoryPair?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MajorCategory.allCases, id: \.self) { major in
                    Menu(major.rawValue) {
                        ForEach(subs(for: major), id: \.self) { sub in
                            Button(sub.rawValue) { selected = CategoryPair(major: major, sub: sub) }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                if selected != nil {
                    Button("초기화") { selected = nil }
                        .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
        }
    }

    private func subs(for major: MajorCategory) -> [SubCategory] {
        switch major {
        case .study:    return [.lecture, .assignment, .exam]
        case .schedule: return [.appointment, .ticket, .travel]
        case .shopping: return [.receipt, .wishlist, .coupon]
        case .document: return [.idCard, .contract, .certificate]
        case .etc:      return [.unknown]
        }
    }
}
