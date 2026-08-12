import SwiftUI
import UIKit

extension Color {
    // Brand (기존 팔레트 유지)
    static let brandGradientTop    = Color(hex: "#87ABA4")
    static let brandGradientBottom = Color(hex: "#FFFCF1")
    // joinButton(#AABBBE) / loginButton(#5E5858)은 제거했습니다.
    // 랜딩의 가입 버튼은 흰 글자 대비 1.99:1로 거의 읽을 수 없었고, 같은 동작인
    // 가입 폼 버튼(#34A853, 3.06:1)과도 색이 달랐습니다. 인증 화면은 이제
    // 앱 본체와 같은 homeGreenDark / homeGreenTint를 씁니다.
    static let brandBgTop      = Color(hex: "#FFFCC1")
    static let brandBgBottom   = Color(hex: "#87ABA4")
    static let brandHeader     = Color(hex: "#CFE8E0")
    static let brandCardBG     = Color.adaptive(light: "#F5F5F5", dark: "#1C1C1E")
    static let brandLine       = Color.adaptive(light: "#EDEDED", dark: "#38383A")
    static let brandAccent     = Color(hex: "#96BAC1")
    static let brandGreenCard  = Color(hex: "#4AA465")
    // 고정 검정이면 다크모드에서 배경에 묻힙니다.
    static let brandTextMain   = Color.adaptive(light: "#262626", dark: "#F2F2F2")
    // 기존 black 0.4(≈#999999)는 라이트모드에서도 2.85:1로 AA 미달이라 함께 조정했습니다.
    static let brandTextSub    = Color.adaptive(light: "#6B6B6B", dark: "#9E9E9E")

    // Global
    static let caplogBlack       = Color(hex: "#000000")
    static let caplogWhite       = Color(hex: "#FFFFFF")
    static let caplogGrayLight   = Color(hex: "#EEEEEE")
    static let caplogGrayMedium  = Color(hex: "#C4C4C4")
    static let caplogGrayDark    = Color.adaptive(light: "#5D5858", dark: "#A8A2A2")

    // 기존 사용 중
    static let accentGreen       = Color(red: 0.06, green: 0.36, blue: 0)

    // Register 등
    static let registerGreen         = Color(hex: "#34A853")
    static let registerGoogleBlue    = Color(hex: "#4285F4")
    static let registerKakaoYellow   = Color(hex: "#FBBC05")
    static let registerRed           = Color(hex: "#EA4335")
    /// 안 읽음 배지. 흰 숫자를 얹는 자리라 배경색 자체가 대비를 결정합니다.
    /// 예전 #F4525F는 흰 글씨 기준 3.38:1이라 12pt 숫자가 AA(4.5:1)에 못 미쳤습니다.
    /// #D32F2F는 4.98:1로 통과하면서 알림 빨강의 인상은 유지합니다.
    static let unreadBadgeRed        = Color(hex: "#D32F2F")
    static let registerGray          = Color(hex: "#AABABE")
    static let registerGrayLight     = Color(hex: "#F1F1F1")
    static let registerGrayMid       = Color(hex: "#BEC1C2")
    static let registerLineGray      = Color(hex: "#E4E8E9")
    static let registerBackground    = Color(hex: "#F5F8F6")
    static let registerTextGray      = Color(hex: "#8D8D8D")
    // 플레이스홀더는 입력 항목이 무엇인지 알려주는 유일한 라벨이라 본문 기준(4.5:1)을 적용합니다.
    // 인증 화면 그라데이션 위쪽(#87ABA4)에서 #8E8E93은 2.4:1, #6B6B6B도 2.13:1로 미달이라
    // 그라데이션 어디에 놓여도 4.34:1 이상 나오는 값으로 잡았습니다.
    static let registerPlaceholder   = Color.adaptive(light: "#3D3D3D", dark: "#B0B0B0")
    static let registerToJoin        = Color(hex: "#BFC2C3")
    static let registerButtonGray    = Color(hex: "#74727F")
    static let registerInactive      = Color(hex: "#FDFDFD")

