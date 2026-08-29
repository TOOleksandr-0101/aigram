import SwiftUI

struct PlaceholderScreen: View {
    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [TelegramPalette.backgroundPrimary, Color(hex: 0x121214)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: symbol)
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(accent)

                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(TelegramPalette.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 80)
        }
    }
}

struct PlaceholderScreen_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderScreen(
            title: "AI Contacts",
            subtitle: "Directory of assistant personas, each with a role and tone for your coursework.",
            symbol: "person.2.crop.square.stack.fill",
            accent: TelegramPalette.skyBlue
        )
    }
}
