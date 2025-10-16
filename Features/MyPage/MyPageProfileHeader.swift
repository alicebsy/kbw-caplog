import SwiftUI

struct MyPageProfileHeader: View {
    let displayName: String
    let email: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(Color.caplogGrayMedium, Color.caplogGrayLight)

            VStack(alignment: .leading, spacing: 6) {
                if !displayName.isEmpty {
                    Text("\(displayName) 님")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    Text("강배우 님")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
                
                Text(email)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            // --- ⬇️ 추가된 수정사항 ⬇️ ---
            // 텍스트 그룹 전체를 y축으로 2만큼 살짝 내려서 시각적 중심을 맞춥니다.
            .offset(y: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
