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
struct CardThumbnailFallback: View {
    var card: Card?

    private var tint: Color {
        card?.category.color ?? Color.brandTextSub
    }

    private var symbolName: String {
        card?.subcategorySymbolName ?? "photo"
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
                Image(systemName: symbolName)
                    .font(.system(size: max(14, side * 0.34), weight: .semibold))
                    // 옅은 틴트 면 위에서 3:1을 넘기도록 밝기만 보정합니다.
                    .foregroundStyle(
                        tint.contrasting(
                            on: Color(uiColor: .secondarySystemGroupedBackground)
                                .composited(with: tint, fraction: 0.20),
                            minimumRatio: 3
                        )
                    )
            }
        }
        .accessibilityHidden(true)
    }
}
