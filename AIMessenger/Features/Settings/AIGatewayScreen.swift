import SwiftUI

struct AIGatewayScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace

    @State private var isTestingConnection: Bool = false
    @State private var testResult: (success: Bool, latencyMs: Int, message: String)?

    private var currentPresets: [(name: String, slug: String, badge: String)] {
        switch aiWorkspace.selectedProvider {
        case .openRouter:
            return [
                ("Claude 3.5 Sonnet", "anthropic/claude-3.5-sonnet", "Coding & Logic"),
                ("GPT-4o", "openai/gpt-4o", "Universal"),
                ("DeepSeek V3", "deepseek/deepseek-chat", "Fast & Low-cost"),
                ("Llama 3.3 70B", "meta-llama/llama-3.3-70b-instruct", "Open Source"),
                ("Qwen 3.5 9B", "qwen/qwen3.5-9b", "Default / Budget")
            ]
        case .openAI:
            return [
                ("GPT-4o", "gpt-4o", "Flagship Model"),
                ("GPT-4o mini", "gpt-4o-mini", "Fast & Lightweight"),
                ("o3-mini", "o3-mini", "Deep Reasoning"),
                ("o1", "o1", "High Capability")
            ]
        case .groq:
            return [
                ("Llama 3.3 70B", "llama-3.3-70b-versatile", "Ultra Fast (500+ T/s)"),
                ("Llama 3.1 8B", "llama-3.1-8b-instant", "Instant Speed"),
                ("Mixtral 8x7B", "mixtral-8x7b-32768", "MoE Architecture")
            ]
        case .ollama:
            return [
                ("Llama 3.2", "llama3.2", "Local On-Device"),
                ("Qwen 2.5 Coder", "qwen2.5-coder", "Local Coding"),
                ("Mistral 7B", "mistral", "Local Fast Inference")
            ]
        }
    }

    var body: some View {
        DetailScreenContainer(title: "AI Gateway", backTitle: "Back", trailingTitle: "Done", dismissAction: { dismiss() }) {
            ScrollViewReader { scrollProxy in
                VStack(spacing: 22) {
                // Provider Selection
                lightGroup {
                    sectionTitle("LLM Provider")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(LLMProviderKind.allCases) { provider in
                                Button {
                                    aiWorkspace.selectedProvider = provider
                                    aiWorkspace.modelSlug = provider.defaultModel
                                    testResult = nil
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: providerIcon(for: provider))
                                            .font(.system(size: 13, weight: .semibold))

                                        Text(provider.rawValue)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        aiWorkspace.selectedProvider == provider
                                            ? TelegramPalette.accentBlue
                                            : TelegramPalette.settingsCard
                                    )
                                    .foregroundStyle(
                                        aiWorkspace.selectedProvider == provider
                                            ? Color.white
                                            : TelegramPalette.settingsPrimaryText
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                aiWorkspace.selectedProvider == provider
                                                    ? Color.clear
                                                    : Color.white.opacity(0.12),
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    footerNote("Choose your preferred AI backend. You can connect cloud endpoints or run private local models via Ollama.")
                }

                // Verified Presets
                lightGroup {
                    sectionTitle("Popular Presets for \(aiWorkspace.selectedProvider.rawValue)")

                    VStack(spacing: 0) {
                        ForEach(Array(currentPresets.enumerated()), id: \.offset) { index, model in
                            Button {
                                aiWorkspace.modelSlug = model.slug
                                testResult = nil
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(TelegramPalette.settingsPrimaryText)
                                        Text(model.badge)
                                            .font(.system(size: 13))
                                            .foregroundStyle(TelegramPalette.settingsSecondaryText)
                                    }

                                    Spacer()

                                    if aiWorkspace.trimmedModelSlug == model.slug {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(TelegramPalette.accentBlue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if index < currentPresets.count - 1 {
                                divider
                            }
                        }
                    }

                    footerNote("Tap any preset to automatically select it, or customize model slug below.")
                }

                // Connection Parameters
                lightGroup {
                    sectionTitle("Connection")

                    VStack(spacing: 0) {
                        if aiWorkspace.selectedProvider.requiresKey {
                            secureInputRow(
                                title: "API Key",
                                placeholder: keyPlaceholder(for: aiWorkspace.selectedProvider),
                                text: $aiWorkspace.apiKey
                            )
                            divider
                        }

                        inputRow(
                            title: "Model",
                            placeholder: aiWorkspace.selectedProvider.defaultModel,
                            text: $aiWorkspace.modelSlug
                        )

                        divider

                        inputRow(
                            title: "Endpoint",
                            placeholder: aiWorkspace.selectedProvider.defaultEndpoint,
                            text: $aiWorkspace.customEndpoint
                        )
                    }

                    footerNote(aiWorkspace.selectedProvider.requiresKey
                        ? "API key is stored locally in device Keychain/UserDefaults and never shared."
                        : "No API key required for local inference. Ensure Ollama is running on localhost."
                    )
                }

                // Test Connection & Status
                lightGroup {
                    sectionTitle("Live Diagnostics")

                    VStack(spacing: 12) {
                        HStack {
                            Text("Gateway Status")
                                .font(.system(size: 16))
                                .foregroundStyle(TelegramPalette.settingsPrimaryText)

                            Spacer()

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(aiWorkspace.isConfigured ? Color(hex: 0x17975F) : Color(hex: 0xC67A00))
                                    .frame(width: 8, height: 8)

                                Text(aiWorkspace.isConfigured ? "Ready" : "Needs Key")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(aiWorkspace.isConfigured ? Color(hex: 0x17975F) : Color(hex: 0xC67A00))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                        divider

                        // Test Connection Button
                        Button {
                            runConnectionTest()
                        } label: {
                            HStack {
                                if isTestingConnection {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.9)
                                    Text("Pinging Endpoint...")
                                        .font(.system(size: 16, weight: .semibold))
                                } else {
                                    Image(systemName: "bolt.horizontal.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Test Connection")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(TelegramPalette.accentBlue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }
                        .disabled(isTestingConnection)

                        if let result = testResult {
                            HStack(spacing: 8) {
                                Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(result.success ? Color(hex: 0x17975F) : Color(hex: 0xEF4444))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.message)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(TelegramPalette.settingsPrimaryText)

                                    if result.latencyMs > 0 {
                                        Text("Latency: \(result.latencyMs) ms")
                                            .font(.system(size: 11))
                                            .foregroundStyle(TelegramPalette.settingsSecondaryText)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Spacer().frame(height: 4)
                    }

                    footerNote("Tests latency and connectivity to the selected model provider.")
                }
                .id("diagnosticsCard")

                if aiWorkspace.selectedProvider == .openRouter {
                    lightGroup {
                        sectionTitle("Privacy Flags")
                        toggleRow("Zero Retention only", isOn: $aiWorkspace.useZeroRetention)
                        divider
                        toggleRow("Deny provider logging", isOn: $aiWorkspace.denyProviderLogging)
                        footerNote("These flags request OpenRouter to route through zero-data-retention nodes.")
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-testGateway") {
                    testResult = (success: true, latencyMs: 38, message: "Connected to Groq Cloud Gateway (HTTP 200 OK)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            scrollProxy.scrollTo("diagnosticsCard", anchor: .bottom)
                        }
                    }
                }
            }
            }
        }
    }

    private func runConnectionTest() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isTestingConnection = true
        testResult = nil

        Task {
            let result = await OpenRouterService().testConnection(configuration: aiWorkspace.configurationSnapshot)
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isTestingConnection = false
                    testResult = result
                }
                if result.success {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
        }
    }

    private func providerIcon(for provider: LLMProviderKind) -> String {
        switch provider {
        case .openRouter: return "network"
        case .openAI: return "sparkle"
        case .groq: return "bolt.fill"
        case .ollama: return "laptopcomputer"
        }
    }

    private func keyPlaceholder(for provider: LLMProviderKind) -> String {
        switch provider {
        case .openRouter: return "sk-or-v1-..."
        case .openAI: return "sk-proj-..."
        case .groq: return "gsk_..."
        case .ollama: return "None needed"
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
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(TelegramPalette.settingsPrimaryText)
            } else {
                Text(text.wrappedValue)
                    .font(.system(size: 15, weight: .medium))
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
                .font(.system(size: 15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(TelegramPalette.settingsPrimaryText)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }
}
