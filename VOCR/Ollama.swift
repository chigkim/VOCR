
import Cocoa

enum Ollama:ModelAsking {

	struct Response: Decodable {
		let response: String
	}
	
	static let ollamaAPIURL = "http://127.0.0.1:11434/api/generate"
	
	
	static func ask(image:CGImage) {
		describe(image:image, system:Settings.systemPrompt, prompt:Settings.prompt) { description in
			Accessibility.speak(description)
		}
	}
	
	static func describe(image: CGImage, system: String, prompt: String, completion: @escaping (String) -> Void) {
		let base64Image = imageToBase64(image: image)
		let jsonBody: [String: Any] = [
			"model": "llava",
			"prompt": prompt,
			"stream": false,
			"images": [base64Image]
		]
		
		let jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
		var request = URLRequest(url: URL(string: ollamaAPIURL)!)
		request.httpBody = jsonData
		performRequest(&request, name:"Ollama") { data in
			do {
				let response = try JSONDecoder().decode(Response.self, from: data)
				let description = response.response
				copyToClipboard(description)
				completion(description)
			} catch {
				print("Error decoding JSON: \(error)")
				completion("Error: Could not parse JSON.")
			}
		}
	}

}

