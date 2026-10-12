import Foundation

enum DefaultPrompts {
    static var system: String {
        NSLocalizedString(
            "preset.default.systemPrompt",
            value: "You are a helpful assistant.",
            comment: "Default system prompt for new presets"
        )
    }

    static var user: String {
        NSLocalizedString(
            "preset.default.userPrompt",
            value: "Analyze the image in a comprehensive and detailed manner.",
            comment: "Default user prompt for new presets"
        )
    }
}

/// Predefined model provider configurations for quick preset creation.
struct ModelProvider {
    let name: String
    let apiURL: String

    static let predefinedProviders: [ModelProvider] = [
        ModelProvider(name: "Claude", apiURL: "https://api.anthropic.com/v1"),
        ModelProvider(
            name: "Gemini", apiURL: "https://generativelanguage.googleapis.com/v1beta/openai/"),
        ModelProvider(name: "Ollama", apiURL: "http://localhost:11434/v1"),
        ModelProvider(name: "Open AI", apiURL: "https://api.openai.com/v1"),
        ModelProvider(name: "Open Router", apiURL: "https://openrouter.ai/api/v1"),
    ]
}

/// Reasoning effort values offered by the preset editor's picker. Any value can be typed;
/// a nil preset value omits the parameter so the endpoint uses the model default.
enum ReasoningEffort {
    static let predefinedValues = [
        "none", "minimal", "low", "medium", "high", "xhigh", "max",
    ]
}

struct ActivePreset {
    let id: UUID
    let name: String
    let url: String
    let model: String
    let systemPrompt: String
    let prompt: String
    let reasoningEffort: String?
    let apiKey: String
}

/// A saved configuration describing how to talk to a model endpoint.
///
/// NOTE: The API key is NOT stored in plaintext. It's stored in
/// `encryptedKeyCombinedBase64`, which is the AES.GCM sealed box
/// (nonce + ciphertext + tag), Base64-encoded.
struct Preset: Codable, Equatable, Identifiable {
    let id: UUID

    // Display / routing
    var name: String  // User-visible label, e.g. "OpenAI GPT-4"
    var url: String  // API endpoint / base URL
    var model: String  // Model identifier on that endpoint

    // Prompts
    var systemPrompt: String  // System / role / behavior prompt
    var prompt: String  // Default user / instruction prompt

    // Request options
    var reasoningEffort: String?  // nil => model default

    // Credentials (encrypted)
    var encryptedKeyCombinedBase64: String

    init(
        id: UUID = UUID(),
        name: String,
        url: String,
        model: String,
        systemPrompt: String,
        prompt: String,
        reasoningEffort: String?,
        encryptedKeyCombinedBase64: String
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.model = model
        self.systemPrompt = systemPrompt
        self.prompt = prompt
        self.reasoningEffort = reasoningEffort
        self.encryptedKeyCombinedBase64 = encryptedKeyCombinedBase64
    }
}
