import SwiftUI

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button {
            dismiss()                  // ✅ "바로 전 화면"으로 pop
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
        }
    }
}
