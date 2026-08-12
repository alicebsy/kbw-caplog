import SwiftUI

/// 인증 화면(랜딩·회원가입·로그인) 공통 스타일.
///
/// 세 화면이 각자 다른 배경·버튼 색을 쓰고 있어서 같은 동작인데 화면마다
/// 모양이 달랐습니다. 여기 한 곳에 모아두고 세 화면이 그대로 가져다 씁니다.

/// 브랜드 그라데이션 배경 (틸 → 크림)
struct AuthBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.brandGradientTop, Color.brandGradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// 로고 + 화면 이름 헤더
struct AuthHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: 12) {
            Image("caplog_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.brandTextMain)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    // 그라데이션 위쪽(#87ABA4)에서는 보조 회색(#6B6B6B)이
                    // 2.13:1까지 떨어져서, 어디에 놓여도 견디는 본문색을 씁니다.
                    .foregroundColor(Color.brandTextMain)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

/// 입력 요소를 감싸는 묶음.
///
/// 처음엔 흰 카드를 얹었는데 그라데이션 위에 판때기 하나가 떠 있는 꼴이라
/// 배경과 따로 놀았습니다. 면을 없애고 여백만 주어 배경 위에 그대로 올립니다.
/// 대신 글자·밑줄 색을 그라데이션 위쪽(#87ABA4) 기준으로 잡아
/// 흰 면 없이도 대비를 확보합니다.
struct AuthFieldGroup<Content: View>: View {
    var spacing: CGFloat = 22
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(.horizontal, 16)
    }
}

extension View {
    /// 주 동작 버튼 (회원가입 / 가입하기 / 로그인)
    ///
    /// 입력이 덜 찼다고 버튼을 회색으로 죽이면 그라데이션 위에서 회색 덩어리가
    /// 화면을 잡아먹고, 라벨 대비도 2.25:1까지 떨어졌습니다. 버튼은 항상 살려두고
    /// 빠진 항목은 눌렀을 때 알려줍니다(가드는 이미 있습니다).
    func authPrimaryButton() -> some View {
        self
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.homeGreenDark)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// 보조 동작 버튼 (테두리형)
    ///
    /// 흰 면을 깔면 그라데이션 위에 판때기가 얹힌 것처럼 보여서 면은 비우고
    /// 테두리와 글자만 브랜드 딥그린으로 둡니다.
    /// 채움 버튼(위)과 달리 색이 **글자로** 쓰이므로, 그라데이션 위에서도 4.80:1을
    /// 유지하는 authOnGradient를 씁니다. homeGreenDark는 밝아서 여기선 2.14:1입니다.
    func authSecondaryButton() -> some View {
        self
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Color.authOnGradient)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.authOnGradient, lineWidth: 1.5)
            )
    }
}

/// "계정이 없으신가요? 회원가입" 같은 화면 전환 안내
struct AuthSwitchPrompt<Destination: View>: View {
    var question: String
    var actionTitle: String
    @ViewBuilder var destination: Destination

    var body: some View {
        HStack(spacing: 6) {
            Text(question)
                .font(.system(size: 14))
                .foregroundColor(Color.brandTextMain)

            NavigationLink(destination: destination) {
                Text(actionTitle)
                    .font(.system(size: 14, weight: .bold))
                    .underline()
                    // 그라데이션 위 글자라서 authOnGradient(4.80:1)를 씁니다.
                    .foregroundColor(Color.authOnGradient)
            }
        }
    }
}
