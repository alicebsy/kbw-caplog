import SwiftUI

struct StartView: View {
    @State private var go = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.gradientTop, .gradientBottom]),
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    Image("caplog_logo").resizable().scaledToFit().frame(width: 120, height: 120)
                    Text("Caplog").font(.system(size: 28, weight: .bold)).foregroundColor(.black)
                    Spacer()
                }
            }
            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { go = true } }
            .navigationDestination(isPresented: $go) { Register1View() }
        }
    }
}
