import SwiftUI

struct AIGatewayScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace

    var body: some View {
        DetailScreenContainer(title: "AI Gateway", backTitle: "Back", trailingTitle: "Done", dismissAction: { dismiss() }) {
            VStack(spacing: 22) {
                lightGroup {
                    sectionTitle("Connection")

                    VStack(spacing: 0) {
                        inputRow(title: "Provider", placeholder: "OpenRouter", text: .constant("OpenRouter"), editable: false)
                        divider
                        secureInputRow(title: "API Key", placeholder: "sk-or-v1-...", text: $aiWorkspace.apiKey)
                        divider
                        inputRow(title: "Model", placeholder: "qwen/qwen3.5-9b", text: $aiWorkspace.modelSlug)
                    }

                    footerNote("By default the app uses qwen/qwen3.5-9b as a balanced low-cost model. You can replace it with any exact OpenRouter model slug later.")
                }

                lightGroup {
                    sectionTitle("Privacy")
                    toggleRow("Zero Retention only", isOn: $aiWorkspace.useZeroRetention)
                    divider
                    toggleRow("Deny provider logging", isOn: $aiWorkspace.denyProviderLogging)
                    footerNote("These flags ask OpenRouter to route through stricter privacy policies when supported by the selected provider.")
                }

                lightGroup {
                    sectionTitle("Status")

                    HStack {
                        Text("Gateway")
                            .font(.system(size: 17))
                            .foregroundStyle(TelegramPalette.settingsPrimaryText)

                        Spacer()

                        Text(aiWorkspace.isConfigured ? "Ready" : "Needs key")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(aiWorkspace.isConfigured ? Color(hex: 0x17975F) : Color(hex: 0xC67A00))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)

                    divider

                    HStack {
                        Text("Current model")
                            .font(.system(size: 17))
                            .foregroundStyle(TelegramPalette.settingsPrimaryText)

                        Spacer()

                        Text(aiWorkspace.trimmedModelSlug)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(TelegramPalette.settingsSecondaryText)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    private func inputRow(
        title: String,
        placeholder: String,
        text: Binding<String>,
        editable: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.settingsPrimaryText)
                .frame(width: 82, alignment: .leading)

            if editable {
                TextField(placeholder, text: text)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(TelegramPalette.settingsPrimaryText)
            } else {
                Text(text.wrappedValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(TelegramPalette.settingsSecondaryText)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }

    private func secureInputRow(title: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.settingsPrimaryText)
                .frame(width: 82, alignment: .leading)

            SecureField(placeholder, text: text)
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(TelegramPalette.settingsPrimaryText)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }
}
