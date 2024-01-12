//
//  LlamaCpp.swift
//  VOCR
//
//  Created by Chi Kim on 1/11/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Foundation
import Cocoa

enum LlamaCpp {
	
	struct Response: Decodable {
				let content: String
	}
	
	static func ask(image:CGImage) {
		let alert = NSAlert()
		alert.messageText = "Ask GPT-4V"
		alert.addButton(withTitle: "Ask")
		alert.addButton(withTitle: "Cancel")
		let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
		inputTextField.placeholderString = "Question"
		inputTextField.stringValue = "Analyze the image in a comprehensive and detailed manner.."
		alert.accessoryView = inputTextField
		let response = alert.runModal()
		if response == .alertFirstButtonReturn { // OK button
			let prompt = inputTextField.stringValue
			let system = "You are a helpful assistant."
			LlamaCpp.describe(image:image, system:system, prompt:prompt) { description in
				Accessibility.speak(description)
				copyToClipboard(description)
			}
		}
	}
	
	static func describe(image: CGImage, system:String, prompt: String, completion: @escaping (String) -> Void) {
		let base64_image = imageToBase64(image: image)
		let jsonBody: [String: Any] = [
			"temperature": 0.1,
			"prompt": "User: [img-1]\n\(prompt)\nAssistant:",
			"image_data": [
				[
					"data": base64_image,
					"id": 1
				]
			],
			"n_predict": 1000
		]
		let jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
		let url = URL(string: "http://127.0.0.1:8080/completion")!
		var request = URLRequest(url: url)
		request.timeoutInterval = 180
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
				let description = response.content
					completion(description)
			} catch {
				print("Error decoding JSON: \(error)")
				completion("Error: Could not parse JSON.")
			}
		}
		Accessibility.speakWithSynthesizer("Getting response from ChatGPT... Please wait...")
		task.resume()
	}
}

