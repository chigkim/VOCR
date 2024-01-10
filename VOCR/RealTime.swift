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
	func calculateDiff(_ old: [String], _ new: [String]) -> [String] {
		let lcs = longestCommonSubsequence(old, new)
		var result = [String]()
		var i = 0, j = 0
		
		while i < old.count || j < new.count {
			if i < old.count && j < new.count && old[i] == new[j] {
				// No change
				i += 1
				j += 1
			} else {
				if i < old.count && !lcs.contains(old[i]) {
					result.append("Deleted '\(old[i])'")
					i += 1
				}
				
				if j < new.count && !lcs.contains(new[j]) {
					result.append("Inserted '\(new[j])'")
					j += 1
				}
			}
		}
		
		return result
	}
	
	func longestCommonSubsequence(_ a: [String], _ b: [String]) -> [String] {
		var lengths = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
		
		for (i, aElement) in a.enumerated() {
			for (j, bElement) in b.enumerated() {
				if aElement == bElement {
					lengths[i + 1][j + 1] = lengths[i][j] + 1
				} else {
					lengths[i + 1][j + 1] = max(lengths[i + 1][j], lengths[i][j + 1])
				}
			}
		}
		
		return backtrackLCS(from: lengths, a: a, b: b)
	}
	
	func backtrackLCS(from lengths: [[Int]], a: [String], b: [String]) -> [String] {
		var i = a.count
		var j = b.count
		var lcs = [String]()
		
		while i > 0 && j > 0 {
			if a[i - 1] == b[j - 1] {
				lcs.insert(a[i - 1], at: 0)
				i -= 1
				j -= 1
			} else if lengths[i - 1][j] > lengths[i][j - 1] {
				i -= 1
			} else {
				j -= 1
			}
		}
		
		return lcs
	}

	static func diff(old:String, new:String) -> String? {
		let oldArray  = old.lowercased().components(separatedBy: " ")
		let newArray = new.lowercased().components(separatedBy: " ")
		let difference = newArray.difference(from: oldArray)
		let insertedTexts = difference.compactMap { change -> String? in
			switch change {
			case .insert(_, let element, _):
				return element
			default:
				return nil
			}
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
							let newTexts = texts.map { $0.topCandidates(1)[0].string.trimmingCharacters(in: .whitespaces) }
							let newText = newTexts.joined(separator: " ")
							if let insertedText = diff(old:oldText, new:newText) {
								oldText = newText
								debugPrint("New:", insertedText)
								Accessibility.speak(insertedText)
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
