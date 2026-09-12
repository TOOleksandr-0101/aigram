import SwiftUI

enum TelegramPalette {
    static let backgroundPrimary = Color(hex: 0x000000)
}

typealias AIGramPalette = TelegramPalette

extension TelegramPalette {
    static let backgroundElevated = Color(hex: 0x1C1C1E)
    static let tabBarBackground = Color(hex: 0x1C1C1D)
    static let groupedBackground = Color(hex: 0x000000)
    static let separator = Color(hex: 0x3D3D3F)
    static let mutedText = Color(hex: 0x8E8E93)
    static let searchFill = Color.black.opacity(0.45)
    static let accentBlue = Color(hex: 0x037EE5)
    static let skyBlue = Color(hex: 0x37A8FF)
    static let successGreen = Color(hex: 0x08A723)
    static let warningOrange = Color(hex: 0xCD7800)
    static let destructiveRed = Color(hex: 0xC60C0C)
    static let unreadGray = Color(hex: 0x666666)
    static let lightSeparator = Color.white.opacity(0.12)
    static let settingsCanvasTop = Color(hex: 0x000000)
    static let settingsCanvasBottom = Color(hex: 0x0A0A0C)
    static let settingsCard = Color(hex: 0x1C1C1E)
    static let settingsCardStroke = Color.white.opacity(0.08)
    static let settingsShadow = Color.black.opacity(0.35)
    static let settingsPrimaryText = Color.white
    static let settingsSecondaryText = Color(hex: 0x8E8E93)
    static let settingsSearchFill = Color.white.opacity(0.08)
    static let outgoingBubble = Color(hex: 0x0A84FF)
    static let incomingBubble = Color(hex: 0x1C1C1E)
}

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
