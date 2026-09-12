import SwiftUI

struct EditProfileScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace

    @State private var showPhotoSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                navigationBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 23) {
                        profileCard
                        bioSection
                        infoRows
                    }
                    .padding(.bottom, 32)
                }
                .background(TelegramPalette.groupedBackground)
            }
            .background(TelegramPalette.groupedBackground.ignoresSafeArea())

            if showPhotoSheet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showPhotoSheet = false
                    }

                photoActionSheet
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showPhotoSheet)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var navigationBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17))
                }
                .foregroundStyle(TelegramPalette.accentBlue)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Profile")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(TelegramPalette.accentBlue)
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button {
                    showPhotoSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0x6C4B32), Color(hex: 0x2B1C12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Circle()
                            .fill(Color.black.opacity(0.28))

                        Text(aiWorkspace.initials)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 66, height: 66)
                }
                .buttonStyle(.plain)

                VStack(spacing: 12) {
                    TextField("Display name", text: $aiWorkspace.displayName)
                        .font(.system(size: 17))
                        .foregroundStyle(.white)

                    Rectangle()
                        .fill(TelegramPalette.separator)
                        .frame(height: 0.5)

                    TextField("Username", text: $aiWorkspace.username)
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Rectangle()
                        .fill(TelegramPalette.separator)
                        .frame(height: 0.5)

                    TextField("Phone", text: $aiWorkspace.phoneNumber)
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                        .keyboardType(.phonePad)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)
            .background(TelegramPalette.backgroundElevated)

            Text("Choose how your workspace appears across chats, calls, and contacts.")
                .font(.system(size: 14))
                .foregroundStyle(TelegramPalette.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 7)
        }
    }

    private var bioSection: some View {
        VStack(spacing: 0) {
            TextField("About", text: $aiWorkspace.bio, axis: .vertical)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(TelegramPalette.backgroundElevated)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(TelegramPalette.separator)
                        .frame(height: 0.5)
                }
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(TelegramPalette.separator)
                        .frame(height: 0.5)
                }

            Text("Describe what this space is for. Example: private hub for coding, research, and study assistants.")
                .font(.system(size: 14))
                .foregroundStyle(TelegramPalette.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
    }

    private var infoRows: some View {
        VStack(spacing: 0) {
            settingsRow(title: "Model", value: aiWorkspace.modelDisplayName)
            settingsRow(title: "Provider", value: aiWorkspace.isConfigured ? "OpenRouter" : "Offline fallback")
            settingsRow(title: "Privacy", value: aiWorkspace.useZeroRetention ? "Zero retention" : "Standard", showSeparator: false)
        }
        .background(TelegramPalette.backgroundElevated)
        .overlay {
            RoundedRectangle(cornerRadius: 0)
                .stroke(TelegramPalette.separator, lineWidth: 0.5)
        }
    }

    private func settingsRow(title: String, value: String, showSeparator: Bool = true) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.white)

            Spacer()

            Text(value)
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.mutedText)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Rectangle()
                    .fill(TelegramPalette.separator)
                    .frame(height: 0.5)
                    .padding(.leading, 16)
            }
        }
    }

    private var photoActionSheet: some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    photoPreview(colors: [Color(hex: 0xFFB347), Color(hex: 0xFF6E4A)], symbol: "camera.fill")
                    photoPreview(colors: [Color(hex: 0x5A2D1F), Color(hex: 0xD68B72)], symbol: "person.fill")
                    photoPreview(colors: [Color(hex: 0x3C322A), Color(hex: 0xA18D72)], symbol: "sparkles")
                    photoPreview(colors: [Color(hex: 0x6B7A89), Color(hex: 0xC4CED7)], symbol: "moon.stars.fill")
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 8)

                sheetOption("Choose Photo", color: TelegramPalette.accentBlue)
                sheetDivider
                sheetOption("View Photo", color: TelegramPalette.accentBlue)
                sheetDivider
                sheetOption("Remove Photo", color: Color(hex: 0xFE3B30))
            }
            .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            Button {
                showPhotoSheet = false
            } label: {
                Text("Cancel")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(TelegramPalette.accentBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 57)
                    .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 32)
    }

    private var sheetDivider: some View {
        Rectangle()
            .fill(TelegramPalette.separator)
            .frame(height: 0.5)
    }

    private func sheetOption(_ title: String, color: Color) -> some View {
        Button {
            showPhotoSheet = false
        } label: {
            Text(title)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 57)
        }
        .buttonStyle(.plain)
    }

    private func photoPreview(colors: [Color], symbol: String) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(height: 84)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.28), in: Circle())
            }
    }
}

struct EditProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileScreen()
            .environmentObject(AIWorkspace())
    }
}
