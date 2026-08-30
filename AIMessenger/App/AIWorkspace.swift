import SwiftUI

struct OpenRouterConfiguration {
    let apiKey: String
    let modelSlug: String
    let useZeroRetention: Bool
    let denyProviderLogging: Bool
}

@MainActor
final class AIWorkspace: ObservableObject {
    @Published var displayName: String {
        didSet { defaults.set(displayName, forKey: Keys.displayName) }
    }

    @Published var username: String {
        didSet { defaults.set(username, forKey: Keys.username) }
    }

    @Published var bio: String {
        didSet { defaults.set(bio, forKey: Keys.bio) }
    }

    @Published var apiKey: String {
        didSet { defaults.set(apiKey, forKey: Keys.apiKey) }
    }

    @Published var modelSlug: String {
        didSet { defaults.set(modelSlug, forKey: Keys.modelSlug) }
    }

    @Published var useZeroRetention: Bool {
        didSet { defaults.set(useZeroRetention, forKey: Keys.useZeroRetention) }
    }

    @Published var denyProviderLogging: Bool {
        didSet { defaults.set(denyProviderLogging, forKey: Keys.denyProviderLogging) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.displayName = defaults.string(forKey: Keys.displayName) ?? "My Space"
        self.username = defaults.string(forKey: Keys.username) ?? "@my_space"
        self.bio = defaults.string(forKey: Keys.bio) ?? "Private AI chat hub for study, coding, research, and design."
        self.apiKey = defaults.string(forKey: Keys.apiKey) ?? ""
        self.modelSlug = defaults.string(forKey: Keys.modelSlug) ?? "qwen/qwen3.5-9b"
        self.useZeroRetention = defaults.object(forKey: Keys.useZeroRetention) as? Bool ?? true
        self.denyProviderLogging = defaults.object(forKey: Keys.denyProviderLogging) as? Bool ?? true
    }

    var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedModelSlug: String {
        let slug = modelSlug.trimmingCharacters(in: .whitespacesAndNewlines)
        return slug.isEmpty ? "qwen/qwen3.5-9b" : slug
    }

    var isConfigured: Bool {
        trimmedAPIKey.isEmpty == false
    }

    var initials: String {
        let pieces = displayName
            .split(whereSeparator: \.isWhitespace)
            .prefix(2)
            .compactMap { $0.first }

        let result = String(pieces)
        return result.isEmpty ? "AI" : result.uppercased()
    }

    var modelDisplayName: String {
        let parts = trimmedModelSlug.split(separator: "/")
        return String(parts.last ?? Substring(trimmedModelSlug))
    }

    var connectionLabel: String {
        isConfigured ? "OpenRouter connected" : "Local fallback only"
    }

    var configurationSnapshot: OpenRouterConfiguration {
        OpenRouterConfiguration(
            apiKey: trimmedAPIKey,
            modelSlug: trimmedModelSlug,
            useZeroRetention: useZeroRetention,
            denyProviderLogging: denyProviderLogging
        )
    }
}

private enum Keys {
    static let displayName = "aiworkspace.profile.displayName"
    static let username = "aiworkspace.profile.username"
    static let bio = "aiworkspace.profile.bio"
    static let apiKey = "aiworkspace.openrouter.apiKey"
    static let modelSlug = "aiworkspace.openrouter.modelSlug"
    static let useZeroRetention = "aiworkspace.openrouter.useZeroRetention"
    static let denyProviderLogging = "aiworkspace.openrouter.denyProviderLogging"
}
