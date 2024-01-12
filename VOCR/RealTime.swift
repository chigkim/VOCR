//
//  RealTime.swift
//  VOCR
//
//  Created by Chi Kim on 1/9/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Foundation
import Vision
import Cocoa
import HotKey

struct RealTime {
	
	static var run:Bool = false
	static var exit:HotKey?
	
	static func performOCR(cgImage:CGImage) -> [VNRecognizedTextObservation]? {
		let textRecognitionRequest = VNRecognizeTextRequest()
		textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
		textRecognitionRequest.minimumTextHeight = 0
		textRecognitionRequest.usesLanguageCorrection = true
		textRecognitionRequest.customWords = []
		textRecognitionRequest.usesCPUOnly = false
		textRecognitionRequest.cancel()
		let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
		do {
			try requestHandler.perform([textRecognitionRequest])
		} catch _ {}
		guard let texts = textRecognitionRequest.results else {
			return []
		}
		return texts
	}

	static func diff(old:String, new:String) -> String? {
		let oldArray  = old.lowercased().components(separatedBy: .whitespaces)
		let newArray = new.lowercased().components(separatedBy: .whitespaces)
		let difference = newArray.difference(from: oldArray)
		let insertedTexts = difference.compactMap {
			if case .insert(_, let element, _) = $0 {
				return element
			} else { return nil }
		}

		if insertedTexts.isNotEmpty {
			return insertedTexts.joined(separator: " ")
		}
return nil
	}

	static func continuousOCR() {
		DispatchQueue.global(qos: .background).async {
			if let rect = voCursorLocation() {
				Accessibility.speakWithSynthesizer("Press escape to stop Realtime OCR.")
				exit = HotKey(key:.escape, modifiers:[])
				exit?.keyDownHandler = {
					Accessibility.speak("Exit Realtime OCR navigation.")
					RealTime.run = false
					RealTime.exit = nil
				}
				var oldText = ""
				run = true
				while run {
					if let cgImage = TakeScreensShots(rect: rect, resize:false) {
						if let texts = performOCR(cgImage:cgImage) {
							let newText = texts.map { $0.topCandidates(1)[0].string }.joined(separator: " ")
							if let insertedText = diff(old:oldText, new:newText) {
								oldText = newText
								debugPrint("New:", insertedText)
								Accessibility.speak(insertedText)
							}
						}
					}
					Thread.sleep(forTimeInterval: 0.5)
					// NSSound(contentsOfFile: "/System/Library/Sounds/Tink.aiff", byReference: true)?.play()
				}
			}
		}
	}
	
}
