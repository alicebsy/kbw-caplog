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
                NotificationRow(
                    notification: notification,
                    onDelete: {
                        deleteNotification(notification)
                    }
                )
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
    
    // MARK: - Delete Notification
    private func deleteNotification(_ notification: AppNotification) {
        withAnimation {
            notifications.removeAll { $0.id == notification.id }
        }
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
        let calendar = Calendar.current
        
        // 기프티콘 실제 만료일 (CardModel.swift 참조)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy. MM. dd."
        
        let starbucksExpiry = dateFormatter.date(from: "2025. 12. 10.") ?? now // 스타벅스
        let megacoffeeExpiry = dateFormatter.date(from: "2025. 12. 31.") ?? now // 메가커피
        let emart24Expiry = dateFormatter.date(from: "2025. 12. 05.") ?? now // 이마트24
        
        // 현재 날짜 기준으로 남은 일수 계산
        let daysUntilStarbucks = calendar.dateComponents([.day], from: now, to: starbucksExpiry).day ?? 0
        let daysUntilMegacoffee = calendar.dateComponents([.day], from: now, to: megacoffeeExpiry).day ?? 0
        let daysUntilEmart24 = calendar.dateComponents([.day], from: now, to: emart24Expiry).day ?? 0
        
        var notifications: [AppNotification] = []
        
        // 쿠폰 만료 알림 (만료일이 7일 이내인 경우에만 표시)
        if daysUntilStarbucks > 0 && daysUntilStarbucks <= 7 {
            let message = daysUntilStarbucks == 1
                ? "스타벅스 사랑은 딸기를 타고 쿠폰이 내일 만료됩니다."
                : "스타벅스 사랑은 딸기를 타고 쿠폰이 \(daysUntilStarbucks)일 후 만료됩니다."
            
            notifications.append(AppNotification(
                type: .couponExpiring,
                message: message,
                timestamp: now.addingTimeInterval(-60 * 5),
                cardID: MockCardIDs.starbucksCoupon
            ))
        }
        
        if daysUntilEmart24 > 0 && daysUntilEmart24 <= 7 {
            let message = daysUntilEmart24 == 1
                ? "이마트24 5천원권이 내일 만료됩니다."
                : "이마트24 5천원권이 \(daysUntilEmart24)일 후 만료됩니다."
            
            notifications.append(AppNotification(
                type: .couponExpiring,
                message: message,
                timestamp: now.addingTimeInterval(-60 * 10),
                cardID: MockCardIDs.emart24Coupon
            ))
        }
        
        if daysUntilMegacoffee > 0 && daysUntilMegacoffee <= 14 {
            let message: String
            if daysUntilMegacoffee == 1 {
                message = "메가커피 아메리카노 쿠폰이 내일 만료됩니다."
            } else if daysUntilMegacoffee <= 7 {
                message = "메가커피 아메리카노 쿠폰이 \(daysUntilMegacoffee)일 후 만료됩니다."
            } else {
                let weeks = daysUntilMegacoffee / 7
                message = "메가커피 아메리카노 쿠폰이 \(weeks)주일 후 만료됩니다."
            }
            
            notifications.append(AppNotification(
                type: .couponExpiring,
                message: message,
                timestamp: now.addingTimeInterval(-60 * 30),
                cardID: MockCardIDs.megacoffeeCoupon
            ))
        }
        
        // 위치 기반 추천
        notifications.append(AppNotification(
            type: .locationBased,
            message: "서대문구 근처에 계시네요! 근처 낭만식탁을 추천해드려요.",
            timestamp: now.addingTimeInterval(-60 * 60),
            cardID: MockCardIDs.nangman
        ))
        
        notifications.append(AppNotification(
            type: .locationBased,
            message: "신촌역 근처입니다. 저장해둔 아콘스톨 김밥은 어떠세요?",
            timestamp: now.addingTimeInterval(-60 * 90),
            cardID: MockCardIDs.acornstol
        ))
        
        // 일정/이벤트 알림
        notifications.append(AppNotification(
            type: .systemUpdate,
            message: "오늘 오후 3~5시 일정이 비어 있어요. 가까운 카페를 추천드려요!",
            timestamp: now.addingTimeInterval(-60 * 120),
            cardID: MockCardIDs.cafeEround
        ))
        
        return notifications
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onDelete: () -> Void
    
    @State private var showCardDetail = false
    @State private var relatedCard: Card?
    
    var body: some View {
        VStack(spacing: 0) {
            // 메인 알림 영역
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
                
                // X 버튼 (삭제)
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.caplogGrayMedium)
                        .frame(width: 24, height: 24)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            
            // 카드 미리보기 (별도 영역)
            if let card = relatedCard {
                Button(action: {
                    showCardDetail = true
                }) {
                    UnifiedCardView(
                        card: card,
                        style: .compact,
                        onTap: {
                            showCardDetail = true
                        }
                    )
                    .environment(\.notificationCardWidth, true)  // 알림용 넓은 폭
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
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
