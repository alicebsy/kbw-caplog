import SwiftUI
import Photos

struct Register4_2View: View {
    @StateObject private var photos = PhotoAccess()
    @State private var goNext = false

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Text("스크린샷 접근")
                    .font(.system(size: 22, weight: .bold))
                Text(photos.isAuthorized
                     ? "스크린샷 \(photos.screenshotCount)장 인덱싱 준비 완료."
                     : "스크린샷을 불러와 자동 분류를 시작합니다.")
                    .foregroundStyle(.secondary)
                PermissionRow(
                    title: "스크린샷 접근",
                    desc: photos.isAuthorized
                        ? "필요 시 설정에서 접근 수준을 조정할 수 있습니다."
                        : "사진 접근 권한을 허용해 주세요.",
                    actionTitle: photos.isAuthorized ? "허용됨" : "허용"
                ) {
                    if photos.isAuthorized {
                        photos.openSettingsIfLimited()
                    } else {
                        photos.request()
                    }
                }
                Button("다음") { goNext = true }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!photos.isAuthorized)
                    .navigationDestination(isPresented: $goNext) {
                        Register4_3View()
                    }
            }
            .padding()
            .padding(.bottom, 40)
            Spacer()
        }
    }
}
