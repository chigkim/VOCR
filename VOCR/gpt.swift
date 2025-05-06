import Foundation
import Cocoa

enum GPT:EngineAsking {

	struct Response: Decodable {
		struct Usage:Decodable {
			let prompt_tokens:Int
			let completion_tokens:Int
			let total_tokens:Int
		}

		struct Choice: Decodable {
			struct Message: Decodable {
				let content: String
			}
			
			let message: Message
		}
		let usage:Usage
		let choices: [Choice]
	}
	
	static func ask(image:CGImage) {
		GPT.describe(image:image, system:Settings.systemPrompt, prompt:Settings.prompt) { description in
				Accessibility.speak(description)
			}
	}

	static func describe(image: CGImage, system:String, prompt:String, completion: @escaping (String) -> Void) {
		if Settings.GPTAPIKEY == "" {
				Settings.displayApiKeyDialog()
		}
		if Settings.GPTAPIKEY == "" {
			return
		}
		let base64_image = imageToBase64(image: image)
		
		let jsonBody: [String: Any] = [
			"model": "gpt-4.1",
			"messages": [
				[
					"role": "system",
					"content": system
				],
				[
					"role": "user",
					"content": [
						[
							"type": "text",
							"text": prompt
						],
						[
							"type": "image_url",
							"image_url": [
								"url": "data:image/jpeg;base64,\(base64_image)"
							]
						]
					]
				]
			],
			"max_tokens": 4096
		]
		
		let jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
		
		
		let url = URL(string: "https://api.openai.com/v1/chat/completions")!
		var request = URLRequest(url: url)
		request.setValue("Bearer \(Settings.GPTAPIKEY)", forHTTPHeaderField: "Authorization")
		request.httpBody = jsonData
		performRequest(&request, name:"GPT") { data in
			log("GPT-4V: \(String(data: data, encoding: .utf8)!)")
			do {
				let response = try JSONDecoder().decode(Response.self, from: data)
				let prompt_tokens = response.usage.prompt_tokens
				let completion_tokens = response.usage.completion_tokens
				let total_tokens = response.usage.total_tokens
				let cost = Float(prompt_tokens)*(200.0/1000000.0)+Float(completion_tokens)*(800.0/1000000.0)
				if let firstChoice = response.choices.first {
					var description = firstChoice.message.content
					description += "\nPrompt tokens: \(prompt_tokens)"
					description += "\nCompletion tokens: \(completion_tokens)"
					description += "\nTotal tokens: \(total_tokens)"
					description += "\nCost: \(cost) cents"
					copyToClipboard(description)
					completion(description)
				}
			} catch {
				Accessibility.speakWithSynthesizer("Error decoding JSON: \(error)")
				completion("Error: Could not parse JSON.")
			}
		}
	}
}

