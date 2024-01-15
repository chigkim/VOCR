//
//  LlamaCpp.swift
//  VOCR
//
//  Created by Chi Kim on 1/11/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//


import Cocoa

enum LlamaCpp:ModelAsking {
	
	struct Response: Decodable {
				let content: String
	}
	
	static func ask(image:CGImage) {
			LlamaCpp.describe(image:image, system:Settings.systemPrompt, prompt:Settings.prompt) { description in
				Accessibility.speak(description)
			}
	}
	
	static func describe(image: CGImage, system:String, prompt: String, completion: @escaping (String) -> Void) {
		let base64_image = imageToBase64(image: image)
		let jsonBody: [String: Any] = [
			"temperature": 0.1,
			"prompt": "USER: [img-1]\n\(prompt)\nASSISTANT:",
			"image_data": [
				[
					"data": base64_image,
					"id": 1
				]
			],
			"n_predict": 4096
		]
		let jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
		let url = URL(string: "http://127.0.0.1:8080/completion")!
		var request = URLRequest(url: url)
		request.timeoutInterval = 600
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = jsonData
		performRequest(request, name:"Llama.Cpp") { data in
//			debugPrint("Llama: \(String(data: data, encoding: .utf8)!)")
			do {
				let response = try JSONDecoder().decode(Response.self, from: data)
				let description = response.content
				copyToClipboard(description)
				completion(description)
			} catch {
				print("Error decoding JSON: \(error)")
				completion("Error: Could not parse JSON.")
			}
		}
	}
}