    // 딥그린 계열은 역할에 따라 두 토큰으로 나눕니다.
    // - 채우기(Fill): 위에 흰 글자가 올라가므로 다크모드에서도 어두워야 합니다. → 고정값 유지
    // - 전경(Tint): 표면 위 아이콘·글자·테두리로 쓰이므로 다크모드에서 밝아져야 합니다.
    // 하나의 색으로 두 역할을 동시에 만족시키는 건 불가능합니다
    // (흰 글자용 상한 휘도 < 다크 표면용 하한 휘도).
    //
    // 예전 값 #144749는 흰 글자 대비 10.3:1로 기준(4.5:1)을 두 배 넘게 넘겼는데,
    // 그만큼 어둡고 채도가 낮아서(청록-회색) 앱 전체가 가라앉아 보였습니다.
    // 남는 대비 여유를 채도와 밝기로 돌려 브랜드의 밝은 딥그린을 되찾습니다.
    // #0E7A50은 흰 글자 5.36:1, 흰 배경 위 전경으로도 5.36:1로 AA를 통과합니다.
    static let homeGreenDark       = Color(hex: "#0E7A50")
    /// 표면 위 전경용 딥그린. 다크모드에서 밝은 그린으로 전환됩니다.
    static let homeGreenTint       = Color.adaptive(light: "#0E7A50", dark: "#4FD3A2")
    /// 인증 화면 그라데이션(#87ABA4~#FFFCF1) **위에 얹는 글자·테두리** 전용 딥그린.
    ///
    /// 밝아진 homeGreenDark(#0E7A50)는 흰 면에서는 5.36:1이지만 그라데이션 위쪽에서는
    /// 2.14:1까지 떨어져서, 로그인 버튼 글자와 화면 전환 링크에 쓸 수 없습니다.
    /// 이 값은 그라데이션 어디에 놓여도 최소 4.80:1을 확보합니다.
    /// 채우기(흰 글자를 올리는 버튼)에는 homeGreenDark를 그대로 씁니다.
    static let authOnGradient      = Color(hex: "#073F26")
    static let homeGreen           = Color(hex: "#A4CFCA")
    static let homeGreenLight      = Color(hex: "#C1E4E0")
    static let homeGrayDeep        = Color(hex: "#2B2B2B")
    static let homeGrayText        = Color(hex: "#444444")
    static let homeGraySub         = Color.adaptive(light: "#666666", dark: "#A0A0A0")
    static let homeBackgroundLight = Color.adaptive(light: "#F9FAFB", dark: "#000000")
    static let homeBackgroundMid   = Color(hex: "#DFD9D9")
    static let homeCardShadow      = Color(hex: "#DEDEDE")
    static let homeBorder          = Color(hex: "#C4C4C4")
    static let homeWhiteOpacity    = Color.white.opacity(0.9)
    static let homeBlackOpacity60  = Color.black.opacity(0.6)
    static let homeBlackOpacity30  = Color.black.opacity(0.3)

    // Common aliases
    static let checkMint   = Color(hex: "#8FD694")
    // 입력 필드의 밑줄은 필드 경계를 알려주는 유일한 표시라 3:1이 필요합니다.
    // 인증 화면 그라데이션 위에서는 회색 계열이 1.5~2.2:1까지 떨어져서
    // 딥그린을 씁니다(authOnGradient와 같은 값, 그라데이션 위 최소 4.80:1).
    static let divider     = Color.adaptive(light: "#073F26", dark: "#6FC4A3")
    // 입력 오류 안내. registerRed(#EA4335)는 흰 면에서도 3.92:1로 AA 미달이고,
    // 인증 화면 그라데이션 위에서는 더 떨어집니다.
    static let errorRed    = Color.adaptive(light: "#8C1D18", dark: "#FF8A80")
    static let placeholder = Color(.placeholderText)

