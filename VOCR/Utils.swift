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
import PythonKit

let logger = Logger()

func chooseFolder() -> URL? {
	var url:URL?
	let openPanel = NSOpenPanel()
	openPanel.title                   = "Choose a ffolder"
	openPanel.canChooseDirectories = true
	openPanel.canChooseFiles = false
	openPanel.allowsMultipleSelection = false
	if (openPanel.runModal() == .OK) {
		let windows = NSApplication.shared.windows
		NSApplication.shared.hide(nil)
		windows[1].close()
		url =  openPanel.url
	}
	return url
}

func saveImage(_ cgimage: CGImage, _ url:URL) throws {
	let cicontext = CIContext()
	let ciimage = CIImage(cgImage: cgimage)
	try? cicontext.writePNGRepresentation(of: ciimage, to: url, format: .RGBA8, colorSpace: ciimage.colorSpace!)
}

func drawBoxes(_ cgImageInput : CGImage, boxes:[CGRect]) -> CGImage? {
	var cgImageOutput : CGImage? = nil
	if let dataProvider = cgImageInput.dataProvider {
		if let data : CFData = dataProvider.data {
			let length = CFDataGetLength(data)
			
			let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
			CFDataGetBytes(data, CFRange(location: 0, length: length), bytes)
			if let ctx = CGContext(data: bytes, width: cgImageInput.width, height: cgImageInput.height, bitsPerComponent: cgImageInput.bitsPerComponent, bytesPerRow: cgImageInput.bytesPerRow, space: cgImageInput.colorSpace!, bitmapInfo: cgImageInput.bitmapInfo.rawValue) {
				let red = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
				ctx.setFillColor(red)
				ctx.setStrokeColor(red)
				ctx.setLineWidth(10)
				debugPrint("Drawing boxes:")
				for box in boxes {
					debugPrint(box)
					ctx.stroke(box, width: 10.0)
				}
				cgImageOutput = (ctx.makeImage())
				if cgImageOutput == nil {
					print("Failed to make image from CGContext.")
				}
			} else {
				print("Could not create context. Try different image parameters.")
			}
			bytes.deallocate()
		} else {
			print("Could not get dataProvider.data")
		}
	} else {
		print ("Could not get cgImage.dataProvider")
	}
	return cgImageOutput
}

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
    
//	let rectDetectRequest = VNDetectRectanglesRequest()
//	rectDetectRequest.maximumObservations = 1000
//	rectDetectRequest.minimumConfidence = 0.0
//	rectDetectRequest.minimumAspectRatio = 0.0
//	rectDetectRequest.minimumSize = 0.0
//	rectDetectRequest.cancel()
    
	let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
	do {
//		try requestHandler.perform([textRecognitionRequest, rectDetectRequest])
        try requestHandler.perform([textRecognitionRequest])
	} catch _ {}
//	let boxes = rectDetectRequest.results!.map { VNImageRectForNormalizedRect($0.boundingBox, cgImage.width, cgImage.height) }
//	if boxes.count > 0 {
//		Accessibility.speak("\(boxes.count) boxes")
//	}
	guard let results = textRecognitionRequest.results else {
		return []
	}
//	let texts = results.map { VNImageRectForNormalizedRect($0.boundingBox, cgImage.width, cgImage.height) }
//	var boxesNoText: [CGRect] = []
//	var boxesText: [CGRect] = []
//	for box in boxes {
//		var intersectsFlag: Bool = false
//		for point in texts {
//			if box.contains(point) {
//				print("got here", box, point)
//				intersectsFlag = true
//				break
//			}
//		}
//		if !intersectsFlag {
//			boxesNoText.append(box)
//		} else {
//			boxesText.append(box)
//		}
//	}
//	print("Box Count:", boxes.count)
//	print("Text Count:", texts.count)
//	print("boxesNoText Count:", boxesNoText.count)
//	print("boxesText count:", boxesText.count)
//	var pointBoxes: [CGRect] = []
//	for point in texts {
//		// print("point: ", point)
//		pointBoxes.append(CGRect(x: point.minX-0.1, y: point.minY-0.1, width: 0.2, height: 0.2))
//	}
	
//	if let url = chooseFolder() {
//		let boxImage = drawBoxes(cgImage, boxes:boxes )!
//		try? saveImage(boxImage, url.appendingPathComponent("Boxes.png"))
//		let boxesTextImage = drawBoxes(cgImage, boxes:boxesText )!
//		try? saveImage(boxesTextImage, url.appendingPathComponent("boxes with text.png"))
//		let boxesNoTextImage = drawBoxes(cgImage, boxes:boxesNoText)!
//		try? saveImage(boxesNoTextImage, url.appendingPathComponent("boxes with no  text.png"))
//		let pointBoxesImage = drawBoxes(cgImage, boxes:pointBoxes)!
//		try? saveImage(pointBoxesImage, url.appendingPathComponent("text points.png"))
//	}
    
    PythonLibrary.useVersion(3)
    PythonLibrary.useLibrary(at: "/usr/local/bin/python3")
    
    let dirPath = (URL(fileURLWithPath: #file).deletingLastPathComponent()).path
    
    callPython(dirPath: dirPath)
    
	return results
}

func callPython(dirPath: String) {
    let sys = Python.import("sys")
    
    print("Python \(sys.version_info.major).\(sys.version_info.minor)")
    print("Python Version: \(sys.version)")
    print("Python Encoding: \(sys.getdefaultencoding().upper())")
    
    sys.path.append(dirPath)
    print("sys", sys.path)
    let function = Python.import("test2")
    print("function", function)
    let message = function.hello("Carlton")
    print(message)
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

