import SwiftUI

/// 통합 카드 뷰 - 모든 탭에서 재사용 가능
/// 3가지 스타일 지원: row, horizontal, compact
struct UnifiedCardView: View {
    let card: Card
    let style: CardStyle
    
    var onTap: () -> Void = {}
    var onMore: () -> Void = {}
    var onTapImage: () -> Void = {}
    var isHomeScreen: Bool = false // ✅ 홈 화면 여부
    
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
                CardThumbnailView(thumbnailId: card.thumbnailName)
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
            CardThumbnailView(thumbnailId: card.thumbnailName)
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
            
            CardThumbnailView(thumbnailId: card.thumbnailName)
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
            
            CardThumbnailView(thumbnailId: card.thumbnailName)
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
    
    
    // MARK: - Coupon Style (이미지 카드 전용)
    /// 홈 "마감 임박": 브랜드색만 배경, 브랜드 아이콘, 화살표 눌러야만 상세로 이동
    private var couponStyle: some View {
        let imageName = isHomeScreen ? card.homeThumbnailName : card.thumbnailName
        let brandName = card.fields["brand"] ?? card.fields["브랜드"] ?? ""
        let expiryText = card.fields["만료일"] ?? card.fields["valid_until"] ?? card.fields["deadline"] ?? card.contextualInfoText
        let benefitText = card.fields["benefit"] ?? card.fields["혜택 요약"] ?? card.title
        let extraLine = card.fields["conditions"] ?? card.fields["조건/제한"] ?? card.fields["상품"] ?? card.summary
        let brandColor = Color.expiringCardBrandColor(brandName: brandName.isEmpty ? nil : brandName)
        let textColor = Color.expiringCardTextColor(brandName: brandName.isEmpty ? nil : brandName)
        let hasExpiry = expiryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let brandIconName = Color.expiringCardBrandIconName(brandName: brandName.isEmpty ? nil : brandName)

        return Group {
            if isHomeScreen {
                let cardCorner: CGFloat = 28
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                        .fill(brandColor)
                        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)

                    // 왼쪽: 제목·마감일
                    VStack(alignment: .leading, spacing: 8) {
                        Text(benefitText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textColor)
                            .lineLimit(2)
                        if hasExpiry {
                            Text(expiryText)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(textColor)
                                .lineLimit(1)
                        }
                        if !extraLine.isEmpty && (hasExpiry || benefitText != extraLine) {
                            Text(extraLine)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(textColor.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.top, 20)

                    // 오른쪽 상단: 브랜드 아이콘 (스타벅스/이마트/배스킨 등) + 브랜드명
                    VStack(alignment: .trailing, spacing: 6) {
                        if let iconName = brandIconName {
                            Image(iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                        } else if !brandName.isEmpty && (brandName.lowercased().contains("배스킨") || brandName.lowercased().contains("baskin") || brandName.lowercased().contains("베라")) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 28))
                                .foregroundColor(textColor.opacity(0.9))
                        }
                        if !brandName.isEmpty {
                            Text(brandName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textColor.opacity(0.95))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 20)
                    .padding(.top, 20)

                    // 우하단: 화살표만 누르면 상세로 (카드 영역 탭은 이동 안 함)
                    HStack(spacing: 10) {
                        Button(action: { isShareSheetPresented = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                                .foregroundColor(textColor.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                        Button(action: { onMore() }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundColor(textColor.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                        Button(action: { onTap() }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(textColor)
                                .frame(width: 48, height: 48)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
                .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
            } else {
                // 홈이 아닐 때: 기존 쿠폰 이미지 카드 (카드 탭 시 상세)
                ZStack(alignment: .bottomTrailing) {
                    CardThumbnailView(thumbnailId: imageName)
                        .scaledToFit()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    HStack(spacing: 12) {
                        Button(action: { isShareSheetPresented = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        Button(action: { onMore() }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                }
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
            }
        }
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
