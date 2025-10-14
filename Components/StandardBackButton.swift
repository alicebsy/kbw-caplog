import SwiftUI

extension View {
    /// 상단 왼쪽에 표준 백버튼을 부착
    func standardBackButton() -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackButton()
                }
            }
    }
}
