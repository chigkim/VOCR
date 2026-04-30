import Cocoa
import Foundation

enum NetworkError: Error {
    case invalidURL
    case connectionError(Error)
    case invalidResponse
    case httpError(Int, String)
    case noData
}

enum HTTPClient {
    private static var currentTask: URLSessionDataTask?

    static func request(
        url: URL,
        method: String = "POST",
        apiKey: String? = nil,
        body: Data? = nil,
        timeout: TimeInterval = 600,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        currentTask?.cancel()
        currentTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if (error as NSError).code != NSURLErrorCancelled {
                    completion(.failure(.connectionError(error)))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            guard let data else {
                completion(.failure(.noData))
                return
            }

            guard httpResponse.statusCode == 200 else {
                let details = String(data: data, encoding: .utf8) ?? ""
                completion(.failure(.httpError(httpResponse.statusCode, details)))
                return
            }

            log(String(data: data, encoding: .utf8) ?? "")
            completion(.success(data))
        }
        currentTask?.resume()
    }
}

enum OpenAIAPI {

    struct ModelsResponse: Decodable {
        struct Model: Decodable {
            let id: String
        }
        let data: [Model]
    }

    struct Response: Decodable {
        struct Usage: Decodable {
            let prompt_tokens: Int
            let completion_tokens: Int
            let total_tokens: Int
        }

        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }

            let message: Message
        }
        let usage: Usage
        let choices: [Choice]
    }

    static func getModels(
        _ apiURL: String, _ apiKey: String, completion: @escaping (Result<[String], Error>) -> Void
    ) {
        guard let base = URL(string: apiURL) else {
            alert(
                NSLocalizedString(
                    "error.invalid_url", value: "Invalid URL",
                    comment: "Error message for invalid URL"), apiURL)
            completion(.failure(NetworkError.invalidURL))
            return
        }

        HTTPClient.request(
            url: base.appendingPathComponent("models"),
            method: "GET",
            apiKey: apiKey,
            timeout: 60
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
                    var ids = decoded.data.map { $0.id }
                    ids.sort()
                    completion(.success(ids))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func ask(image: CGImage, system: String, prompt: String) {
        describe(image: image, system: system, prompt: prompt, followUp: false) { description in
            NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
            sleep(1)
            Accessibility.speak(description)
        }
    }

    static func describe(
        image: CGImage,
        system: String,
        prompt: String,
        followUp: Bool,
        completion: @escaping (String) -> Void
    ) {
        guard let preset = PresetManager.shared.activePreset() else {
            return
        }
        guard let base64Image = ScreenCapture.base64(image, type: .jpeg) else {
            completion("")
            return
        }
        if !AIConversationSession.shared.messages.isEmpty && followUp {
            let message: [String: Any] = [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": prompt,
                    ]
                ],
            ]
            AIConversationSession.shared.messages.append(message)
        } else {
            let message: [String: Any] = [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": prompt,
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ],
                    ],
                ],
            ]

            AIConversationSession.shared.messages = [
                [
                    "role": "system",
                    "content": system,
                ],
                message,
            ]
        }

        var jsonBody: [String: Any] = [
            "model": preset.model,
            "messages": AIConversationSession.shared.messages,
        ]

        if system.contains("JSON") {
            jsonBody["response_format"] = [
                "type": "json_schema",
                "json_schema": Settings.exploreResponseSchema,
            ]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody, options: []) else {
            completion("")
            return
        }

        guard let base = URL(string: preset.url) else {
            alert(
                NSLocalizedString(
                    "error.invalid_url", value: "Invalid URL",
                    comment: "Error message for invalid URL"), preset.url)
            completion("")
            return
        }

        Accessibility.speakWithSynthesizer(
            String(
                format: NSLocalizedString(
                    "dialog.asking.message", value: "Asking %@... Please wait...",
                    comment: "Speech message when making a request to an AI service"),
                preset.model))

        HTTPClient.request(
            url: chatCompletionsURL(base),
            apiKey: preset.apiKey,
            body: jsonData
        ) { result in
            switch result {
            case .failure(let error):
                showNetworkError(error)
                completion("")
            case .success(let data):
                handleDescriptionResponse(data, modelName: preset.model, completion: completion)
            }
        }
    }

    private static func handleDescriptionResponse(
        _ data: Data,
        modelName: String,
        completion: @escaping (String) -> Void
    ) {
        log("\(modelName): \(String(data: data, encoding: .utf8) ?? "")")
        do {
            let response = try JSONDecoder().decode(Response.self, from: data)
            let prompt_tokens = response.usage.prompt_tokens
            let completion_tokens = response.usage.completion_tokens
            let total_tokens = response.usage.total_tokens
            if let firstChoice = response.choices.first {
                let description = firstChoice.message.content
                var usage = "Prompt tokens: \(prompt_tokens)"
                usage += "\nCompletion tokens: \(completion_tokens)"
                usage += "\nTotal tokens: \(total_tokens)"
                copyToClipboard("\(description)\n\(usage)")
                completion(description)
            }
        } catch {
            alert(
                NSLocalizedString(
                    "error.decoding_json", value: "Error decoding JSON",
                    comment: "Error message when JSON decoding fails"), "\(error)")
            completion(
                NSLocalizedString(
                    "error.parse_json", value: "Error: Could not parse JSON.",
                    comment: "Error message when JSON cannot be parsed"))
        }
    }

    private static func showNetworkError(_ error: NetworkError) {
        switch error {
        case .connectionError(let underlying):
            alert(
                NSLocalizedString(
                    "error.connection.title", value: "Connection error",
                    comment: "Alert title for connection errors"),
                underlying.localizedDescription)
        case .invalidResponse:
            alert(
                NSLocalizedString(
                    "error.response.invalid.title", value: "Invalid response from server",
                    comment: "Alert title for invalid server response"),
                NSLocalizedString(
                    "error.response.invalid.message", value: "No valid HTTP response object",
                    comment: "Alert message when no valid HTTP response is received"))
        case .httpError(let statusCode, let details):
            alert(
                NSLocalizedString(
                    "error.http.title", value: "HTTP Error", comment: "Alert title for HTTP errors"),
                String(
                    format: NSLocalizedString(
                        "error.http.message", value: "Status code %d: %@",
                        comment: "Alert message for HTTP error with status code and details"),
                    statusCode, details))
        case .noData:
            Accessibility.speakWithSynthesizer(
                NSLocalizedString(
                    "error.nodata.message", value: "No data received from server.",
                    comment: "Speech message when no data is received from server"))
        case .invalidURL:
            alert(
                NSLocalizedString(
                    "error.invalid_url", value: "Invalid URL",
                    comment: "Error message for invalid URL"), "")
        }
    }

    private static func chatCompletionsURL(_ base: URL) -> URL {
        let path = base.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path.hasSuffix("chat/completions") {
            return base
        }
        if path.hasSuffix("chat") {
            return base.appendingPathComponent("completions")
        }
        return base.appendingPathComponent("chat").appendingPathComponent("completions")
    }
}

final class AIConversationSession {
    static let shared = AIConversationSession()

    var messages: [[String: Any]] = []

    private init() {}
}
