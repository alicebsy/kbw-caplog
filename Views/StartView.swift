// Views/StartView.swift
import SwiftUI

struct StartView: View {
    @State private var go = false

    var body: some View {
        NavigationStack {
            // 완전 흰 배경만 표시 (스플래시처럼)
            Color.white
                .ignoresSafeArea()
                // Register1View로 즉시 이동
                .navigationDestination(isPresented: $go) {
                    Register1View()
                        .navigationBarBackButtonHidden(true)
                }
                .task {
                    // 다음 런루프에서 트리거 → 사용자에게는 즉시 전환처럼 보임
                    go = true
                }
        }
    }
}
