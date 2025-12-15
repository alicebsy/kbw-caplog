import SwiftUI
import Combine
import UserNotifications

@MainActor
final class NotificationPermission: ObservableObject {
    enum Status { case notDetermined, authorized, denied }
    @Published var status: Status = .notDetermined

    init() { refresh() }

    func refresh() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                switch settings.authorizationStatus {
                case .notDetermined: self.status = .notDetermined
                case .authorized, .provisional, .ephemeral: self.status = .authorized
                case .denied: self.status = .denied
                @unknown default: self.status = .denied
                }
            }
        }
    }

    // 🔒 메인 스레드에서만 요청 + APNs 등록 제거(임시)
    func request() {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                    Task { @MainActor in
                        self.refresh()
                    }
                }
        }
    }

    // 🔒 설정 열기도 메인에서
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }

    var isAuthorized: Bool { status == .authorized }
    var actionTitle: String {
        switch status {
        case .authorized: return "허용됨"
        case .denied:     return "설정에서 허용"
        case .notDetermined: return "허용"
        }
    }
}
