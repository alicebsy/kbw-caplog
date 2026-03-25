import SwiftUI

extension Color {
    // Brand (기존 팔레트 유지)
    static let brandGradientTop    = Color(hex: "#87ABA4")
    static let brandGradientBottom = Color(hex: "#FFFCF1")
    static let joinButton  = Color(hex: "#AABBBE")
    static let loginButton = Color(hex: "#5E5858")
    static let brandBgTop      = Color(hex: "#FFFCC1")
    static let brandBgBottom   = Color(hex: "#87ABA4")
    static let brandHeader     = Color(hex: "#CFE8E0")
    static let brandCardBG     = Color(hex: "#F5F5F5")
    static let brandLine       = Color(hex: "#EDEDED")
    static let brandAccent     = Color(hex: "#96BAC1")
    static let brandGreenCard  = Color(hex: "#4AA465")
    static let brandTextMain   = Color.black.opacity(0.85)
    static let brandTextSub    = Color.black.opacity(0.4)

    // Global
    static let caplogBlack       = Color(hex: "#000000")
    static let caplogWhite       = Color(hex: "#FFFFFF")
    static let caplogGrayLight   = Color(hex: "#EEEEEE")
    static let caplogGrayMedium  = Color(hex: "#C4C4C4")
    static let caplogGrayDark    = Color(hex: "#5D5858")

    // 기존 사용 중
    static let accentGreen       = Color(red: 0.06, green: 0.36, blue: 0)

    // Register 등
    static let registerGreen         = Color(hex: "#34A853")
    static let registerGoogleBlue    = Color(hex: "#4285F4")
    static let registerKakaoYellow   = Color(hex: "#FBBC05")
    static let registerRed           = Color(hex: "#EA4335")
    static let unreadBadgeRed        = Color(hex: "#F4525F")
    static let registerGray          = Color(hex: "#AABABE")
    static let registerGrayLight     = Color(hex: "#F1F1F1")
    static let registerGrayMid       = Color(hex: "#BEC1C2")
    static let registerLineGray      = Color(hex: "#E4E8E9")
    static let registerBackground    = Color(hex: "#F5F8F6")
    static let registerTextGray      = Color(hex: "#8D8D8D")
    static let registerPlaceholder   = Color(hex: "#C4C4C6")
    static let registerToJoin        = Color(hex: "#BFC2C3")
    static let registerButtonGray    = Color(hex: "#74727F")
    static let registerInactive      = Color(hex: "#FDFDFD")

    static let homeGreenDark       = Color(hex: "#144749")
    static let homeGreen           = Color(hex: "#A4CFCA")
    static let homeGreenLight      = Color(hex: "#C1E4E0")
    static let homeGrayDeep        = Color(hex: "#2B2B2B")
    static let homeGrayText        = Color(hex: "#444444")
    static let homeGraySub         = Color(hex: "#666666")
    static let homeBackgroundLight = Color(hex: "#F9FAFB")
    static let homeBackgroundMid   = Color(hex: "#DFD9D9")
    static let homeCardShadow      = Color(hex: "#DEDEDE")
    static let homeBorder          = Color(hex: "#C4C4C4")
    static let homeWhiteOpacity    = Color.white.opacity(0.9)
    static let homeBlackOpacity60  = Color.black.opacity(0.6)
    static let homeBlackOpacity30  = Color.black.opacity(0.3)

    // Common aliases
    static let checkMint   = Color(hex: "#8FD694")
    static let divider     = Color.gray.opacity(0.3)
    static let placeholder = Color(.placeholderText)

    // === MyPage 전용 토큰 ===
    static let myPageActionBlue   = Color(hex: "#2E6CF6")
    static let myPageActionBlueBg = Color(hex: "#2E6CF6").opacity(0.12)
    static let myPageSectionGreen = Color.accentGreen

    // === 마감 임박 카드: 브랜드별 색상 (원래 톤) ===
    static func expiringCardBrandColor(brandName: String?) -> Color {
        guard let name = brandName?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return Color(hex: "#46A68E") // 기본 민트그린
        }
        if name.contains("스타벅스") || name.contains("starbucks") { return Color(hex: "#46A68E") }      // 기존 초록을 조금 밝게
        if name.contains("이마트") || name.contains("emart")       { return Color(hex: "#F7BF5B") }      // 부드러운 머스터드
        if name.contains("메가") || name.contains("megacoffee") ||
           name.contains("mgc")                                     { return Color(hex: "#A8744F") }      // 연한 브라운
        if name.contains("카카오") || name.contains("kakao")       { return Color(hex: "#FFEFA3") }      // 연한 옐로우
        if name.contains("gs25") || name.contains("gs 25")         { return Color(hex: "#9CD279") }      // 연한 그린
        if name.contains("cu") || name.contains("씨유")            { return Color(hex: "#C86B7B") }      // 약간 톤 다운된 레드/와인
        if name.contains("투썸") || name.contains("twosome")       { return Color(hex: "#D46C71") }      // 소프트 레드
        if name.contains("빽다방") || name.contains("baek")        { return Color(hex: "#4A4A4A") }      // 진한 그레이
        if name.contains("할리스") || name.contains("hollys")      { return Color(hex: "#7A567F") }      // 톤 다운 퍼플
        if name.contains("던킨") || name.contains("dunkin")        { return Color(hex: "#F48A7D") }      // 코랄 계열
        if name.contains("배스킨") || name.contains("baskin")      { return Color(hex: "#E97CA3") }      // 부드러운 핑크
        return Color(hex: "#46A68E")
    }

    /// 마감 임박 카드에서 브랜드 배경에 맞는 글자색 (밝은 배경이면 검정, 아니면 흰색)
    static func expiringCardTextColor(brandName: String?) -> Color {
        let name = (brandName ?? "").lowercased()
        if name.contains("카카오") || name.contains("kakao") { return .black }
        if name.contains("이마트") || name.contains("emart") { return .black }
        return .white
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB,
                  red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255,
                  opacity: Double(a)/255)
    }
}
