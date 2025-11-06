import SwiftUI

/// 통합 카드 뷰 - 모든 탭에서 재사용 가능
/// 3가지 스타일 지원: row, horizontal, compact
struct UnifiedCardView: View {
    let card: Card
    let style: CardStyle
    
    var onTap: () -> Void = {}
    var onShare: () -> Void = {}
    var onMore: () -> Void = {}
    var onTapImage: () -> Void = {}
    
    enum CardStyle {
        case row        // 좌측 정보 + 우측 썸네일 (HomeCardRow, RecentlyRow)
        case horizontal // 상단 썸네일 + 하단 정보 (HomeCardHorizontal)
        case compact    // 작은 카드 (검색 결과, 폴더 목록)
        case coupon     // 쿠폰 전용 (초록색 배경)
        case chat       // ✅ (추가) 채팅방 전용 (compact보다 폰트 작게)
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
            case .chat: // ✅ (추가)
                chatStyle
            }
        }
    }
    
    // MARK: - Row Style (좌측 정보 + 우측 썸네일)
    
    private var rowStyle: some View {
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
                
                if !card.location.isEmpty {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 28, height: 28)
                        Text(card.location)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.brandTextSub)
                            .lineLimit(1)
                    }
                }
                
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
                    Button(action: onShare) {
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
    
    // MARK: - ✅ (수정) Chat Style
    
    private var chatStyle: some View {
        HStack(alignment: .top, spacing: 10) { // spacing 12 -> 10
            VStack(alignment: .leading, spacing: 6) { // spacing 8 -> 6
                Text(card.category.rawValue + " - " + card.subcategory)
                    .font(.system(size: 11, weight: .semibold)) // 12pt -> 11pt
                    .foregroundStyle(.secondary)
                
                Text(card.title)
                    .font(.system(size: 16, weight: .bold)) // 18pt -> 16pt
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true) // ✅ 단어 잘림 방지

                if !card.summary.isEmpty {
                    Text(card.summary)
                        .font(.system(size: 13)) // 14pt -> 13pt
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true) // ✅ 단어 잘림 방지
                }
                
                if !card.location.isEmpty {
                    Text(card.location)
                        .font(.system(size: 12)) // 13pt -> 12pt
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if !card.dateString.isEmpty {
                    Text(card.dateString)
                        .font(.system(size: 11)) // 12pt -> 11pt
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 8) // minLength 10 -> 8
            
            Image(card.thumbnailName)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60) // 64x64 -> 60x60
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8)) // 10 -> 8
        }
        .padding(14) // padding 16 -> 14
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .onTapGesture { onTap() }
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
                
                // 만료일 표시
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
                    Button(action: onShare) {
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
            
            // ✅ (추가) Chat 스타일 프리뷰
            Text("Chat Style").font(.headline)
            UnifiedCardView(card: sampleCard, style: .chat)
                .frame(width: 200) // 채팅방에서 사용할 프레임
        }
        .padding()
    }
}
