// In Ollama.swift

import Foundation
import Cocoa

class Ollama {

	private struct OllamaTagResponse: Decodable {
		struct Model: Decodable {
			struct ModelDetails: Codable {
				let families: [String]?
			}
			let details: ModelDetails
			let name: String
		}
		let models: [Model]
	}

	static func selectModel(completion: @escaping (String?) -> Void) {
		guard let url = URL(string: "http://127.0.0.1:11434/api/tags") else {
			completion(nil)
			return
		}
		var request = URLRequest(url: url)
		request.httpMethod = "GET"

		URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				Accessibility.speakWithSynthesizer("Could not connect to Ollama server.")
				completion(nil)
				return
			}
			
			do {
				var models = try JSONDecoder().decode(OllamaTagResponse.self, from: data).models
				// Filter for compatible vision models
				models = models.filter {
					if let families = $0.details.families, (families.contains("clip") || families.contains("mllama") || families.contains("gemma3")) {
						return true
					} else {
						return false
					}
				}

				if models.isEmpty {
					Accessibility.speakWithSynthesizer("No compatible vision models found on the Ollama server.")
					completion(nil)
					return
				}

				DispatchQueue.main.async {
					let alert = NSAlert()
					alert.alertStyle = .informational
					alert.messageText = "Choose an Ollama Vision Model"
					for model in models {
						alert.addButton(withTitle: model.name)
					}
					alert.addButton(withTitle: "Cancel")
					
					let modalResult = alert.runModal()
					
					if modalResult.rawValue < 1000 + models.count { // A model button was clicked
						let selectedModelName = models[modalResult.rawValue - 1000].name
						completion(selectedModelName)
					} else { // Cancel was clicked
						completion(nil)
					}
				}
			} catch {
				Accessibility.speakWithSynthesizer("Error parsing model list from Ollama.")
				log("Error decoding Ollama tags JSON: \(error)")
				completion(nil)
			}
		}.resume()
	}
}
