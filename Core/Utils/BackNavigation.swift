import SwiftUI

// iOS 14+ 표준 툴바 백버튼
private struct StandardBackToolbar: ToolbarContent {
    @Environment(\.dismiss) private var dismiss

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
            }
            .accessibilityLabel("뒤로")
        }
    }
}

extension View {
    /// 네비게이션 상단에 표준 뒤로 버튼 추가
    func standardBackButton() -> some View {
        self.toolbar { StandardBackToolbar() }
    }
}
