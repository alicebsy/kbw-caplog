import SwiftUI

struct NotificationView: View {
    @State private var notifications: [AppNotification] = []
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    if notifications.isEmpty {
                        emptyState
                    } else {
                        notificationList
                    }
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadNotifications()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(.caplogGrayMedium)
                .padding(.top, 100)
            
            Text("새로운 알림이 없습니다")
                .font(.body)
                .foregroundColor(.caplogGrayDark)
        }
    }
    
    // MARK: - Notification List
    private var notificationList: some View {
        LazyVStack(spacing: 12) {
            ForEach(notifications) { notification in
                NotificationRow(notification: notification)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Load Notifications
    private func loadNotifications() {
        notifications = AppNotification.mockNotifications
    }
}

//
// MARK: - 🔥 수정된 Notification Model 전체 코드
//

struct AppNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let message: String
    let timestamp: Date
    let cardID: UUID?
    var isRead: Bool = false
}

// MARK: - 알림 타입 (3종만 남김)
enum NotificationType {
    case locationBased         // 위치 기반: 장소 근처 추천
    case timeBased             // 시간 기반: 쿠폰 만료, D-day
    case scheduleBased         // 일정 기반: 일정 빈 시간 추천
    
    var icon: String {
        switch self {
        case .locationBased: return "mappin.and.ellipse"
        case .timeBased: return "clock"
        case .scheduleBased: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .locationBased: return .homeGreen
        case .timeBased: return .orange
        case .scheduleBased: return .caplogGrayMedium
        }
    }
}


// MARK: - 🔥 친구 / 시스템 알림 제거한 새로운 mock 데이터 전체
extension AppNotification {
    static var mockNotifications: [AppNotification] {
        let now = Date()
        
        return [
            // 1) 시간 기반
            AppNotification(
                type: .timeBased,
                message: "스타벅스 무료 음료 쿠폰이 3일 뒤 만료됩니다.",
                timestamp: now.addingTimeInterval(-60 * 5),
                cardID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")
            ),
            
            AppNotification(
                type: .timeBased,
                message: "메가커피 아메리카노 쿠폰이 일주일 뒤 만료됩니다.",
                timestamp: now.addingTimeInterval(-60 * 30),
                cardID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")
            ),
            
            // 2) 위치 기반
            AppNotification(
                type: .locationBased,
                message: "서대문구 근처에 계시네요! 근처 낭만식탁을 추천해드려요.",
                timestamp: now.addingTimeInterval(-60 * 60),
                cardID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")
            ),
            
            AppNotification(
                type: .locationBased,
                message: "신촌역 근처입니다. 저장해둔 아콘스톨 김밥은 어떠세요?",
                timestamp: now.addingTimeInterval(-60 * 90),
                cardID: UUID(uuidString: "00000000-0000-0000-0000-000000000004")
            ),
            
            // 3) 일정 기반
            AppNotification(
                type: .scheduleBased,
                message: "오늘 오후 3~5시 일정이 비어 있어요. 가까운 카페를 추천드려요!",
                timestamp: now.addingTimeInterval(-60 * 120),
                cardID: UUID(uuidString: "00000000-0000-0000-0000-000000000005")
            )
        ]
    }
}

//
// MARK: - Notification Row (건드리면 안 되는 부분 → 그대로 유지)
//

struct NotificationRow: View {
    let notification: AppNotification
    @State private var showCardDetail = false
    @State private var relatedCard: Card?
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                if notification.cardID != nil {
                    showCardDetail = true
                }
            }) {
                HStack(alignment: .top, spacing: 12) {
                    // 아이콘
                    ZStack {
                        Circle()
                            .fill(notification.type.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: notification.type.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(notification.type.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        // 메시지
                        Text(notification.message)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // 시간
                        Text(timeString(for: notification.timestamp))
                            .font(.system(size: 13))
                            .foregroundColor(.caplogGrayMedium)
                    }
                    
                    Spacer()
                    
                    if notification.cardID != nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.caplogGrayMedium)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear {
            if let cardID = notification.cardID {
                Task { @MainActor in
                    relatedCard = CardManager.shared.allCards.first(where: { $0.id == cardID })
                }
            }
        }
        .sheet(isPresented: $showCardDetail) {
            if let card = relatedCard {
                NavigationView {
                    CardDetailView(card: card)
                }
            }
        }
    }
    
    private func timeString(for date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "방금 전"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)분 전"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)시간 전"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)일 전"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M월 d일"
            return formatter.string(from: date)
        }
    }
}
