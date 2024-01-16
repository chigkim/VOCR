
import Cocoa

enum Ollama:ModelAsking {
	
	struct Response: Decodable {
		let response: String
	}
	
	struct ModelsContainer: Decodable {
		struct Model: Decodable {
			struct ModelDetails: Codable {
				let families: [String]
			}
				let details: ModelDetails
			let name:String
		}
		let models:[Model]
	}


static let ollamaAPIURL = "http://127.0.0.1:11434/api/generate"
	static var model:String?
	static func setModel() {
		let url = "http://127.0.0.1:11434/api/tags"
		var request = URLRequest(url: URL(string: url)!)
		performRequest(&request, method:"GET") { data in
		do {
				let response = try JSONDecoder().decode(ModelsContainer.self, from: data)
				var models = response.models
			models = models.filter { $0.details.families.contains("clip") }
			if models.count > 1 {
				DispatchQueue.main.async {
					let alert = NSAlert()
					alert.alertStyle = .informational
					alert.messageText = "Choose a Model"
					for model in models {
						alert.addButton(withTitle: model.name)
					}
					let modalResult = alert.runModal()
					hide()
					let n = modalResult.rawValue-1000
					Ollama.model = models[n].name
				}
			} else if models.count == 1 {
				model = models[0].name
			}
			} catch {
				print("Error decoding JSON: \(error)")
			}
		}
	}

	static func ask(image:CGImage) {
		describe(image:image, system:Settings.systemPrompt, prompt:Settings.prompt) { description in
			Accessibility.speak(description)
		}
	}
	
	static func describe(image: CGImage, system: String, prompt: String, completion: @escaping (String) -> Void) {
		guard let model = model else {
			Accessibility.speakWithSynthesizer("Please choose a model for Ollama to use first.")
			return
		}
		let base64Image = imageToBase64(image: image)
		let jsonBody: [String: Any] = [
			"model": model,
			"prompt": prompt,
			"stream": false,
			"images": [base64Image]
		]
		
		let jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
		var request = URLRequest(url: URL(string: ollamaAPIURL)!)
		request.httpBody = jsonData
		performRequest(&request, name:model) { data in
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

