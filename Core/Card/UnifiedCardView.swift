import SwiftUI

/// 통합 카드 뷰 - 모든 탭에서 재사용 가능
/// 3가지 스타일 지원: row, horizontal, compact
struct UnifiedCardView: View {
    let card: Card
    let style: CardStyle
    
    var onTap: () -> Void = {}
    // ❌ onShare 콜백 제거
    var onMore: () -> Void = {}
    var onTapImage: () -> Void = {}
    
    // ✅ (추가) 공유 시트를 띄우기 위한 내부 상태
    @State private var isShareSheetPresented = false
    
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
        // ✅ (수정) .sheet 수정자에 실제 전송 로직 추가
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheetView(
                target: card
            ) { friendIDs, threadIDs, msg in
                
                // ✅ (추가) 싱글톤 VM을 가져와서 전송 로직 실행
                let vm = ShareViewModel.shared
                let cardToSend = self.card
                
                Task {
                    // 1. 선택된 기존 채팅방에 전송
                    for threadId in threadIDs {
                        await vm.sendCard(to: threadId, card: cardToSend)
                        if !msg.isEmpty {
                            await vm.send(to: threadId, text: msg)
                        }
                    }
                    
                    // 2. 선택된 친구와 1:1 채팅방을 찾아 전송
                    for friendId in friendIDs {
                        // 친구 객체 찾기
                        guard let friend = vm.friends.first(where: { $0.id == friendId }) else { continue }
                        
                        // 기존 1:1 채팅방 찾기
                        var targetThreadId: String
                        if let existingThread = vm.threads.first(where: {
                            $0.participantIds.count == 2 && $0.participantIds.contains(friend.id)
                        }) {
                            targetThreadId = existingThread.id
                        } else {
                            // 새 1:1 채팅방 생성
                            let newThread = ChatThread(
                                id: "new_\(friend.id)_\(UUID().uuidString)",
                                title: friend.name, // (loadAll에서 어차피 다시 계산됨)
                                participantIds: ["me", friend.id],
                                lastMessageText: nil,
                                lastMessageAt: Date(),
                                unreadCount: 0,
                                lastMessageCardTitle: nil
                            )
                            await vm.addNewThread(newThread)
                            targetThreadId = newThread.id
                        }
                        
                        // 카드 및 메시지 전송
                        await vm.sendCard(to: targetThreadId, card: cardToSend)
                        if !msg.isEmpty {
                            await vm.send(to: targetThreadId, text: msg)
                        }
                    }
                }
            }
            .presentationDetents([.height(420)])
        }
    }
    
    // MARK: - Row Style (좌측 정보 + 우측 썸네일)
    
    private var rowStyle: some View {
        HStack(alignment: .top, spacing: 12) {
            // ... (VStack: 텍스트 블록) ...
            VStack(alignment: .leading, spacing: 10) {
                // --- 제목/카테고리 ---
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
                
                // ✅ (삭제) 이모지 블록이 여기서 삭제됨
                
                // --- 요약 ---
                if !card.summary.isEmpty {
                    Text(card.summary)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(2)
                }
                
                // ✅ (수정) 이모지+텍스트 블록을 여기(summary 아래)로 이동
                //    (이모지는 항상 표시하고, 텍스트만 비어있게 됨)
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.white) // 흰색 원
                            .overlay(
                                Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        
                        Text(card.subcategoryEmoji) // 이모지
                            .font(.system(size: 14))
                    }
                    .frame(width: 28, height: 28)
                    
                    // ✅ (수정) 새 변수명 사용
                    Text(card.contextualInfoText) // 유효기간 또는 위치
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(1)
                }
                
                // --- 태그 ---
                if !card.tagsString.isEmpty {
                    Text(card.tagsString)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            
            Spacer(minLength: 10)
            
            // RIGHT: 썸네일 + 버튼
            VStack(spacing: 0) {
                Image(card.thumbnailName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture { onTapImage() }
                
                Spacer().frame(height: 12)
                
                HStack(spacing: 14) {
                    Button(action: { isShareSheetPresented = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: onMore) {
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
    
    // MARK: - Horizontal Style (상단 썸네일 + 하단 정보)
    
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
    
    // MARK: - Compact Style (검색 결과, 폴더 목록)
    
    private var compactStyle: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(card.category.rawValue + " - " + card.subcategory)
                    .font(.system(size: 12, weight: .semibold)) // 12pt
                    .foregroundStyle(.secondary)
                
                Text(card.title)
                    .font(.system(size: 18, weight: .bold)) // 18pt
                    .foregroundStyle(.primary)
                
                if !card.summary.isEmpty {
                    Text(card.summary)
                        .font(.system(size: 14)) // 14pt
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                if !card.location.isEmpty {
                    Text(card.location)
                        .font(.system(size: 13)) // 13pt
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if !card.dateString.isEmpty {
                    Text(card.dateString)
                        .font(.system(size: 12)) // 12pt
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 10)
            
            Image(card.thumbnailName)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
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
                        .fixedSize(horizontal: false, vertical: true)
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
    
    // MARK: - Coupon Style (연한 파란색 배경)
    
    private var couponStyle: some View {
        HStack(alignment: .top, spacing: 12) {
            // LEFT: 텍스트 블록
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
            
            Spacer(minLength: 10)
            
            // RIGHT: 썸네일 + 버튼
            VStack(spacing: 8) {
                Image(card.thumbnailName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture { onTapImage() }
                
                HStack(spacing: 14) {
                    // ✅ (수정) onShare -> isShareSheetPresented = true
                    Button(action: { isShareSheetPresented = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: onMore) {
                        Image(systemName: "ellipsis")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.brandTextSub)
                .frame(width: 80)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .background(Color.homeGreenLight.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview("Card Styles") {
    let sampleCard = Card.sampleCards[0]
    
    return ScrollView {
        VStack(spacing: 20) {
            Text("Row Style").font(.headline)
            UnifiedCardView(card: sampleCard, style: .row)
            
            Text("Horizontal Style").font(.headline)
            UnifiedCardView(card: sampleCard, style: .horizontal)
            
            Text("Compact Style").font(.headline)
            UnifiedCardView(card: sampleCard, style: .compact)
            
            Text("Chat Style").font(.headline)
            UnifiedCardView(card: sampleCard, style: .chat)
                .frame(maxWidth: 200)
        }
        .padding()
    }
}
