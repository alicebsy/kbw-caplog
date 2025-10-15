import SwiftUI

struct MyPageProfileHeader: View {
    let displayName: String
    let email: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) { // ← 간격 줄이기 (기존: 10)
            // ✅ displayName이 비어있지 않으면 'OO 님'으로 출력
            if !displayName.isEmpty {
                Text("\(displayName) 님")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 8)
            }

            Text(email)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 6) // ← 하단 패딩도 약간 줄여줌
    }
}