    // === MyPage 전용 토큰 ===
    static let myPageActionBlue   = Color(hex: "#2A6BA0")
    static let myPageActionBlueBg = Color(hex: "#2A6BA0").opacity(0.12)
    static let myPageSectionGreen = Color.accentGreen
    /// 표면 위 전경용 브랜드 그린. 다크모드에서 밝은 그린으로 전환됩니다.
    /// `myPageSectionGreen`은 흰 글자를 올리는 버튼 채우기 전용으로 남겨둡니다.
    static let accentGreenTint    = Color.adaptive(light: "#0E7A50", dark: "#4FD3A2")

    // === 포인트 팔레트 ===
    // 카드 대분류를 구분하는 색입니다. 예전 값은 회색을 많이 섞어 톤을 낮춘 탓에
    // 카드가 늘어선 화면 전체가 흐릿하고 처져 보였습니다(회색끼).
    // 색조는 그대로 두고 채도만 올렸고, 모든 값이 흰 면에서 5:1 이상을 유지합니다.
    static let pointBlue   = Color(hex: "#2A6BA0")  // 5.66:1
    static let pointAmber  = Color(hex: "#A05A00")  // 5.31:1
    static let pointCoral  = Color(hex: "#B03A30")  // 6.01:1
    static let pointTeal   = Color(hex: "#0F7A73")  // 5.19:1
    static let pointViolet = Color(hex: "#6A3FA0")  // 7.41:1
    static let pointSlate  = Color(hex: "#4A5A6E")  // 7.06:1 (기타: 유일하게 중립 유지)


    // === 마감 임박 카드: 브랜드별 색상 (원래 톤) ===
    /// 아는 브랜드일 때만 hex를 돌려줍니다(모르면 nil).
    ///
    /// 대체 썸네일은 "아는 브랜드인지"를 구분해야 합니다. 모르는 이름까지 기본 민트로
    /// 칠하면 맛집·여행 카드가 전부 같은 초록 타일이 되어 카테고리 색 구분이 사라집니다.
    private static func expiringCardBrandHexIfKnown(brandName: String?) -> String? {
        guard let name = brandName?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return nil
        }
        if name.contains("스타벅스") || name.contains("starbucks") { return "#46A68E" }      // 기존 초록을 조금 밝게
        if name.contains("이마트") || name.contains("emart")       { return "#F7BF5B" }      // 부드러운 머스터드
        if name.contains("메가") || name.contains("megacoffee") ||
           name.contains("mgc")                                     { return "#A8744F" }      // 연한 브라운
        if name.contains("카카오") || name.contains("kakao")       { return "#FFEFA3" }      // 연한 옐로우
        if name.contains("gs25") || name.contains("gs 25")         { return "#9CD279" }      // 연한 그린
        if name.contains("cu") || name.contains("씨유")            { return "#C86B7B" }      // 약간 톤 다운된 레드/와인
        if name.contains("투썸") || name.contains("twosome")       { return "#D46C71" }      // 소프트 레드
        if name.contains("빽다방") || name.contains("baek")        { return "#4A4A4A" }      // 진한 그레이
        if name.contains("할리스") || name.contains("hollys")      { return "#7A567F" }      // 톤 다운 퍼플
        if name.contains("던킨") || name.contains("dunkin")        { return "#F48A7D" }      // 코랄 계열
        if name.contains("배스킨") || name.contains("baskin")      { return "#E97CA3" }      // 부드러운 핑크
        return nil
    }

    /// 브랜드 배경색의 hex. 글자색을 휘도에서 계산하기 위해 hex를 단일 출처로 둡니다.
    private static func expiringCardBrandHex(brandName: String?) -> String {
        expiringCardBrandHexIfKnown(brandName: brandName) ?? "#46A68E" // 기본 민트그린
    }

    /// 아는 브랜드의 색(모르면 nil). 대체 썸네일이 카테고리 색으로 넘어갈지 판단할 때 씁니다.
    static func knownBrandColor(brandName: String?) -> Color? {
        expiringCardBrandHexIfKnown(brandName: brandName).map { Color(hex: $0) }
    }

    static func expiringCardBrandColor(brandName: String?) -> Color {
        Color(hex: expiringCardBrandHex(brandName: brandName))
    }

    /// 마감 임박 카드에서 브랜드 배경에 맞는 글자색.
    ///
    /// 브랜드를 하나하나 나열하는 대신 배경의 상대 휘도(WCAG 2.1)를 계산해
    /// 대비가 더 큰 쪽을 고릅니다. 예전 구현은 밝은 배경 7종(#9CD279는 1.76:1)에
    /// 흰 글자를 올려 WCAG AA(4.5:1)에 크게 못 미쳤습니다.
    /// 현재 팔레트에서는 이 방식으로 모든 브랜드가 최소 5.2:1을 확보합니다.
    static func expiringCardTextColor(brandName: String?) -> Color {
        readableForeground(onHex: expiringCardBrandHex(brandName: brandName))
    }

    /// 마감 임박 카드용 브랜드 아이콘 에셋 이름 (있으면 표시, 없으면 nil)
    static func expiringCardBrandIconName(brandName: String?) -> String? {
        guard let name = brandName?.lowercased(), !name.isEmpty else { return nil }
        if name.contains("스타벅스") || name.contains("starbucks") { return "스타벅스" }
        if name.contains("이마트") || name.contains("emart") { return "이마트24" }
        if name.contains("메가") || name.contains("megacoffee") || name.contains("mgc") { return "메가커피" }
        if name.contains("카카오") || name.contains("kakao") { return "카카오페이" }
        return nil
    }
}

