import SwiftUI

struct CardEditSheet: View {
    var card: Card
    var onSave: (String) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 12) {
            Text("상세정보 수정 (스텁)").font(.title3.bold())
            Text("todo: 나중에 실제 폼으로 교체")
                .foregroundStyle(Color.brandTextSub)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.medium, .large])
    }
}
