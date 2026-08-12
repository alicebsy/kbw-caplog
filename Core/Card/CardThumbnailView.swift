//
//  CardThumbnailView.swift
//  Caplog
//
//  카드 썸네일: Asset 이미지 또는 스크린샷(로컬 저장) 표시
//

import SwiftUI

/// 카드에 맞는 썸네일 이미지 (Asset 또는 스크린샷)
///
/// 이미지가 없을 때 예전에는 `Image("placeholder")`를 그렸는데
/// 에셋 카탈로그에 `placeholder`가 없어서 투명한 빈 칸이 나왔습니다.
/// (서버에서 받은 카드는 이미지 경로를 안 주므로 대부분이 이 경우였습니다.)
/// 지금은 카테고리 색 틴트 + 하위분류 심볼로 채운 대체 썸네일을 그립니다.
struct CardThumbnailView: View {
    let thumbnailId: String
    /// 대체 썸네일의 색·심볼을 정할 때 씁니다. 없으면 중립 회색으로 그립니다.
    var card: Card? = nil
    /// 사진이 있을 때의 채우기 방식.
    ///
    /// 예전에는 호출부에서 `.scaledToFill()`을 붙였는데, 그러면 사진이 없어 대체 썸네일이
    /// 나올 때도 종횡비 보정이 걸립니다. 대체 썸네일은 고유 비율이 없어서 SwiftUI가 1:1로 보고
    /// 250×118 자리에 250×250을 그린 뒤 잘라내 버렸고, 채팅 말풍선에서 심볼이 두 배 넘게 커졌습니다.
    /// 그래서 채우기 방식을 뷰 안으로 들여와 **사진에만** 적용합니다.
    var contentMode: ContentMode = .fill

    @ViewBuilder
    var body: some View {
        if CardImageStore.isLocalScreenshot(id: thumbnailId),
           let uiImage = CardImageStore.load(id: thumbnailId) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else if let assetImage = UIImage(named: thumbnailId) {
            Image(uiImage: assetImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            // 대체 썸네일은 주어진 프레임을 그대로 채웁니다.
            CardThumbnailFallback(card: card)
        }
    }
}

/// 이미지가 없는 카드용 대체 썸네일.
/// 어떤 크기로 잘려도 자연스럽도록 심볼 크기를 컨테이너에 비례시킵니다.
///
/// 브랜드/장소 이름을 아는 카드(쿠폰·기프티콘·맛집 등)는 심볼 대신 **머리글자 타일**을
/// 그립니다. 티켓 심볼만 있는 자리는 "사진이 빠졌다"로 읽히는데, 브랜드 색 위에 머리글자를
/// 얹으면 사진이 없어도 의도된 모양이 됩니다. 실제 브랜드 로고는 상표라 쓰지 않습니다.
struct CardThumbnailFallback: View {
    var card: Card?

    /// 머리글자에 쓸 이름. 쿠폰은 브랜드, 그 외는 장소명을 봅니다.
    /// couponStyle이 "쿠폰" 알약 옆에 쓰는 키와 같은 순서입니다.
    private var brandName: String? {
        guard let fields = card?.fields else { return nil }
        let candidates = ["brand", "브랜드", "장소명", "place", "매장", "가맹점"]
        for key in candidates {
            if let value = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    /// 한글은 한 글자로 충분히 읽히고, 라틴 문자는 두 글자를 씁니다.
    private var monogram: String? {
        guard let name = brandName, let first = name.first else { return nil }
        let isHangulSyllable = first.unicodeScalars.contains { (0xAC00...0xD7A3).contains($0.value) }
        return isHangulSyllable ? String(first) : String(name.prefix(2)).uppercased()
    }

    private var tint: Color {
        // 아는 브랜드면 브랜드 색(쿠폰 카드가 쓰는 것과 같은 색), 모르면 카테고리 색입니다.
        // 모르는 이름까지 브랜드 기본색으로 칠하면 맛집·여행 카드가 전부 같은 초록이 됩니다.
        if let brandColor = Color.knownBrandColor(brandName: brandName) {
            return brandColor
        }
        return card?.category.color ?? Color.brandTextSub
    }

    private var symbolName: String {
        card?.subcategorySymbolName ?? "photo"
    }

    /// 틴트를 얹은 실제 면. 글자·심볼 색을 여기 기준으로 보정합니다.
    private var surface: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
            .composited(with: tint, fraction: 0.20)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                LinearGradient(
                    colors: [tint.opacity(0.20), tint.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let monogram {
                    VStack(spacing: 3) {
                        Text(monogram)
                            .font(.system(size: max(18, side * 0.42), weight: .bold, design: .rounded))
                            .foregroundStyle(tint.contrasting(on: surface))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        // 타일이 좁으면 이름까지 넣으면 둘 다 안 읽힙니다.
                        if side >= 80, let brandName {
                            Text(brandName)
                                .font(.system(size: max(9, side * 0.10), weight: .semibold))
                                .foregroundStyle(tint.contrasting(on: surface))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 6)
                        }
                    }
                } else {
                    Image(systemName: symbolName)
                        .font(.system(size: max(14, side * 0.34), weight: .semibold))
                        // 옅은 틴트 면 위에서 3:1을 넘기도록 밝기만 보정합니다.
                        .foregroundStyle(tint.contrasting(on: surface, minimumRatio: 3))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
