import SwiftUI
import Combine
@preconcurrency import CoreLocation

@MainActor
final class AppNotificationCenter: ObservableObject {
    static let shared = AppNotificationCenter()

    @Published private(set) var notifications: [AppNotification] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var locationMessage: String?

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    private let cardManager = CardManager.shared
    private let cardService = CardService()
    private let locationPermission = LocationPermission()
    private let defaults = UserDefaults.standard
    private let readIDsKey = "AppNotificationCenter_readIDs"
    private let dismissedIDsKey = "AppNotificationCenter_dismissedIDs"

    private var readIDs: Set<String>
    private var dismissedIDs: Set<String>

    private init() {
        readIDs = Set(defaults.stringArray(forKey: readIDsKey) ?? [])
        dismissedIDs = Set(defaults.stringArray(forKey: dismissedIDsKey) ?? [])
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        locationMessage = nil
        defer { isLoading = false }

        if cardManager.allCards.isEmpty {
            await cardManager.loadAllCards()
        }

        let now = Date()
        let dayKey = Self.dayKey(for: now)
        var generated = deadlineNotifications(
            from: cardManager.allCards,
            now: now,
            dayKey: dayKey
        )

        if let currentLocation = await locationPermission.currentLocation() {
            do {
                let nearbyCards = try await cardService.fetchNearbyCards(
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude,
                    radiusMeters: 1_000,
                    limit: 3
                )
                let areaName = await currentAreaName(for: currentLocation)
                let locationItems = locationNotifications(
                    from: nearbyCards,
                    areaName: areaName,
                    now: now,
                    dayKey: dayKey
                )
                generated.append(contentsOf: locationItems)
                if locationItems.isEmpty {
                    locationMessage = "현재 위치 1km 안에는 저장해 둔 장소가 없어요."
                }
            } catch {
                locationMessage = "주변의 저장 장소를 확인하지 못했어요."
            }
        } else if locationPermission.isDeniedOrRestricted {
            locationMessage = "위치 알림을 보려면 설정에서 위치 접근을 허용해 주세요."
        } else if !locationPermission.isAuthorized {
            locationMessage = "위치 권한을 허용하면 주변의 저장 장소를 알려드려요."
        }

        var seen = Set<String>()
        generated = generated.filter { seen.insert($0.id).inserted }
        let activeIDs = Set(generated.map(\.id))

        readIDs.formIntersection(activeIDs)
        dismissedIDs.formIntersection(activeIDs)
        persistState()

        notifications = generated
            .filter { !dismissedIDs.contains($0.id) }
            .map { item in
                var updated = item
                updated.isRead = readIDs.contains(item.id)
                return updated
            }

        if notifications.isEmpty,
           cardManager.errorMessage != nil,
           cardManager.allCards.isEmpty {
            errorMessage = "카드를 불러오지 못해 알림을 만들 수 없어요."
        }
    }

    func markAsRead(_ notification: AppNotification) {
        guard !notification.isRead else { return }
        readIDs.insert(notification.id)
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
        persistState()
    }

    func markAllAsRead() {
        for notification in notifications {
            readIDs.insert(notification.id)
        }
        notifications = notifications.map { item in
            var updated = item
            updated.isRead = true
            return updated
        }
        persistState()
    }

    func dismiss(_ notification: AppNotification) {
        dismissedIDs.insert(notification.id)
        notifications.removeAll { $0.id == notification.id }
        persistState()
    }

    private func deadlineNotifications(
        from cards: [Card],
        now: Date,
        dayKey: String
    ) -> [AppNotification] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        return cards.compactMap { card -> (Card, Date, Int)? in
            guard let deadline = NotificationDateParser.date(from: card.expiryText) else {
                return nil
            }
            let deadlineDay = calendar.startOfDay(for: deadline)
            let daysLeft = calendar.dateComponents(
                [.day],
                from: today,
                to: deadlineDay
            ).day ?? Int.max
            guard (0...14).contains(daysLeft) else { return nil }
            return (card, deadlineDay, daysLeft)
        }
        .sorted {
            if $0.2 == $1.2 {
                return $0.0.title.localizedCompare($1.0.title) == .orderedAscending
            }
            return $0.2 < $1.2
        }
        .prefix(5)
        .map { card, deadline, daysLeft in
            let isCoupon = card.subcategory == "쿠폰"
            let action = isCoupon ? "만료" : "마감"
            let title: String
            let message: String

            switch daysLeft {
            case 0:
                title = "오늘 \(action)"
                message = "‘\(card.title)’의 \(action)일이 오늘이에요."
            case 1:
                title = "\(action) 하루 전"
                message = "‘\(card.title)’의 \(action)까지 하루 남았어요."
            default:
                title = "\(action) 임박"
                message = "‘\(card.title)’의 \(action)까지 \(daysLeft)일 남았어요."
            }

            return AppNotification(
                id: "deadline:\(card.id.uuidString):\(dayKey)",
                type: .deadline,
                title: title,
                message: message,
                timestamp: now,
                card: card,
                detail: Self.deadlineString(deadline)
            )
        }
    }

    private func locationNotifications(
        from nearbyCards: [Card],
        areaName: String?,
        now: Date,
        dayKey: String
    ) -> [AppNotification] {
        nearbyCards
            .filter { Self.distanceInMeters(from: $0.fields["거리"]) <= 1_000 }
            .prefix(3)
            .map { nearbyCard in
                let card = cardManager.allCards.first(where: { $0.id == nearbyCard.id })
                    ?? nearbyCard
                let area = areaName ?? "현재 위치"
                let distance = nearbyCard.fields["거리"]
                let distanceText = distance.map { " \($0) 거리에" } ?? " 근처에"

                return AppNotification(
                    id: "location:\(card.id.uuidString):\(dayKey)",
                    type: .location,
                    title: "저장한 장소가 근처에 있어요",
                    message: "\(area)에 계시네요. 저장해 둔 ‘\(card.title)’이\(distanceText) 있어요.",
                    timestamp: now,
                    card: card,
                    detail: nearbyCard.fields["주소"] ?? nearbyCard.fields["장소명"]
                )
            }
    }

    private static func distanceInMeters(from value: String?) -> Double {
        guard let value else { return .infinity }
        let normalized = value
            .lowercased()
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        if normalized.hasSuffix("km"),
           let distance = Double(normalized.dropLast(2)) {
            return distance * 1_000
        }
        if normalized.hasSuffix("m"),
           let distance = Double(normalized.dropLast()) {
            return distance
        }
        return .infinity
    }

    private func currentAreaName(for location: CLLocation) async -> String? {
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            return placemark.subLocality
                ?? placemark.locality
                ?? placemark.administrativeArea
        } catch {
            return nil
        }
    }

    private func persistState() {
        defaults.set(readIDs.sorted(), forKey: readIDsKey)
        defaults.set(dismissedIDs.sorted(), forKey: dismissedIDsKey)
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private static func deadlineString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}

