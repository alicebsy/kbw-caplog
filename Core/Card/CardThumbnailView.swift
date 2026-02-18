//
//  CardThumbnailView.swift
//  Caplog
//
//  카드 썸네일: Asset 이미지 또는 스크린샷(로컬 저장) 표시
//

import SwiftUI

/// 카드에 맞는 썸네일 이미지 (Asset 또는 스크린샷)
struct CardThumbnailView: View {
    let thumbnailId: String
    var placeholder: String = "placeholder"
    
    @ViewBuilder
    var body: some View {
        if CardImageStore.isLocalScreenshot(id: thumbnailId),
           let uiImage = CardImageStore.load(id: thumbnailId) {
            Image(uiImage: uiImage)
                .resizable()
        } else if CardImageStore.isLocalScreenshot(id: thumbnailId) {
            Image(placeholder)
                .resizable()
        } else {
            Image(thumbnailId)
                .resizable()
        }
    }
}
