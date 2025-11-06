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
                
                if !card.tags.isEmpty {
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
            // ❌ 수정: .contentShape와 .onTapGesture를 이곳에서 제거
            
            Spacer(minLength: 10)
            
            // RIGHT: 썸네일 + 버튼
            VStack(spacing: 8) {
                Image(card.thumbnailName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture { onTapImage() } // (이미지 탭은 유지)
                
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
        // ✅ 수정: .contentShape와 .onTapGesture를 HStack 전체에 적용
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
        }
        .padding()
    }
}
