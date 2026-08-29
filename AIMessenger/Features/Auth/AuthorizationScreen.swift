import SwiftUI

struct AuthorizationScreen: View {
    let onContinue: () -> Void

    @State private var phoneNumber = ""
    @State private var syncContacts = true

    private let keypad = [
        ("1", ""),
        ("2", "ABC"),
        ("3", "DEF"),
        ("4", "GHI"),
        ("5", "JKL"),
        ("6", "MNO"),
        ("7", "PQRS"),
        ("8", "TUV"),
        ("9", "WXYZ"),
        ("", ""),
        ("0", ""),
        ("⌫", "")
    ]

    var body: some View {
        ZStack {
            authBackground

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroCard
                        phoneCard
                        syncCard
                        keypadView
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 112)
                }
            }

            VStack {
                Spacer()

                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 134, height: 5)
                    .padding(.bottom, 9)
            }
        }
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button("Cancel") { }
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(TelegramPalette.accentBlue)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(Color.white.opacity(0.62), in: Capsule(style: .continuous))

            Spacer()

            Button("Next") {
                onContinue()
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(TelegramPalette.accentBlue)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(Color.white.opacity(0.78), in: Capsule(style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var keypadView: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(keypad, id: \.0) { key in
                    keypadButton(number: key.0, letters: key.1)
                }
            }
            .padding(16)
        }
        .background(glassCard)
    }

    private func keypadButton(number: String, letters: String) -> some View {
        Button {
            handleKey(number)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(number.isEmpty ? 0 : 0.88))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(number.isEmpty ? 0 : 0.82), lineWidth: 1)
                    }

                if number == "⌫" {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(TelegramPalette.settingsPrimaryText.opacity(0.72))
                } else if !number.isEmpty {
                    VStack(spacing: 3) {
                        Text(number)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(TelegramPalette.settingsPrimaryText)

                        Text(letters)
                            .font(.system(size: 12, weight: .medium))
                            .tracking(1.2)
                            .foregroundStyle(TelegramPalette.settingsSecondaryText)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 74)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Phone")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(TelegramPalette.settingsPrimaryText)

                    Text("Confirm your country code and enter the number for your AI messenger workspace.")
                        .font(.system(size: 17))
                        .foregroundStyle(TelegramPalette.settingsSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0x59B8FF), Color(hex: 0x7D63FF)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }

            HStack(spacing: 8) {
                authPill("Private")
                authPill("Fast login")
                authPill("Contacts sync")
            }
        }
        .padding(22)
        .background(glassCard)
    }

    private var phoneCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Region")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(TelegramPalette.settingsSecondaryText)

                Spacer()

                Text("United States")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(TelegramPalette.settingsPrimaryText)
            }
            .padding(.horizontal, 18)
            .frame(height: 54)

            Rectangle()
                .fill(Color.white.opacity(0.78))
                .frame(height: 0.5)
                .padding(.leading, 18)

            HStack(spacing: 14) {
                Text("+1")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(TelegramPalette.settingsPrimaryText)
                    .frame(width: 54, alignment: .leading)

                Rectangle()
                    .fill(Color.white.opacity(0.78))
                    .frame(width: 1, height: 42)

                HStack(spacing: 3) {
                    Text(phoneNumber.isEmpty ? "Your phone number" : formattedPhone)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(phoneNumber.isEmpty ? TelegramPalette.settingsSecondaryText.opacity(0.42) : TelegramPalette.settingsPrimaryText)

                    if phoneNumber.isEmpty {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(TelegramPalette.accentBlue)
                            .frame(width: 2, height: 26)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .frame(height: 74)
        }
        .background(glassCard)
    }

    private var syncCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sync Contacts")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(TelegramPalette.settingsPrimaryText)

                Text("Import people and AI spaces into one contact list.")
                    .font(.system(size: 14))
                    .foregroundStyle(TelegramPalette.settingsSecondaryText)
            }

            Spacer()

            Toggle("", isOn: $syncContacts)
                .labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(glassCard)
    }

    private func authPill(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(TelegramPalette.settingsPrimaryText)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color.white.opacity(0.64), in: Capsule(style: .continuous))
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(TelegramPalette.settingsCard)
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(TelegramPalette.settingsCardStroke, lineWidth: 1)
            }
            .shadow(color: TelegramPalette.settingsShadow, radius: 24, y: 12)
    }

    private var authBackground: some View {
        LinearGradient(
            colors: [TelegramPalette.settingsCanvasTop, TelegramPalette.settingsCanvasBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color(hex: 0xCDD6FF, opacity: 0.45))
                .frame(width: 250, height: 250)
                .blur(radius: 62)
                .offset(x: -70, y: -80)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: 0xFFE0C5, opacity: 0.62))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: 70, y: -40)
        }
        .ignoresSafeArea()
    }

    private var formattedPhone: String {
        let numbers = Array(phoneNumber.prefix(10))
        guard !numbers.isEmpty else { return "" }

        var result = ""
        for (index, char) in numbers.enumerated() {
            if index == 0 { result += "(" }
            if index == 3 { result += ") " }
            if index == 6 { result += "-" }
            result.append(char)
        }
        return result
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            _ = phoneNumber.popLast()
        case "":
            break
        default:
            guard phoneNumber.count < 10 else { return }
            phoneNumber.append(key)
        }
    }
}

struct AuthorizationScreen_Previews: PreviewProvider {
    static var previews: some View {
        AuthorizationScreen { }
    }
}
