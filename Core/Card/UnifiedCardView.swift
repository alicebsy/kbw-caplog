import SwiftUI

/// 통합 카드 뷰 - 모든 탭에서 재사용 가능
/// 3가지 스타일 지원: row, horizontal, compact
struct UnifiedCardView: View {
    let card: Card
    let style: CardStyle
    
    var onTap: () -> Void = {}
    var onMore: () -> Void = {}
    var onTapImage: () -> Void = {}
    
    @State private var isShareSheetPresented = false
    @Environment(\.notificationCardWidth) private var isNotificationCard
    
    enum CardStyle {
        case row
        case horizontal
        case compact
        case coupon
        case chat
    }
    
    var body: some View {
        Group {
            switch style {
            case .row:
                rowStyle
            case .horizontal:
                horizontalStyle
            case .compact:
                compactStyle
            case .coupon:
                couponStyle
            case .chat:
                chatStyle
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheetView(
                target: card
            ) { friendIDs, threadIDs, msg in
                
                let vm = ShareViewModel.shared
                let cardToSend = self.card
                
                Task {
                    for threadId in threadIDs {
                        await vm.sendCard(to: threadId, card: cardToSend)
                        if !msg.isEmpty { await vm.send(to: threadId, text: msg) }
                    }
                    
                    for friendId in friendIDs {
                        guard let friend = vm.friends.first(where: { $0.id == friendId }) else { continue }
                        
                        var targetThreadId: String
                        if let existingThread = vm.threads.first(where: {
                            $0.participantIds.count == 2 && $0.participantIds.contains(friend.id)
                        }) {
                            targetThreadId = existingThread.id
                        } else {
                            let newThread = ChatThread(
                                id: "new_\(friend.id)_\(UUID().uuidString)",
                                title: friend.name,
                                participantIds: ["me", friend.id],
                                lastMessageText: nil,
                                lastMessageAt: Date(),
                                unreadCount: 0,
                                lastMessageCardTitle: nil
                            )
                            await vm.addNewThread(newThread)
                            targetThreadId = newThread.id
                        }
                        
                        await vm.sendCard(to: targetThreadId, card: cardToSend)
                        if !msg.isEmpty { await vm.send(to: targetThreadId, text: msg) }
                    }
                }
            }
            .presentationDetents([.height(420)])
        }
    }
    
    
    // MARK: - Row Style (Recommended / Recently)
    private var rowStyle: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // LEFT: 텍스트 (카드 상세 보기)
            VStack(alignment: .leading, spacing: 10) {
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.category.rawValue + " - " + card.subcategory)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(1)
                    
                    Text(card.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                if !card.summary.isEmpty {
                    Text(card.summary)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .overlay(
                                Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        
                        Text(card.subcategoryEmoji)
                            .font(.system(size: 14))
                    }
                    .frame(width: 28, height: 28)
                    
                    Text(card.contextualInfoText)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(1)
                }
                
                if !card.tagsString.isEmpty {
                    Text(card.tagsString)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle()) // 탭 영역 명확하게 지정
            .onTapGesture {
                print("🔵 UnifiedCardView rowStyle: 텍스트 영역 탭 -> onTap() 호출 (CardDetailView 열림)")
                onTap()
            }
            
            Spacer(minLength: 10)
            
            // RIGHT: 이미지 + 버튼
            VStack(spacing: 0) {
                Image(card.thumbnailName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 90)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("🟡 UnifiedCardView rowStyle: 이미지 탭 -> onTapImage() 호출 (전체화면)")
                        onTapImage()
                    }
                
                Spacer().frame(height: 12)
                
                HStack(spacing: 14) {
                    Button(action: {
                        print("🟢 UnifiedCardView rowStyle: 공유 버튼 탭")
                        isShareSheetPresented = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: {
                        print("🔴 UnifiedCardView rowStyle: ... 버튼 탭 -> onMore() 호출 (수정 시트)")
                        onMore()
                    }) {
                        Image(systemName: "ellipsis")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.brandTextSub)
                .frame(width: 80)
            }
        }
        .padding(16)
        .background(Color.brandCardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    
    // MARK: - Horizontal Style
    private var horizontalStyle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(card.thumbnailName)
                .resizable()
                .scaledToFill()
                .frame(height: 160)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onTapGesture { onTapImage() }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.category.rawValue + " - " + card.subcategory)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.brandTextSub)
                
                Text(card.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if !card.location.isEmpty {
                    Text(card.location)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(Color.brandCardBG)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
        .onTapGesture { onTap() }
    }
    
    
    // MARK: - Compact Style
    private var compactStyle: some View {
        HStack(alignment: .top, spacing: 12) {
            
            VStack(alignment: .leading, spacing: 8) {
                Text(card.category.rawValue + " - " + card.subcategory)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Text(card.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                if !card.summary.isEmpty {
                    Text(card.summary)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                if !card.location.isEmpty {
                    Text(card.location)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if !card.dateString.isEmpty {
                    Text(card.dateString)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 10)
            
            Image(card.thumbnailName)
                .resizable()
                .scaledToFill()
                .frame(width: isNotificationCard ? 80 : 64, height: isNotificationCard ? 80 : 64)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(isNotificationCard ? 14 : 16)
        .frame(maxWidth: isNotificationCard ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .onTapGesture { onTap() }
    }
    
    
    // MARK: - Chat Style
    private var chatStyle: some View {
        HStack(alignment: .top, spacing: 10) {
            
            VStack(alignment: .leading, spacing: 6) {
                Text(card.category.rawValue + " - " + card.subcategory)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Text(card.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !card.summary.isEmpty {
                    Text(card.summary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                if !card.location.isEmpty {
                    Text(card.location)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if !card.dateString.isEmpty {
                    Text(card.dateString)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 8)
            
            Image(card.thumbnailName)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .onTapGesture { onTap() }
        .frame(maxWidth: 200)
    }
    
    
    // MARK: - Coupon Style
    private var couponStyle: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // LEFT: 텍스트 (카드 상세 보기)
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.category.rawValue + " - " + card.subcategory)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(1)
                    
                    Text(card.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                if !card.summary.isEmpty {
                    Text(card.summary)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(2)
                }
                
                if let expireDate = card.fields["만료일"] {
                    Text(expireDate)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
            .contentShape(Rectangle()) // 탭 영역 명확하게 지정
            .onTapGesture {
                print("🔵 UnifiedCardView couponStyle: 텍스트 영역 탭 -> onTap() 호출 (CardDetailView 열림)")
                onTap()
            }
            
            Spacer(minLength: 10)
            
            // RIGHT: 이미지 + 버튼
            VStack(spacing: 8) {
                Image(card.thumbnailName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("🟡 UnifiedCardView couponStyle: 이미지 탭 -> onTapImage() 호출 (전체화면)")
                        onTapImage()
                    }
                
                HStack(spacing: 14) {
                    Button(action: {
                        print("🟢 UnifiedCardView couponStyle: 공유 버튼 탭")
                        isShareSheetPresented = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: {
                        print("🔴 UnifiedCardView couponStyle: ... 버튼 탭 -> onMore() 호출 (수정 시트)")
                        onMore()
                    }) {
                        Image(systemName: "ellipsis")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.brandTextSub)
                .frame(width: 80)
            }
        }
        .padding(16)
        .background(Color.homeGreenLight.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}



// MARK: - 알림용 환경 변수
private struct NotificationCardWidthKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var notificationCardWidth: Bool {
        get { self[NotificationCardWidthKey.self] }
        set { self[NotificationCardWidthKey.self] = newValue }
    }
}
