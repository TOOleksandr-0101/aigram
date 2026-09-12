import Foundation

enum LLMProviderKind: String, CaseIterable, Identifiable, Codable {
    case openRouter = "OpenRouter"
    case openAI = "OpenAI"
    case groq = "Groq"
    case ollama = "Local Ollama"

    var id: String { rawValue }

    var defaultEndpoint: String {
        switch self {
        case .openRouter: return "https://openrouter.ai/api/v1/chat/completions"
        case .openAI: return "https://api.openai.com/v1/chat/completions"
        case .groq: return "https://api.groq.com/openai/v1/chat/completions"
        case .ollama: return "http://localhost:11434/v1/chat/completions"
        }
    }

    var defaultModel: String {
        switch self {
        case .openRouter: return "qwen/qwen3.5-9b"
        case .openAI: return "gpt-4o-mini"
        case .groq: return "llama-3.3-70b-versatile"
        case .ollama: return "llama3.2"
        }
    }

    var requiresKey: Bool {
        switch self {
        case .ollama: return false
        default: return true
        }
    }
}

struct OpenRouterChatMessage: Encodable {
    let role: String
    let content: String
}

struct OpenRouterProviderOptions: Encodable {
    let allow_fallbacks: Bool
    let data_collection: String?
    let zdr: Bool?
}

struct OpenRouterRequestBody: Encodable {
    let model: String
    let messages: [OpenRouterChatMessage]
    let temperature: Double
    let provider: OpenRouterProviderOptions?
}

struct OpenRouterResponseBody: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }

        let message: Message
    }

    let model: String?
    let choices: [Choice]
}

enum OpenRouterServiceError: LocalizedError {
    case invalidKey
    case invalidResponse
    case emptyResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "Add an API key in Settings -> AI Gateway."
        case .invalidResponse:
            return "The provider returned an invalid response."
        case .emptyResponse:
            return "The model responded with an empty message."
        case let .serverError(message):
            return message
        }
    }
}

struct OpenRouterService {
    func sendMessage(
        draft: String,
        thread: ChatThread,
        history: [ConversationMessage],
        memoryNote: String,
        configuration: OpenRouterConfiguration
    ) async throws -> String {
        if configuration.provider.requiresKey && configuration.apiKey.isEmpty {
            throw OpenRouterServiceError.invalidKey
        }

        let endpointString = configuration.customEndpoint.isEmpty ? configuration.provider.defaultEndpoint : configuration.customEndpoint
        guard let url = URL(string: endpointString) else {
            throw OpenRouterServiceError.invalidResponse
        }

        let providerOpts: OpenRouterProviderOptions? = configuration.provider == .openRouter ? OpenRouterProviderOptions(
            allow_fallbacks: true,
            data_collection: configuration.denyProviderLogging ? "deny" : nil,
            zdr: configuration.useZeroRetention ? true : nil
        ) : nil

        let requestBody = OpenRouterRequestBody(
            model: configuration.modelSlug,
            messages: makeMessages(draft: draft, thread: thread, history: history, memoryNote: memoryNote),
            temperature: 0.85,
            provider: providerOpts
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if !configuration.apiKey.isEmpty {
            request.addValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("https://codex.local/aimessenger", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("AIGram", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterServiceError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed with status \(httpResponse.statusCode)."
            throw OpenRouterServiceError.serverError(message)
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponseBody.self, from: data)
        guard let content = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              content.isEmpty == false else {
            throw OpenRouterServiceError.emptyResponse
        }

        return content
    }

    func testConnection(configuration: OpenRouterConfiguration) async -> (success: Bool, latencyMs: Int, message: String) {
        if configuration.provider.requiresKey && configuration.apiKey.isEmpty {
            return (false, 0, "API key is required for \(configuration.provider.rawValue)")
        }

        let endpointString = configuration.customEndpoint.isEmpty ? configuration.provider.defaultEndpoint : configuration.customEndpoint
        guard let url = URL(string: endpointString) else {
            return (false, 0, "Invalid endpoint URL")
        }

        let testBody = OpenRouterRequestBody(
            model: configuration.modelSlug,
            messages: [OpenRouterChatMessage(role: "user", content: "Ping. Reply with 'OK'.")],
            temperature: 0.1,
            provider: nil
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if !configuration.apiKey.isEmpty {
            request.addValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("AIGram", forHTTPHeaderField: "X-Title")

        do {
            request.httpBody = try JSONEncoder().encode(testBody)
            let startTime = CFAbsoluteTimeGetCurrent()
            let (data, response) = try await URLSession.shared.data(for: request)
            let latencyMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, latencyMs, "Invalid HTTP response")
            }

            if (200...299).contains(httpResponse.statusCode) {
                return (true, latencyMs, "Connected successfully (\(latencyMs)ms)")
            } else {
                let errText = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
                return (false, latencyMs, "HTTP \(httpResponse.statusCode): \(errText.prefix(60))")
            }
        } catch {
            return (false, 0, error.localizedDescription)
        }
    }

    private func makeMessages(
        draft: String,
        thread: ChatThread,
        history: [ConversationMessage],
        memoryNote: String
    ) -> [OpenRouterChatMessage] {
        var system = """
        \(thread.aiProfile.rolePrompt)
        You are inside an iOS messenger app named AIGram where you appear as an AI collaborator.
        Keep replies natural, conversational, and message-sized by default.
        """

        if memoryNote.isEmpty == false {
            system += "\n\nSaved chat memory:\n\(memoryNote)"
        }

        let priorMessages = history.suffix(8).compactMap { message -> OpenRouterChatMessage? in
            let contentPrefix: String
            if message.side == .incoming, let authorName = message.authorName {
                contentPrefix = "[\(authorName)] "
            } else {
                contentPrefix = ""
            }

            switch message.payload {
            case let .text(text):
                return OpenRouterChatMessage(
                    role: message.side == .incoming ? "assistant" : "user",
                    content: contentPrefix + text
                )
            case let .emoji(value):
                return OpenRouterChatMessage(
                    role: message.side == .incoming ? "assistant" : "user",
                    content: contentPrefix + value
                )
            case let .photo(name, size):
                return OpenRouterChatMessage(
                    role: message.side == .incoming ? "assistant" : "user",
                    content: contentPrefix + "[Shared image: \(name), \(size)]"
                )
            case let .voice(duration):
                return OpenRouterChatMessage(
                    role: message.side == .incoming ? "assistant" : "user",
                    content: contentPrefix + "[Voice message: \(duration)]"
                )
            case let .videoNote(duration):
                return OpenRouterChatMessage(
                    role: message.side == .incoming ? "assistant" : "user",
                    content: contentPrefix + "[Video message: \(duration)]"
                )
            case let .sticker(name, emoji):
                return OpenRouterChatMessage(
                    role: message.side == .incoming ? "assistant" : "user",
                    content: contentPrefix + "[Sticker: \(emoji) \(name)]"
                )
            case let .widget(widget):
                return OpenRouterChatMessage(
                    role: message.side == .incoming ? "assistant" : "user",
                    content: contentPrefix + "[Interactive Widget: \(widget.title) - \(widget.currentStatus)]"
                )
            case let .document(name, size, ext, _):
                return OpenRouterChatMessage(
                    role: message.side == .incoming ? "assistant" : "user",
                    content: contentPrefix + "[Attached Document: \(name) (\(ext.uppercased()), \(size))]"
                )
            }
        }

        return [OpenRouterChatMessage(role: "system", content: system)] + priorMessages + [
            OpenRouterChatMessage(role: "user", content: draft)
        ]
    }
}
