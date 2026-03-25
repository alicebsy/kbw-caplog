import SwiftUI
import UIKit

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
        HStack(alignment: .top, spacing: 10) {
            
            // LEFT: 텍스트 (카드 상세 보기)
            VStack(alignment: .leading, spacing: 8) {
                
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
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    
    // MARK: - Horizontal Style
    private var horizontalStyle: some View {
        VStack(alignment: .leading, spacing: 6) {
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
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.white)
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
        .onTapGesture { onTap() }
        .frame(maxWidth: 200)
    }
    /// 스크린샷/에셋 평균색을 쿠폰 액센트로 사용 (너무 밝·어두우면 브랜드 색 폴백)
    private static func couponAccentColor(thumbnailId: String, fallback: Color) -> Color {
        let ui: UIImage?
        if CardImageStore.isLocalScreenshot(id: thumbnailId) {
            ui = CardImageStore.load(id: thumbnailId)
        } else {
            ui = UIImage(named: thumbnailId)
        }
        guard let img = ui, let uic = img.caplogAverageColor() else { return fallback }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if !uic.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return fallback
        }
        let brightness = (r + g + b) / 3
        if brightness < 0.15 || brightness > 0.97 {
            return fallback
        }
        return Color(uic)
    }

    // MARK: - Coupon Style (이미지 카드 전용)
    /// 홈 "마감 임박": 스크린샷 톤 + 지갑형 카드 (밝은 면 + 썸네일 + 액센트 스트립)
    private var couponStyle: some View {
        let imageName = isHomeScreen ? card.homeThumbnailName : card.thumbnailName
        let brandName = card.fields["brand"] ?? card.fields["브랜드"] ?? ""
        let expiryText = card.fields["만료일"] ?? card.fields["valid_until"] ?? card.fields["deadline"] ?? card.contextualInfoText
        let benefitText = card.fields["benefit"] ?? card.fields["혜택 요약"] ?? card.title
        let extraLine = card.fields["conditions"] ?? card.fields["조건/제한"] ?? card.fields["상품"] ?? card.summary
        let fallbackBrand = Color.expiringCardBrandColor(brandName: brandName.isEmpty ? nil : brandName)
        let accent = Self.couponAccentColor(thumbnailId: imageName, fallback: fallbackBrand)
        let hasExpiry = expiryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let brandIconName = Color.expiringCardBrandIconName(brandName: brandName.isEmpty ? nil : brandName)

        return Group {
            if isHomeScreen {
                let cardCorner: CGFloat = 20
                ZStack(alignment: .leading) {
                    // 베이스: 밝은 카드 + 스크린샷 톤의 아주 옅은 틴트
                    RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(uiColor: .secondarySystemGroupedBackground),
                                    Color(uiColor: .systemBackground)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                                .fill(accent.opacity(0.07))
                        )
                        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)

                    // 왼쪽 액센트 스트립 (카드 모서리는 바깥 clipShape가 맞춤)
                    HStack(spacing: 0) {
                        LinearGradient(
                            colors: [accent, accent.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: 5)
                        Spacer(minLength: 0)
                    }

                    HStack(alignment: .center, spacing: 14) {
                        // 스크린샷 미리보기 (실제 앱처럼 왼쪽 비주얼)
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                            CardThumbnailView(thumbnailId: imageName)
                                .scaledToFill()
                                .frame(width: 92, height: 112)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .frame(width: 96, height: 116)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text("쿠폰")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(accent.opacity(0.12))
                                    )
                                if !brandName.isEmpty {
                                    Text(brandName)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Text(benefitText)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            if hasExpiry {
                                Text(expiryText)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(accent.opacity(0.95))
                                    .lineLimit(1)
                            }

                            if !extraLine.isEmpty && extraLine != benefitText {
                                Text(extraLine)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)

                            HStack {
                                if let iconName = brandIconName {
                                    Image(iconName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                        .opacity(0.9)
                                } else if !brandName.isEmpty && (brandName.lowercased().contains("배스킨") || brandName.lowercased().contains("baskin") || brandName.lowercased().contains("베라")) {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(accent.opacity(0.85))
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Button(action: { isShareSheetPresented = true }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    Button(action: { onMore() }) {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    Button(action: { onTap() }) {
                                        Image(systemName: "chevron.right.circle.fill")
                                            .font(.system(size: 26))
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(accent, Color(uiColor: .secondarySystemGroupedBackground))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading, 14)
                    .padding(.trailing, 16)
                    .padding(.vertical, 14)
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
