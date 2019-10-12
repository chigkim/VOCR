//
//  RecognizeVOCursor.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Vision
import Cocoa

func classify(url:URL) {
	var categories: [String: VNConfidence] = [:]
	let handler = VNImageRequestHandler(url: url, options: [:])
	let request = VNClassifyImageRequest()
	try? handler.perform([request])
	guard let observations = request.results as? [VNClassificationObservation] else {
		return
	}
	categories = observations
		.filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
		.reduce(into: [String: VNConfidence]()) { dict, observation in dict[observation.identifier] = observation.confidence }
	let classes = categories.sorted(by: {($0.value>$1.value)})
	print("Classes: \(classes)")
		NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
	var count = classes.count
	if count>0 {
		if count>3 {
			count = 3
		}
		var message = ""
		for c in 0..<count {
			message += "\(classes[c].key), "
		}
		Accessibility.speak(message)
		if message.contains("document") {
			ocrDocument(url:url)
		}
	} else {
		Accessibility.speak("Can't recognize")
	}
}

func recognizeVOCursor() {
	let bundle = Bundle.main
	let script = bundle.url(forResource: "VOScreenshot", withExtension: "scpt")
	debugPrint(script)
	var error:NSDictionary?
	if let scriptObject = NSAppleScript(contentsOf: script!, error: &error) {
		var outputError:NSDictionary?
		if let output = scriptObject.executeAndReturnError(&outputError).stringValue {
			print("Output: \(output)")
			let url = URL(fileURLWithPath: output)
			classify(url:url)
			let fileManager = FileManager.default
			try? fileManager.removeItem(at: url)
		} else {
			debugPrint("Output Error: \(outputError)")
		}
	} else {
		debugPrint(error)
	}
	
}


func ocrDocument(url:URL) {
	if let dataImage = try? Data(contentsOf:url) {
		let dataProvider = CGDataProvider(data: dataImage as CFData)
		if let cgImage = CGImage(pngDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
			sleep(1)
			Navigation.shared.startOCR(cgImage:cgImage)
		}
	}

}
