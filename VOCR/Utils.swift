//
//  Utils.swift
//  VOCR
//
//  Created by Chi Kim on 10/2/22.
//  Copyright © 2022 Chi Kim. All rights reserved.
//

import Foundation
import os
import Vision
import AVFoundation
import Cocoa

let logger = Logger()

func TakeScreensShots() -> CGImage? {
	var displayCount: UInt32 = 0
	var result = CGGetActiveDisplayList(0, nil, &displayCount)
	if (result != CGError.success) {
		print("error: \(result)")
		return nil
	}
	let allocated = Int(displayCount)
	let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
	result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
	
	if (result != CGError.success) {
		print("error: \(result)")
		return nil
	}
	
	let currentApp = NSWorkspace.shared.frontmostApplication
	//	let appID = currentApp!.processIdentifier
	//	let appElement = AXUIElementCreateApplication(appID)
	let windows = currentApp?.windows()
	if (windows!.isEmpty) {
		return nil
	}
	let window = windows![0]
	print("Window information")
	print(window.value(of: "AXTitle"))
	var position:CFTypeRef?
	var size:CFTypeRef?
	var cgPosition = CGPoint()
	var cgSize = CGSize()
	AXUIElementCopyAttributeValue(window, "AXPosition" as CFString, &position)
	AXUIElementCopyAttributeValue(window, "AXSize" as CFString, &size)
	AXValueGetValue(position as! AXValue, AXValueType.cgPoint, &cgPosition)
	AXValueGetValue(size as! AXValue, AXValueType.cgSize, &cgSize)
	Navigation.shared.cgSize = cgSize
	Navigation.shared.cgPosition = cgPosition
	print("\(cgPosition), \(cgSize)")
	return CGDisplayCreateImage(activeDisplays[0], rect:CGRect(origin: cgPosition, size: cgSize))
}

func performOCR(cgImage:CGImage) -> [VNRecognizedTextObservation] {
	let textRecognitionRequest = VNRecognizeTextRequest()
	textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
	textRecognitionRequest.minimumTextHeight = 0
	textRecognitionRequest.usesLanguageCorrection = true
	textRecognitionRequest.customWords = []
	textRecognitionRequest.usesCPUOnly = false
	textRecognitionRequest.cancel()
	let rectDetectRequest = VNDetectRectanglesRequest()
	rectDetectRequest.maximumObservations = 16
	rectDetectRequest.minimumConfidence = 0.6
	rectDetectRequest.minimumAspectRatio = 0.3
	rectDetectRequest.cancel()
	let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
	do {
		try requestHandler.perform([textRecognitionRequest, rectDetectRequest])
	} catch _ {}
	for r in rectDetectRequest.results! {
		let tl = Navigation.shared.convertPoint(r.topLeft)
		let tr = Navigation.shared.convertPoint(r.topRight)
		let bl = Navigation.shared.convertPoint(r.bottomLeft)
		let br = Navigation.shared.convertPoint(r.bottomRight)
		let box = CGRect(x: tl.x, y: tl.y, width: br.x-bl.x, height: br.y-tr.y)
		debugPrint("Box: \(box)")
	}
    
    let VNDetectRectanglesRequest = VNImageBasedRequest()
    print("VND Detect Rectangles results")
    let VNDresults = VNDetectRectanglesRequest.results
    print(VNDresults ?? "no results")
    
	guard let results = textRecognitionRequest.results else {
		return []
	}
    print("results")
    print(results)
	return results
    
//    let textRecognitionRequest = VNRecognizeTextRequest()
//    textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
//    textRecognitionRequest.minimumTextHeight = 0
//    textRecognitionRequest.usesLanguageCorrection = true
//    textRecognitionRequest.customWords = []
//    textRecognitionRequest.usesCPUOnly = false
//    textRecognitionRequest.cancel()
//    
//    
//    
////    let ciImageInput = CIImage(cgImage: cgImage)
////    let requestHandler = VNImageRequestHandler(ciImage: ciImageInput)
////    let documentDetectionRequest = VNDetectDocumentSegmentationRequest()
////    do {
////        try requestHandler.perform([documentDetectionRequest])
////    } catch _ {}
////
//    
////    let documentRequestHandler = VNImageRequestHandler(ciImage: ciImageInput)
////
////    var checkBoxImages: [VNRectangleObservation] = []
////    var rectangles: [VNRectangleObservation] = []
////
////    let rectanglesDetection = VNDetectRectanglesRequest { request, error in
////        rectangles = request.results as! [VNRectangleObservation]
////        rectangles.sort{$0.boundingBox.origin.y > $1.boundingBox.origin.y}
////
////        for rectangle in rectangles {
////            //            guard let checkBoxImage =
////            checkBoxImages.append(rectangle)
////        }
////    }
////
////    do {
////        try documentRequestHandler.perform([rectanglesDetection])
////    } catch {
////        print(error)
////    }
//    
////    print("checkbox")
////    print(checkBoxImages)
//    
//    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//    
//    do {
//        try requestHandler.perform([textRecognitionRequest])
//    } catch _ {}
//    
////    do {
////        try requestHandler.perform([rectanglesDetection])
////    } catch _ {}
//    
//    
//    for r in rectanglesDetectionRequest.results! {
//        let tl = Navigation.shared.convertPoint(r.topLeft)
//        let tr = Navigation.shared.convertPoint(r.topRight)
//        let bl = Navigation.shared.convertPoint(r.bottomLeft)
//        let br = Navigation.shared.convertPoint(r.bottomRight)
//        let box = CGRect(x: tl.x, y: tl.y, width: br.x-bl.x, height: br.y-tr.y)
//        debugPrint("Box: \(box)")
////    }
//    
//    let VNDetectRectanglesRequest = VNImageBasedRequest()
//    print("VND Detect Rectangles results")
//    let VNDresults = VNDetectRectanglesRequest.results
//    print(VNDresults ?? "no results")
//    
//    guard let results = textRecognitionRequest.results else {
//        return []
//    }
//    print("results")
//    print(results)
//    return results
}

