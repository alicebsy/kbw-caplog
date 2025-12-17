import SwiftUI

struct StartView: View {
    // 1. 로그인 상태를 저장할 변수 추가
    @State private var isLoggedIn = false

    var body: some View {
        // 2. 앱 전체를 관리할 단 하나의 NavigationStack
        NavigationStack {
            // 3. 로그인 상태에 따라 다른 뷰를 보여주는 로직
            if isLoggedIn {
                // 로그인이 성공하면 TabView가 있는 메인 화면으로 전환
                AppNavigation()
            } else {
                // 로그인 전에는 가입/로그인 화면을 보여줌
                Register1View(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
