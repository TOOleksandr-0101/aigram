import Foundation

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
    let provider: OpenRouterProviderOptions
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
            return "Add an OpenRouter API key in Settings -> AI Gateway."
        case .invalidResponse:
            return "OpenRouter returned an invalid response."
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
        guard configuration.apiKey.isEmpty == false else {
            throw OpenRouterServiceError.invalidKey
        }

        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw OpenRouterServiceError.invalidResponse
        }

        let requestBody = OpenRouterRequestBody(
            model: configuration.modelSlug,
            messages: makeMessages(draft: draft, thread: thread, history: history, memoryNote: memoryNote),
            temperature: 0.85,
            provider: OpenRouterProviderOptions(
                allow_fallbacks: true,
                data_collection: configuration.denyProviderLogging ? "deny" : nil,
                zdr: configuration.useZeroRetention ? true : nil
            )
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("https://codex.local/aimessenger", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("AIMessenger", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterServiceError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "OpenRouter request failed with status \(httpResponse.statusCode)."
            throw OpenRouterServiceError.serverError(message)
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponseBody.self, from: data)
        guard let content = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              content.isEmpty == false else {
            throw OpenRouterServiceError.emptyResponse
        }

        return content
    }

    private func makeMessages(
        draft: String,
        thread: ChatThread,
        history: [ConversationMessage],
        memoryNote: String
    ) -> [OpenRouterChatMessage] {
        var system = """
        \(thread.aiProfile.rolePrompt)
        You are inside an iOS messenger app where you appear as a normal chat contact.
        Keep replies natural, conversational, and message-sized by default.
        Avoid saying you are an AI unless the user directly asks.
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
            }
        }

        return [OpenRouterChatMessage(role: "system", content: system)] + priorMessages + [
            OpenRouterChatMessage(role: "user", content: draft)
        ]
    }
}
