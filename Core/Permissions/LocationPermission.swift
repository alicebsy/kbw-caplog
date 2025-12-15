import Foundation
import Combine
import CoreLocation
import UIKit

final class LocationPermission: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var status: CLAuthorizationStatus = .notDetermined
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        // 초기 스냅샷만 읽고, 이후엔 콜백으로만 갱신
        status = manager.authorizationStatus
    }

    var isAuthorized: Bool {
        status == .authorizedWhenInUse || status == .authorizedAlways
    }

    var isDeniedOrRestricted: Bool {
        status == .denied || status == .restricted
    }

    /// 권한 요청. 거부/제한, 글로벌 OFF면 설정으로 유도.
    func request() {
        guard CLLocationManager.locationServicesEnabled() else {
            openSettings(); return
        }
        guard !isDeniedOrRestricted else {
            openSettings(); return
        }
        // 팝업은 iOS가 알아서 띄움. 여기서 별도 트리거(예: startUpdatingLocation) 불필요
        manager.requestWhenInUseAuthorization()
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // iOS 14+ 권한 상태 변경 콜백 (여기서만 상태 갱신)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
    }

    // 디버그용
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("CLLocationManager error:", error.localizedDescription)
    }
}
