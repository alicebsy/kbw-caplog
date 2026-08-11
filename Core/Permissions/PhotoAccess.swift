import Foundation
import Combine
import Photos
import SwiftUI

final class PhotoAccess: ObservableObject {
    @Published var status: PHAuthorizationStatus = .notDetermined
    @Published var screenshotCount: Int = 0

    init() { refresh() }

    /// 설정 앱에 다녀오면 상태가 바뀌어 있을 수 있어서 다시 읽습니다.
    func refresh() {
        // 권한 상태를 안전하게 읽기 (권한 없어도 크래시 X)
        DispatchQueue.global(qos: .userInitiated).async {
            let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            DispatchQueue.main.async {
                self.status = authStatus
                if self.isAuthorized {
                    self.loadScreenshotsCount()
                }
            }
        }
    }

    var isAuthorized: Bool {
        status == .authorized || status == .limited
    }

    /// iOS는 한 번 거부하면 다시 묻지 않습니다. 이 상태를 구분하지 않으면
    /// "허용" 버튼이 아무 반응도 없는 버튼이 됩니다(권한 화면이 막히던 원인).
    var isDenied: Bool {
        status == .denied || status == .restricted
    }

    var permissionState: PermissionState {
        if isAuthorized { return .granted }
        if isDenied { return .denied }
        return .notDetermined
    }

    /// 아직 안 물어봤으면 팝업, 이미 거부했으면 설정으로 보냅니다.
    func requestOrOpenSettings() {
        if isDenied {
            openSettings()
        } else {
            request()
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func request() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { st in
            DispatchQueue.main.async {
                self.status = st
                if self.isAuthorized {
                    self.loadScreenshotsCount()
                }
            }
        }
    }

    func openSettingsIfLimited() {
        guard status == .limited,
              let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func loadScreenshotsCount() {
        Task { @MainActor [weak self] in
            self?.screenshotCount = await ScreenshotIndexer.fetchGalleryScreenshotCount()
        }
    }
}
