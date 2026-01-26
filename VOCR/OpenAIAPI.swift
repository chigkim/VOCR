import Cocoa
import Foundation

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
        _ apiURL: String, _ apiKey: String, completion: @escaping ([String]) -> Void
    ) {
        guard let base = URL(string: apiURL) else {
            alert("Invalid URL", apiURL)
            completion([])
            return
        }

        let url = base.appendingPathComponent("models")

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        performRequest(&request, method: "GET") { data in
            do {
                let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
                var ids = decoded.data.map { $0.id }
                ids.sort()
                completion(ids)
            } catch {
                alert("Error decoding models JSON", "\(error)")
                completion([])
            }
        }
    }

    static func ask(image: CGImage, system: String, prompt: String) {
        describe(image: image, system: system, prompt: prompt) { description in
            NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
            sleep(1)
            Accessibility.speak(description)
        }
    }

    static func describe(
        image: CGImage, system: String, prompt: String, completion: @escaping (String) -> Void
    ) {
        guard let preset = Settings.activePreset() else {
            return
        }
        let apiURL = preset.url
        let apiKey = preset.apiKey  // decrypted right now
        let modelName = preset.model
        let base64_image = imageToBase64(image: image)
        if !Settings.messages.isEmpty && Settings.followUp {
            let message: [String: Any] = [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": prompt,
                    ]
                ],
            ]
            Settings.messages.append(message)
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
                            "url": "data:image/jpeg;base64,\(base64_image)"
                        ],
                    ],
                ],
            ]

            Settings.messages = [
                [
                    "role": "system",
                    "content": system,
                ],
                message,
            ]
        }

        var jsonBody: [String: Any] = [
            "model": modelName,
            "messages": Settings.messages,
        ]

        if system.contains("JSON") {
            jsonBody["response_format"] = ["type": "json_object"]
        }
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])

        guard let base = URL(string: apiURL) else {
            alert("Invalid URL", apiURL)
            completion("")
            return
        }

        let url =
            base
            .appendingPathComponent("chat")
            .appendingPathComponent("completions")

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        performRequest(&request, name: modelName) { data in
            log("\(modelName): \(String(data: data, encoding: .utf8)!)")
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
                alert("Error decoding JSON", "\(error)")
                completion("Error: Could not parse JSON.")
            }
        }
    }
}
