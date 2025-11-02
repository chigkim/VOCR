import Foundation
import Cocoa

enum OpenAIAPI {
	
	struct ModelsResponse: Decodable {
		struct Model: Decodable {
			let id: String
		}
		let data: [Model]
	}
	
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
	
	static func getModels(_ apiURL:String, _ apiKey:String, completion: @escaping ([String]) -> Void) {
		guard let url = URL(string: "\(apiURL)/models") else {
			alert("Invalid URL", apiURL)
			completion([])
			return
		}
		
		var request = URLRequest(url: url)
		request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
		
		performRequest(&request, method: "GET") { data in
			do {
				let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
				let ids = decoded.data.map { $0.id }
				completion(ids)
			} catch {
				alert("Error decoding models JSON", "\(error)")
				completion([])
			}
		}
	}
	
	static func ask(image:CGImage) {
		describe(image:image) { description in
			NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
			sleep(1)
			Accessibility.speak(description)
		}
	}
	
	static func describe(image: CGImage, completion: @escaping (String) -> Void) {
		guard let preset = Settings.activePreset() else {
			return
		}
		let apiURL = preset.url
		let apiKey = preset.apiKey		 // decrypted right now
		let modelName = preset.model
		let prompt = preset.presetPrompt
		let systemPrompt = preset.systemPrompt
		
		let base64_image = imageToBase64(image: image)
		
		let jsonBody: [String: Any] = [
			"model": modelName,
			"messages": [
				[
					"role": "system",
					"content": systemPrompt
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
		
		
		let url = URL(string: "\(apiURL)/chat/completions")!
		var request = URLRequest(url: url)
		request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
		request.httpBody = jsonData
		performRequest(&request, name:modelName) { data in
			log("\(modelName): \(String(data: data, encoding: .utf8)!)")
			do {
				let response = try JSONDecoder().decode(Response.self, from: data)
				let prompt_tokens = response.usage.prompt_tokens
				let completion_tokens = response.usage.completion_tokens
				let total_tokens = response.usage.total_tokens
				if let firstChoice = response.choices.first {
					var description = firstChoice.message.content
					description += "\nPrompt tokens: \(prompt_tokens)"
					description += "\nCompletion tokens: \(completion_tokens)"
					description += "\nTotal tokens: \(total_tokens)"
					copyToClipboard(description)
					completion(description)
				}
			} catch {
				alert("Error decoding JSON", "\(error)")
				completion("Error: Could not parse JSON.")
			}
		}
	}
}
