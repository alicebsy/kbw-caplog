import SwiftUI

struct MyPageProfileHeader: View {
    let displayName: String
    let email: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {   // spacing 살짝 늘림
            // ✅ 사용자 이름 + "님" 으로 표시
            Text("\(displayName)님")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 8)

            // 이메일 표시
            Text(email)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