struct AppNotification: Identifiable {
    enum NotificationType {
        case location
        case deadline

        var icon: String {
            switch self {
            case .location: return "location.fill"
            case .deadline: return "calendar.badge.clock"
            }
        }

        var color: Color {
            switch self {
            case .location: return .homeGreen
            case .deadline: return .orange
            }
        }
    }

    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let card: Card
    let detail: String?
    var isRead = false
}

private enum NotificationDateParser {
    static func date(from rawValue: String) -> Date? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) {
            return date
        }
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: value) {
            return date
        }

        let normalized = value
            .replacingOccurrences(of: "년", with: ".")
            .replacingOccurrences(of: "월", with: ".")
            .replacingOccurrences(of: "일", with: "")
            .replacingOccurrences(of: " ", with: "")

        let formats = [
            "yyyy.M.d.", "yyyy.M.d", "yyyy-MM-dd", "yyyy/MM/dd",
            "yy.M.d.", "yy.M.d", "yy-MM-dd", "yy/MM/dd"
        ]
        for format in formats {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            formatter.isLenient = false
            if let date = formatter.date(from: normalized) {
                return date
            }
        }
        return nil
    }
}

struct NotificationView: View {
    @StateObject private var notificationCenter = AppNotificationCenter.shared

    var body: some View {
        Group {
            if notificationCenter.isLoading && notificationCenter.notifications.isEmpty {
                ProgressView("알림을 확인하는 중...")
            } else if notificationCenter.notifications.isEmpty {
                emptyState
            } else {
                notificationList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if notificationCenter.unreadCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("모두 읽음") {
                        notificationCenter.markAllAsRead()
                    }
                    .font(.subheadline)
                }
            }
        }
        .task {
            await notificationCenter.refresh()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("새로운 알림이 없어요", systemImage: "bell.slash")
        } description: {
            VStack(spacing: 6) {
                Text(
                    notificationCenter.errorMessage
                        ?? "마감이 가까워지거나 저장한 장소 근처에 가면 여기에서 알려드려요."
                )
                if let locationMessage = notificationCenter.locationMessage {
                    Text(locationMessage)
                }
            }
        } actions: {
            Button("다시 확인") {
                Task { await notificationCenter.refresh() }
            }
        }
    }

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let locationMessage = notificationCenter.locationMessage {
                    Label(locationMessage, systemImage: "location.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }

                ForEach(notificationCenter.notifications) { notification in
                    NotificationRow(
                        notification: notification,
                        onRead: {
                            notificationCenter.markAsRead(notification)
                        },
                        onDelete: {
                            withAnimation {
                                notificationCenter.dismiss(notification)
                            }
                        }
                    )
                }
            }
            .padding(16)
        }
        .refreshable {
            await notificationCenter.refresh()
        }
    }
}

private struct NotificationRow: View {
    let notification: AppNotification
    let onRead: () -> Void
    let onDelete: () -> Void

    @State private var showCardDetail = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onRead()
                CardManager.shared.markCardAsViewed(notification.card)
                showCardDetail = true
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(notification.type.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: notification.type.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(notification.type.color)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            if !notification.isRead {
                                Circle()
                                    .fill(Color.unreadBadgeRed)
                                    .frame(width: 7, height: 7)
                            }
                            Text(notification.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        Text(notification.message)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            Text(timeString(for: notification.timestamp))
                            if let detail = notification.detail, !detail.isEmpty {
                                Text("·")
                                Text(detail)
                                    .lineLimit(1)
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 4)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                UnifiedCardView(
                    card: notification.card,
                    style: .compact,
                    onTap: {
                        onRead()
                        CardManager.shared.markCardAsViewed(notification.card)
                        showCardDetail = true
                    }
                )
                .environment(\.notificationCardWidth, true)

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color(uiColor: .systemGray5))
                        .clipShape(Circle())
                }
                .accessibilityLabel("알림 숨기기")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            notification.isRead
                ? Color(uiColor: .systemBackground)
                : Color.homeGreenLight.opacity(0.18)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showCardDetail) {
            NavigationStack {
                CardDetailView(card: notification.card)
            }
        }
    }

    private func timeString(for date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "방금 전" }
        if interval < 3_600 { return "\(Int(interval / 60))분 전" }
        if interval < 86_400 { return "\(Int(interval / 3_600))시간 전" }
        return "\(Int(interval / 86_400))일 전"
    }
}

#Preview {
    NavigationStack {
        NotificationView()
    }
}