func classify(cgImage:CGImage) -> String {
	var message = ""
	var categories: [String: VNConfidence] = [:]
	let handler = VNImageRequestHandler(cgImage:cgImage, options: [:])
	let request = VNClassifyImageRequest()
	try? handler.perform([request])
	guard let observations = request.results else {
		return message
	}
	categories = observations
		.filter { $0.hasMinimumRecall(0.1, forPrecision: 0.9) }
		.reduce(into: [String: VNConfidence]()) { dict, observation in dict[observation.identifier] = observation.confidence }
	let classes = categories.sorted(by: {($0.value>$1.value)})
	print("Classes: \(classes)")
	var count = classes.count
	if count>0 {
		if count>5 {
			count = 5
		}
		
		for c in 0..<count {
			message += "\(classes[c].key), "
		}
		Accessibility.speak(message)
		if message.contains("document") {
			Navigation.shared.startOCR(cgImage:cgImage)
			message += "\n"+Navigation.shared.text()
		}
	} else {
		Accessibility.speak("Unknown")
	}
	return message
}

func recognizeVOCursor() {
	let bundle = Bundle.main
	let script = bundle.url(forResource: "VOScreenshot", withExtension: "scpt")
	debugPrint(script!)
	var error:NSDictionary?
	if let scriptObject = NSAppleScript(contentsOf: script!, error: &error) {
		var outputError:NSDictionary?
		if let output = scriptObject.executeAndReturnError(&outputError).stringValue {
			print("Output: \(output)")
			let url = URL(fileURLWithPath: output)
			if let dataImage = try? Data(contentsOf:url) {
				let dataProvider = CGDataProvider(data: dataImage as CFData)
				if let cgImage = CGImage(pngDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
					classify(cgImage:cgImage)
				}
			}
			let fileManager = FileManager.default
			try? fileManager.removeItem(at: url)
		} else {
			debugPrint("Output Error: \(String(describing: outputError))")
		}
	} else {
		debugPrint(String(describing: error))
	}
	
}

