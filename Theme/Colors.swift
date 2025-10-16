import SwiftUI

extension Color {
    // MARK: - Brand palette (was `Brand`)
    static let brandGradientTop    = Color(hex: "#87ABA4")
    static let brandGradientBottom = Color(hex: "#FFFCF1")
    
    static let joinButton  = Color(hex: "#AABBBE")
    static let loginButton = Color(hex: "#5E5858")

    
    static let brandBgTop    = Color(hex: "#FFFCC1")
    static let brandBgBottom = Color(hex: "#87ABA4")
    static let brandHeader   = Color(hex: "#CFE8E0")
    static let brandCardBG   = Color(hex: "#FAFAFA")
    static let brandLine     = Color(hex: "#EDEDED")
    static let brandAccent   = Color(hex: "#96BAC1")
    static let brandGreenCard = Color(hex: "#4AA465")
    static let brandTextMain = Color.black.opacity(0.85)
    static let brandTextSub  = Color.black.opacity(0.4)

    // MARK: - Global color tokens
    static let caplogBlack       = Color(hex: "#000000")
    static let caplogWhite       = Color(hex: "#FFFFFF")
    static let caplogGrayLight   = Color(hex: "#EEEEEE")
    static let caplogGrayMedium  = Color(hex: "#C4C4C4")
    static let caplogGrayDark    = Color(hex: "#5D5858")
    static let accentGreen = Color(red: 0.06, green: 0.36, blue: 0)

    static let registerGreen         = Color(hex: "#34A853")
    static let registerGoogleBlue    = Color(hex: "#4285F4")
    static let registerKakaoYellow   = Color(hex: "#FBBC05")
    static let registerRed           = Color(hex: "#EA4335")
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

    // --- 기존 컴포넌트 호환용 별칭 ---
    static let checkMint   = Color(hex: "#8FD694")           // CheckBoxView
    static let divider     = Color.gray.opacity(0.3)         // UnderlineTextField
    static let placeholder = Color(.placeholderText)         // 호환용
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int>>8)*17, (int>>4 & 0xF)*17, (int & 0xF)*17)
        case 6:  (a, r, g, b) = (255, int>>16, int>>8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int>>24, int>>16 & 0xFF, int>>8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:   Double(r)/255,
                  green: Double(g)/255,
                  blue:  Double(b)/255,
                  opacity: Double(a)/255)
    }
}
