import SwiftUI

struct HomeImagePopupView: View, Identifiable {
    let id = UUID()
    let imageName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            imageView
        }
        .onTapGesture { dismiss() }
    }
    
    private var imageView: some View {
        Group {
            if CardImageStore.isLocalScreenshot(id: imageName),
               let uiImage = CardImageStore.load(id: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            }
        }
        .padding()
    }
}
