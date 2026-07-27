import Foundation
import Combine
@preconcurrency import CoreLocation
import UIKit

@MainActor
final class LocationPermission: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var status: CLAuthorizationStatus = .notDetermined
    @Published private(set) var lastErrorMessage: String?
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var locationTimeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
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

    /// 이미 허용된 권한으로 현재 위치를 한 번만 조회합니다. 권한 팝업은 이 메서드에서 띄우지 않습니다.
    func currentLocation() async -> CLLocation? {
        guard CLLocationManager.locationServicesEnabled(), isAuthorized else { return nil }

        if let cached = manager.location,
           abs(cached.timestamp.timeIntervalSinceNow) < 300 {
            return cached
        }

        locationContinuation?.resume(returning: nil)
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            lastErrorMessage = nil
            manager.requestLocation()
            locationTimeoutTask?.cancel()
            locationTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                self?.finishLocationRequest(
                    with: nil,
                    errorMessage: "현재 위치를 가져오는 데 시간이 오래 걸리고 있습니다."
                )
            }
        }
    }

    private func finishLocationRequest(with location: CLLocation?, errorMessage: String? = nil) {
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil
        lastErrorMessage = errorMessage
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    // iOS 14+ 권한 상태 변경 콜백 (여기서만 상태 갱신)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if isDeniedOrRestricted {
            finishLocationRequest(with: nil, errorMessage: "위치 권한이 허용되지 않았습니다.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finishLocationRequest(with: locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finishLocationRequest(with: nil, errorMessage: error.localizedDescription)
        print("CLLocationManager error:", error.localizedDescription)
    }
}
