import SwiftUI
import Photos

/// 권한 안내 화면.
///
/// 예전에는 위치·사진·알림을 화면 세 개로 나눠 두고, 각 화면의 "다음" 버튼을
/// 권한이 허용될 때까지 잠가뒀습니다. 문제는 사진 화면이었습니다. iOS는 한 번
/// 거부하면 다시 묻지 않는데 설정으로 가는 길이 없어서, 거기서 앱에 영영
/// 들어가지 못했습니다. 세 개를 한 화면에 모으고, 허용 여부와 상관없이
/// 시작할 수 있게 했습니다. 권한이 실제로 필요한 순간에 다시 물으면 됩니다.
struct Register4_1View: View {
    @ObservedObject var appState: AppState
    @StateObject private var loc = LocationPermission()
    @StateObject private var photos = PhotoAccess()
    @StateObject private var noti = NotificationPermission()

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                content
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
            }
            .background(AuthBackground())
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: scenePhase) { _, phase in
            // 설정 앱에 다녀오면 상태가 바뀌어 있습니다. 위치는 델리게이트가
            // 알아서 갱신하고, 나머지 둘은 직접 다시 읽어야 합니다.
            guard phase == .active else { return }
            noti.refresh()
            photos.refresh()
        }
    }

    private var content: some View {
        VStack(spacing: 28) {
            AuthHeader(
                title: "권한 설정",
                subtitle: "허용해두면 캡처를 자동으로 정리하고 제때 알려드려요."
            )

            VStack(spacing: 12) {
                PermissionRow(
                    icon: "photo.on.rectangle.angled",
                    title: "사진 접근",
                    desc: photoDesc,
                    state: photos.permissionState,
                    action: photos.requestOrOpenSettings
                )

                PermissionRow(
                    icon: "bell.badge",
                    title: "알림",
                    desc: "유효기간이 끝나기 전에 미리 알려드립니다.",
                    state: noti.permissionState,
                    action: {
                        switch noti.status {
                        case .notDetermined: noti.request()
                        case .denied:        noti.openSettings()
                        case .authorized:    break
                        }
                    }
                )

                PermissionRow(
                    icon: "location",
                    title: "위치",
                    desc: "매장 근처에 가면 관련된 카드를 꺼내 보여줍니다.",
                    state: locationState,
                    action: loc.request
                )
            }

            VStack(spacing: 10) {
                Button {
                    // 권한 단계 종료 → StartView가 탭바 화면으로 전환합니다.
                    appState.isLoggedIn = true
                } label: {
                    Text("시작하기").authPrimaryButton()
                }

                Text("허용하지 않아도 시작할 수 있어요. 나중에 iOS 설정에서 바꿀 수 있습니다.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.brandTextMain)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var photoDesc: String {
        switch photos.status {
        case .limited:
            return "선택한 사진만 볼 수 있어요. 설정에서 범위를 넓힐 수 있습니다."
        case .authorized:
            return photos.screenshotCount > 0
                ? "스크린샷 \(photos.screenshotCount)장을 정리할 준비가 됐어요."
                : "스크린샷을 불러와 카드로 분류합니다."
        default:
            return "스크린샷을 불러와 카드로 분류합니다."
        }
    }

    private var locationState: PermissionState {
        if loc.isAuthorized { return .granted }
        if loc.isDeniedOrRestricted { return .denied }
        return .notDetermined
    }
}
