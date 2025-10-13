//이것도 임시 화면입니다.
import SwiftUI

struct MyPageView: View {
    var body: some View {
        VStack {
            Text("마이페이지 화면")
                .font(.title3.bold())
                .padding(.top, 80)
            Spacer()
        }
        .navigationTitle("My Page")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}
