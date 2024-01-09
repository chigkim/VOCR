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
				var oldTexts:[String] = []
				run = true
				while run {
					if let cgImage = TakeScreensShots(rect: rect, resize:false) {
						if let texts = performOCR(cgImage:cgImage) {
							let newTexts = texts.map { $0.topCandidates(1)[0].string }.joined(separator: " ").components(separatedBy: " ")
							let difference = newTexts.difference(from: oldTexts)
							let insertedTexts = difference.compactMap { change -> String? in
								switch change {
								case .insert(_, let element, _):
									return element
								default:
									return nil
								}
							}
							if insertedTexts.isNotEmpty {
								oldTexts = newTexts
								debugPrint("New:", insertedTexts)
								Accessibility.speak(insertedTexts.joined(separator:" "))
							}
							}
					}
					Thread.sleep(forTimeInterval: 1.0)
					// NSSound(contentsOfFile: "/System/Library/Sounds/Tink.aiff", byReference: true)?.play()
				}
			}
		}
	}
	
}
