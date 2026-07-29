import Foundation
import Combine
import Photos
import SwiftUI

final class PhotoAccess: ObservableObject {
    @Published var status: PHAuthorizationStatus = .notDetermined
    @Published var screenshotCount: Int = 0

    init() {
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
