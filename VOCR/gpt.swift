import Foundation
import Cocoa

enum GPT {

	struct Response: Decodable {
		struct Choice: Decodable {
			struct Message: Decodable {
				let content: String
			}
			
			let message: Message
		}
		let choices: [Choice]
	}
	
	
	static func describe(image: CGImage, system:String, prompt: String, completion: @escaping (String) -> Void) {
		if Settings.GPTAPIKEY == "" {
			if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
				appDelegate.presentApiKeyInputDialog(nil)
			}
		}
		if Settings.GPTAPIKEY == "" {
			return
		}
			let bitmapRep = NSBitmapImageRep(cgImage: image)
		guard let imageData = bitmapRep.representation(using: .jpeg, properties: [:]) else {
			fatalError("Could not convert image to JPEG.")
			return
			return
		}
		
		let base64_image = imageData.base64EncodedString(options: [])
		
		let jsonBody: [String: Any] = [
			"model": "gpt-4-vision-preview",
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
			"max_tokens": 1000
		]
		
		let jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
		
		
		let url = URL(string: "https://api.openai.com/v1/chat/completions")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(Settings.GPTAPIKEY)", forHTTPHeaderField: "Authorization")
		request.httpBody = jsonData
		let session = URLSession.shared
		let task = session.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				print("Request failed with error: \(error?.localizedDescription ?? "No data")")
				completion("Error: \(error?.localizedDescription ?? "No data")")
				return
			}
			do {
				let response = try JSONDecoder().decode(Response.self, from: data)
				if let firstChoice = response.choices.first {
					let description = firstChoice.message.content
					print("GPT-4V: \(description)")
					completion(description)
				}
			} catch {
				print("Error decoding JSON: \(error)")
				completion("Error: Could not parse JSON.")
			}
			
			
		}
		Accessibility.speakWithSynthesizer("Getting response from ChatGPT... Please wait...")
		task.resume()
	}
}

