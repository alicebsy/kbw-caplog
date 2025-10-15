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
        DispatchQueue.global(qos: .userInitiated).async {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
            
            var count = 0
            allPhotos.enumerateObjects { asset, _, _ in
                if asset.mediaType == .image {
                    count += 1
                }
            }
            
            DispatchQueue.main.async {
                self.screenshotCount = count
            }
        }
    }
}
