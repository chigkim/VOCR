//
//  Gemini.swift
//  VOCR
//
//  Created by Victor Tsaran on 5/25/25.
//  Copyright © 2025 Chi Kim. All rights reserved.
//


import Foundation
import Cocoa

enum Gemini:EngineAsking {

    struct Response: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                }
                let parts: [Part]
            }
            let content: Content
        }
        let candidates: [Candidate]?
        // Todo: Add usage/token information, similar to GPT's Response
    }

    static func ask(image:CGImage) {
        Gemini.describe(image:image, system:Settings.systemPrompt, prompt:Settings.prompt) { description in
            NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
            sleep(1)
            Accessibility.speak(description)
        }
    }

    static func describe(image: CGImage, system:String, prompt:String, completion: @escaping (String) -> Void) {
        if Settings.GeminiAPIKEY == "" {
            Settings.displayGeminiApiKeyDialog()
        }
        if Settings.GeminiAPIKEY == "" {
            Accessibility.speakWithSynthesizer("Gemini API Key is not set.")
            completion("Error: Gemini API Key is not set.")
            return
        }
        let base64_image = imageToBase64(image: image)

        let jsonBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": system],
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64_image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 4096,
                "temperature": 0.4, // Adjust as needed
            ]
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(Settings.GeminiAPIKEY)"
        guard let url = URL(string: urlString) else {
            Accessibility.speakWithSynthesizer("Invalid Gemini API URL.")
            completion("Error: Invalid Gemini API URL.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        performRequest(&request, name:"Gemini") { data in
            log("Description: Gemini: \(String(data: data, encoding: .utf8)!)")
            do {
                let response = try JSONDecoder().decode(Response.self, from: data)
                if let firstCandidate = response.candidates?.first,
                   let firstPart = firstCandidate.content.parts.first(where: { $0.text != nil }),
                   let description = firstPart.text {
                    // Todo: Add token/cost calculation
                    copyToClipboard(description)
                    completion(description)
                } else {
                    let errorResponse = String(data: data, encoding: .utf8) ?? "No content found and could not decode error."
                    log("Description: Gemini Error Response: \(errorResponse)")
                    if errorResponse.lowercased().contains("api key not valid") {
                         Accessibility.speakWithSynthesizer("Gemini API key is not valid. Please check your API key in the settings.")
                         completion("Error: Gemini API key not valid.")
                    } else {
                        Accessibility.speakWithSynthesizer("No content found in Gemini response or error parsing parts.")
                        completion("Error: No content found in Gemini response or error parsing parts. Raw: \(errorResponse)")
                    }
                }
            } catch {
                Accessibility.speakWithSynthesizer("Error decoding Gemini JSON: \(error)")
                let rawResponse = String(data: data, encoding: .utf8) ?? "No raw response available"
                log("Description: Raw Gemini error response: \(rawResponse)")
                completion("Error: Could not parse Gemini JSON. \(error). Raw: \(rawResponse)")
            }
        }
    }
}
