import Foundation
import Combine
import Photos
import SwiftUI

final class PhotoAccess: ObservableObject {
    @Published var status: PHAuthorizationStatus = .notDetermined
    @Published var screenshotCount: Int = 0

    init() {
        status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if isAuthorized { loadScreenshotsCount() }
    }

    var isAuthorized: Bool {
        status == .authorized || status == .limited
    }

    func request() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { st in
            DispatchQueue.main.async {
                self.status = st
                if self.isAuthorized { self.loadScreenshotsCount() }
            }
        }
    }

    func openSettingsIfLimited() {
        guard status == .limited,
              let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func loadScreenshotsCount() {
        let col = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        ).firstObject
        guard let col else { self.screenshotCount = 0; return }
        let assets = PHAsset.fetchAssets(in: col, options: nil)
        self.screenshotCount = assets.count
    }
}
