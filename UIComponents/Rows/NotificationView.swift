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
        // 목업 알림 데이터 생성
        notifications = AppNotification.mockNotifications
    }
}

// MARK: - Notification Model
struct AppNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let message: String
    let timestamp: Date
    let cardID: UUID?
    var isRead: Bool = false
    
    enum NotificationType {
        case locationBased
        case couponExpiring
        case friendActivity
        case systemUpdate
        
        var icon: String {
            switch self {
            case .locationBased: return "location.fill"
            case .couponExpiring: return "tag.fill"
            case .friendActivity: return "person.2.fill"
            case .systemUpdate: return "bell.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .locationBased: return .homeGreen
            case .couponExpiring: return .orange
            case .friendActivity: return .blue
            case .systemUpdate: return .caplogGrayMedium
            }
        }
    }
    
    // MARK: - Mock Data
    static var mockNotifications: [AppNotification] {
        let now = Date()
        
        return [
            // 쿠폰 만료 알림
            AppNotification(
                type: .couponExpiring,
                message: "스타벅스 무료 음료 쿠폰이 3일 후 만료됩니다. 빨리 사용해 주세요!",
                timestamp: now.addingTimeInterval(-60 * 5),
                cardID: MockCardIDs.starbucksCoupon
            ),
            AppNotification(
                type: .couponExpiring,
                message: "메가커피 아메리카노 쿠폰이 일주일 후 만료됩니다.",
                timestamp: now.addingTimeInterval(-60 * 30),
                cardID: MockCardIDs.megacoffeeCoupon
            ),
            
            // 위치 기반 추천
            AppNotification(
                type: .locationBased,
                message: "서대문구에 도착하셨네요! 근처 낭만식탁 추천드려요. 여기 어떠세요?",
                timestamp: now.addingTimeInterval(-60 * 60),
                cardID: MockCardIDs.nangman
            ),
            AppNotification(
                type: .locationBased,
                message: "신촌역 근처에 계시군요! 아콘스톨에서 김밥 드시는 건 어떠세요?",
                timestamp: now.addingTimeInterval(-60 * 90),
                cardID: MockCardIDs.acornstol
            ),
            
            // 친구 활동 알림
            AppNotification(
                type: .friendActivity,
                message: "우민하님이 카페 이라운드를 공유했습니다.",
                timestamp: now.addingTimeInterval(-60 * 120),
                cardID: MockCardIDs.cafeEround
            ),
            AppNotification(
                type: .friendActivity,
                message: "강다혜님이 이목리막국수를 저장했습니다.",
                timestamp: now.addingTimeInterval(-60 * 180),
                cardID: MockCardIDs.makguksu
            ),
            
            // 쿠폰 만료 추가
            AppNotification(
                type: .couponExpiring,
                message: "이마트24 5천원권이 내일 만료됩니다. 오늘 사용하세요!",
                timestamp: now.addingTimeInterval(-60 * 240),
                cardID: MockCardIDs.emart24Coupon
            ),
            
            // 위치 기반 추가
            AppNotification(
                type: .locationBased,
                message: "대현동에서 점심 추천! 사장님돈까스 어떠세요?",
                timestamp: now.addingTimeInterval(-60 * 300),
                cardID: MockCardIDs.donkatsu
            ),
            
            // 시스템 알림
            AppNotification(
                type: .systemUpdate,
                message: "저장한 카드가 10개를 돌파했어요! 계속해서 멋진 순간들을 기록하세요 ✨",
                timestamp: now.addingTimeInterval(-60 * 360),
                cardID: nil
            )
        ]
    }
}

// MARK: - Notification Row
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
                    
                    // 카드가 있으면 화살표 표시
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
            
            // 카드가 있으면 카드 미리보기 표시
            if let card = relatedCard {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.leading, 68)
                    
                    UnifiedCardView(
                        card: card,
                        style: .compact,
                        onTap: {
                            showCardDetail = true
                        }
                    )
                    .padding(.leading, 68)
                    .padding(.trailing, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
            }
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear {
            // 동기적으로 카드 로드
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
    
    // MARK: - Time String
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

#Preview {
    NavigationView {
        NotificationView()
    }
}
