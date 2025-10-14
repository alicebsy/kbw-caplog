import SwiftUI
import Combine
import UserNotifications

final class NotificationPermission: ObservableObject {
    @Published var granted = false

    func request() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
                DispatchQueue.main.async { self.granted = ok }
            }
    }
}
