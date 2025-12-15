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
            }
            // ✅ 텍스트를 위로 살짝 이동하여 중심 맞춤
            .offset(y: -2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
