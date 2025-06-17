//
//  OpenAIClient.swift
//  VOCR
//
//  Created by Victor Tsaran on 6/15/25.
//  Copyright © 2025 Chi Kim. All rights reserved.
//

import Foundation
import Cocoa

struct OpenAIChatCompletionResponse: Decodable {
	let choices: [Choice]
	let usage: Usage?
}

struct Choice: Decodable {
	struct Message: Decodable {
		let role: String?
		let content: String?
	}
	let message: Message
}

struct Usage: Decodable {
	let prompt_tokens: Int?
	let completion_tokens: Int?
	let total_tokens: Int?
}

class OpenAIClient {
	
	static func describe(engine: Engines, image: CGImage, system: String, prompt: String, completion: @escaping (String) -> Void) {
		
		guard let (endpointURL, apiKey, modelName) = getEngineCredentials(for: engine) else {
			let errorMessage = "Configuration for engine '\(engine)' is not set."
			Accessibility.speakWithSynthesizer(errorMessage)
			completion("Error: \(errorMessage)")
			return
		}
		
		let base64Image = imageToBase64(image: image)
		let jsonBody: [String: Any] = [
			"model": modelName,
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
								"url": "data:image/jpeg;base64,\(base64Image)"
							]
						]
					]
				]
			],
			"max_tokens": 4096
		]
		
		guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody) else {
			completion("Error: Could not serialize request body to JSON.")
			return
		}
		
		guard let url = URL(string: endpointURL) else {
			completion("Error: Invalid endpoint URL for engine \(engine).")
			return
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		if !apiKey.isEmpty {
			request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
		}
		request.httpBody = jsonData
		
		performRequest(&request, name: modelName) { data in
			do {
				let response = try JSONDecoder().decode(OpenAIChatCompletionResponse.self, from: data)
				
				guard var content = response.choices.first?.message.content else {
					completion("Error: No content found in the response.")
					return
				}
				
				// only executes if usage stats are provided by the engine.
				if let usage = response.usage,
				   let promptTokens = usage.prompt_tokens,
				   let completionTokens = usage.completion_tokens {
										let totalTokens = usage.total_tokens ?? (promptTokens + completionTokens)
					
					content += "\n\n---"
					content += "\nPrompt tokens: \(promptTokens)"
					content += "\nCompletion tokens: \(completionTokens)"
					content += "\nTotal tokens: \(totalTokens)"
					
					//For GPT only, todo: check how Gemini calculates
					if engine == .gpt || engine == .gemini {
						let cost = Float(promptTokens) * (200.0 / 1000000.0) + Float(completionTokens) * (800.0 / 1000000.0)
						content += "\nCost: \(String(format: "%.4f", cost)) cents"
					}
				}
				
				copyToClipboard(content)
				completion(content)
				
			} catch {
				let errorMessage = "Error decoding JSON from \(engine): \(error)"
				Accessibility.speakWithSynthesizer(errorMessage)
				log(errorMessage)
				log("Failing response data: \(String(data: data, encoding: .utf8) ?? "No readable data")")
				completion("Error: Could not parse JSON from \(engine).")
			}
		}
		
	}
}

