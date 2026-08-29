import SwiftUI

enum TelegramPalette {
    static let backgroundPrimary = Color(hex: 0x000000)
    static let backgroundElevated = Color(hex: 0x1C1C1E)
    static let tabBarBackground = Color(hex: 0x1C1C1D)
    static let groupedBackground = Color(hex: 0xEFEFF4)
    static let separator = Color(hex: 0x3D3D3F)
    static let mutedText = Color(hex: 0x8E8E93)
    static let searchFill = Color.black.opacity(0.45)
    static let accentBlue = Color(hex: 0x037EE5)
    static let skyBlue = Color(hex: 0x37A8FF)
    static let successGreen = Color(hex: 0x08A723)
    static let warningOrange = Color(hex: 0xCD7800)
    static let destructiveRed = Color(hex: 0xC60C0C)
    static let unreadGray = Color(hex: 0x666666)
    static let lightSeparator = Color.black.opacity(0.12)
    static let settingsCanvasTop = Color(hex: 0xF7F8FD)
    static let settingsCanvasBottom = Color(hex: 0xEBEEF8)
    static let settingsCard = Color.white.opacity(0.82)
    static let settingsCardStroke = Color.white.opacity(0.7)
    static let settingsShadow = Color(hex: 0x8C98B8, opacity: 0.18)
    static let settingsPrimaryText = Color(hex: 0x111322)
    static let settingsSecondaryText = Color(hex: 0x6D738A)
    static let settingsSearchFill = Color.white.opacity(0.72)
}

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