// MARK: - 대비(Contrast) 유틸리티
//
// 쿠폰/마감임박 카드는 브랜드 색이나 스크린샷 평균색을 액센트로 쓰고, 그 액센트를
// 그대로 글자색으로도 씁니다. 액센트가 실행 시점에 결정되므로 색 목록을 손으로
// 관리할 수 없고, 휘도를 계산해 대비를 보정해야 합니다.
extension Color {
    /// hex 문자열을 0~255 RGBA 성분으로 파싱합니다. (#RGB / #RRGGBB / #AARRGGBB)
    fileprivate static func rgbaComponents(hex rawHex: String) -> (a: UInt64, r: UInt64, g: UInt64, b: UInt64) {
        let hex = rawHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: hex).scanHexInt64(&int)
        switch hex.count {
        case 3: return (255, (int>>8)*17, (int>>4&0xF)*17, (int&0xF)*17)
        case 6: return (255, int>>16, int>>8&0xFF, int&0xFF)
        case 8: return (int>>24, int>>16&0xFF, int>>8&0xFF, int&0xFF)
        default: return (255, 0, 0, 0)
        }
    }

    fileprivate typealias RGB = (r: Double, g: Double, b: Double)

    /// WCAG 2.1 상대 휘도(0…1)
    fileprivate static func luminance(_ c: RGB) -> Double {
        func channel(_ v: Double) -> Double {
            v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
    }

    /// 두 휘도 사이의 대비율. AA 본문 기준 4.5, 큰 글자·그래픽 기준 3.0
    fileprivate static func contrastRatio(_ l1: Double, _ l2: Double) -> Double {
        let hi = max(l1, l2), lo = min(l1, l2)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// SwiftUI Color의 sRGB 성분. 동적 색이면 현재 trait으로 해석됩니다.
    fileprivate var srgbComponents: RGB? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return (Double(r), Double(g), Double(b))
    }

    /// WCAG 2.1 상대 휘도(0…1)를 hex에서 계산합니다.
    static func relativeLuminance(hex: String) -> Double {
        let c = rgbaComponents(hex: hex)
        return luminance((Double(c.r)/255, Double(c.g)/255, Double(c.b)/255))
    }

    /// 배경 위에서 대비가 더 큰 전경색(검정 또는 흰색)을 고릅니다.
    /// 순수 검정/흰색만 후보로 두어 어떤 배경에서도 얻을 수 있는 최대 대비를 보장합니다.
    static func readableForeground(onHex hex: String) -> Color {
        let bg = relativeLuminance(hex: hex)
        return contrastRatio(bg, 0) >= contrastRatio(bg, 1) ? .black : .white
    }

    /// `background` 위에서 `minimumRatio`를 만족할 때까지 색조를 유지하며 밝기만 낮추거나 높인 색.
    ///
    /// 이미 기준을 넘으면 원본을 그대로 돌려주므로 진한 브랜드 색은 손대지 않습니다.
    /// 검정/흰색을 100% 섞어도 기준에 못 미치는 배경(중간 회색)에서는 달성 가능한 최대 대비를 씁니다.
    func contrasting(on background: Color, minimumRatio: Double = 4.5) -> Color {
        guard let fg = srgbComponents, let bg = background.srgbComponents else { return self }
        let bgLuminance = Color.luminance(bg)
        if Color.contrastRatio(Color.luminance(fg), bgLuminance) >= minimumRatio { return self }

        // 밝은 배경에서는 검정 쪽으로, 어두운 배경에서는 흰색 쪽으로 섞습니다.
        let target: Color.RGB = bgLuminance > 0.18 ? (0, 0, 0) : (1, 1, 1)
        func blend(_ t: Double) -> Color.RGB {
            (fg.r + (target.r - fg.r) * t,
             fg.g + (target.g - fg.g) * t,
             fg.b + (target.b - fg.b) * t)
        }
        // 혼합비 t에 대해 대비는 단조 증가하므로 이분 탐색으로 최소 t를 찾습니다.
        // 기준을 만족하는 t가 없으면 t = 1(검정/흰색)이 그대로 남습니다.
        var best = blend(1)
        var low = 0.0, high = 1.0
        for _ in 0..<16 {
            let mid = (low + high) / 2
            let candidate = blend(mid)
            if Color.contrastRatio(Color.luminance(candidate), bgLuminance) >= minimumRatio {
                best = candidate
                high = mid
            } else {
                low = mid
            }
        }
        return Color(.sRGB, red: best.r, green: best.g, blue: best.b, opacity: 1)
    }

    /// 라이트/다크에서 서로 다른 hex를 쓰는 동적 색.
    /// 고정 hex 토큰은 다크모드에서 배경과 붙어버리므로, 명도에 민감한 토큰에만 씁니다.
    /// (브랜드 그라디언트·소셜 로고처럼 정체성이 있는 색은 고정값 그대로 둡니다.)
    static func adaptive(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { trait in
            UIColor(Color(hex: trait.userInterfaceStyle == .dark ? dark : light))
        })
    }

    /// self 위에 `overlay`를 `fraction`(0…1) 알파로 합성한 불투명 색.
    /// 반투명 오버레이가 깔린 표면의 실제 색을 대비 계산 기준으로 쓰기 위해 필요합니다.
    func composited(with overlay: Color, fraction: Double) -> Color {
        guard let base = srgbComponents, let top = overlay.srgbComponents else { return self }
        return Color(.sRGB,
                     red: base.r + (top.r - base.r) * fraction,
                     green: base.g + (top.g - base.g) * fraction,
                     blue: base.b + (top.b - base.b) * fraction,
                     opacity: 1)
    }

    init(hex: String) {
        let c = Color.rgbaComponents(hex: hex)
        self.init(.sRGB,
                  red: Double(c.r)/255, green: Double(c.g)/255, blue: Double(c.b)/255,
                  opacity: Double(c.a)/255)
    }
}
