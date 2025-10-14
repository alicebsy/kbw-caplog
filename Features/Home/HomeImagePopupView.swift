import SwiftUI

struct HomeImagePopupView: View, Identifiable {
    let id = UUID()
    let imageName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            Image(imageName).resizable().scaledToFit().padding()
        }
        .onTapGesture { dismiss() }
    }
}
