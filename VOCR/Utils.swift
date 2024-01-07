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
import AXSwift

let logger = Logger()
import Cocoa

func copyToClipboard(_ string: String) {
	let pasteboard = NSPasteboard.general
	pasteboard.clearContents()
	pasteboard.setString(string, forType: .string)
}

func extractString(text: String, startDelimiter: String, endDelimiter: String) -> String? {
	guard let startRange = text.range(of: startDelimiter) else {
		return nil // No start delimiter found
	}
	
	// Define the search start for the next delimiter to be right after the first delimiter
	let searchStartIndex = startRange.upperBound
	
	// Find the range of the next delimiter after the first delimiter
	guard let endRange = text.range(of: endDelimiter, range: searchStartIndex..<text.endIndex) else {
		return nil // No end delimiter found
	}
	
	// Extract the substring between the delimiters
	let startIndex = startRange.upperBound
	let endIndex = endRange.lowerBound
	return String(text[startIndex..<endIndex])
}


func saveImage(_ cgImage: CGImage) throws {
	let savePanel = NSSavePanel()
	savePanel.title = "Save Your File"
	savePanel.message = "Choose a destination and save your file."
	savePanel.allowedContentTypes = [.png]
	savePanel.nameFieldStringValue = Navigation.shared.appName+".png"
	savePanel.begin { response in
		if response == .OK {
			if let selectedURL = savePanel.url {
				let cicontext = CIContext()
				let ciimage = CIImage(cgImage: cgImage)
				try? cicontext.writePNGRepresentation(of: ciimage, to: selectedURL, format: .RGBA8, colorSpace: ciimage.colorSpace!)
			}
		}
		let windows = NSApplication.shared.windows
		NSApplication.shared.hide(nil)
		windows[1].close()
	}
}

func drawBoxes(_ cgImageInput : CGImage, boxes:[Observation], color:NSColor) -> CGImage? {
	var cgImageOutput : CGImage? = nil
	if let dataProvider = cgImageInput.dataProvider {
		if let data : CFData = dataProvider.data {
			let length = CFDataGetLength(data)
			
			let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
			CFDataGetBytes(data, CFRange(location: 0, length: length), bytes)
			if let ctx = CGContext(data: bytes, width: cgImageInput.width, height: cgImageInput.height, bitsPerComponent: cgImageInput.bitsPerComponent, bytesPerRow: cgImageInput.bytesPerRow, space: cgImageInput.colorSpace!, bitmapInfo: cgImageInput.bitmapInfo.rawValue) {
				ctx.setFillColor(color.cgColor)
				ctx.setStrokeColor(color.cgColor)
				ctx.setLineWidth(10)
				debugPrint("Drawing boxes:")
				let rects = boxes.map { VNImageRectForNormalizedRect($0.boundingBox, cgImageInput.width, cgImageInput.height) }
				for box in rects {
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

func report(_ element:UIElement?) {
	print("\(element!.label!)")
	for atr in try! element!.attributesAsStrings() {
		print(atr)
		do {
			if let value:AnyObject = try element!.attribute(atr) {
				var valueStr = ""
				if atr == "AXChildren", let children = value as? [AXUIElement] {
					for child in children {
						valueStr += "\(UIElement(child).label!)"
					}
				} else {
					valueStr = "\(value)"
				}
				let text = "\(atr): \(valueStr)"
				print(text)
			}
		} catch let error {
			print(error)
		}
	}
}

func setWindow(_ n:Int) {
	Navigation.shared.windowName = "Unknown Window"
	Navigation.shared.appName = "Unknown App"
	var cgPosition = CGPoint()
	var cgSize = CGSize()
	Navigation.shared.cgSize = cgSize
	Navigation.shared.cgPosition = cgPosition
	let currentApp = NSWorkspace.shared.frontmostApplication
	Navigation.shared.appName = currentApp!.localizedName!
	let windows = currentApp?.windows()
	
	/*
	 // filter main window.
	 windows = windows!.filter {
	 var ref:CFTypeRef?
	 AXUIElementCopyAttributeValue($0, "AXMain" as CFString, &ref)
	 if let value = ref as? Int, value == 1 {
	 return true
	 }
	 return false
	 }
	 */
	
	if (windows!.isEmpty) {
		return
	}
	var window = windows![0]
	
	if (n == -1) {
		let alert = NSAlert()
		alert.alertStyle = .informational
		alert.messageText = "Target Window"
		alert.informativeText = "Choose an window to scan."
		for window in windows! {
			var title = window.value(of: "AXTitle")
			if (title == "") {
				title = "Untitled"
			}
			title += String(window.hashValue)
			alert.addButton(withTitle: title)
		}
		let modalResult = alert.runModal()
		NSApplication.shared.hide(NSApplication.shared)
		let r = modalResult.rawValue-1000
		window = windows![r]
	}
	
	print("Window information")
	// report(UIElement(window))
	Navigation.shared.windowName = window.value(of: "AXTitle")
	var position:CFTypeRef?
	var size:CFTypeRef?
	AXUIElementCopyAttributeValue(window, "AXPosition" as CFString, &position)
	AXUIElementCopyAttributeValue(window, "AXSize" as CFString, &size)
	
	if position != nil && size != nil {
		AXValueGetValue(position as! AXValue, AXValueType.cgPoint, &cgPosition)
		AXValueGetValue(size as! AXValue, AXValueType.cgSize, &cgSize)
		print("\(cgPosition), \(cgSize)")
	} else {
		print("Failed to get position or size")
	}
	Navigation.shared.cgSize = cgSize
	Navigation.shared.cgPosition = cgPosition
	
}

func resizeCGImage(_ cgImage: CGImage, toWidth width: Int, toHeight height: Int) -> CGImage? {
	let context = CGContext(data: nil,
							width: width,
							height: height,
							bitsPerComponent: cgImage.bitsPerComponent,
							bytesPerRow: 0, // letting Core Graphics determine the row bytes
							space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
							bitmapInfo: cgImage.bitmapInfo.rawValue)
	
	context?.interpolationQuality = .high
	context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
	
	return context?.makeImage()
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
	if let cgImage = CGDisplayCreateImage(activeDisplays[0], rect:CGRect(origin: Navigation.shared.cgPosition, size: Navigation.shared.cgSize)) {
		debugPrint("Original:", cgImage.width, cgImage.height)
		if let resizedImage = resizeCGImage(cgImage, toWidth: Int(Navigation.shared.cgSize.width), toHeight:Int(Navigation.shared.cgSize.height)) {
			debugPrint("Resized:", resizedImage.width, resizedImage.height)
			return resizedImage
		}
	}
return nil
}

func initOCR() {
	if Navigation.shared.cgSize != CGSize() {
		if let  cgImage = TakeScreensShots() {
			Navigation.shared.startOCR(cgImage:cgImage)
		} else {
			Accessibility.speakWithSynthesizer("Faild to take a screenshot of \(Navigation.shared.appName), \(Navigation.shared.windowName)")
		}
	} else {
		Accessibility.speakWithSynthesizer("Faild to access \(Navigation.shared.appName), \(Navigation.shared.windowName)")
	}
}

func performOCR(cgImage:CGImage) -> [Observation] {
	let textRecognitionRequest = VNRecognizeTextRequest()
	textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
	textRecognitionRequest.minimumTextHeight = 0
	textRecognitionRequest.usesLanguageCorrection = true
	textRecognitionRequest.customWords = []
	textRecognitionRequest.usesCPUOnly = false
	textRecognitionRequest.cancel()
	let rectDetectRequest = VNDetectRectanglesRequest()
	rectDetectRequest.maximumObservations = 1000
	rectDetectRequest.minimumConfidence = 0.0
	rectDetectRequest.minimumAspectRatio = 0.0
	rectDetectRequest.minimumSize = 0.0
	rectDetectRequest.cancel()

	let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
	do {
		try requestHandler.perform([textRecognitionRequest, rectDetectRequest])
	} catch _ {}
	guard let texts = textRecognitionRequest.results else {
		return []
	}
	var result = texts.map {Observation($0)}

	guard let boxes = rectDetectRequest.results else {
		return []
	}

	var boxesNoText:[Observation] = []
	var boxesText:[Observation] = []
	for box in boxes {
		var intersectsFlag: Bool = false
		for text in texts {
			if box.boundingBox.intersects(text.boundingBox) {
				let obs = Observation(box, value:"Text: "+text.topCandidates(1)[0].string)
				boxesText.append(obs)
				intersectsFlag = true
				break
			}
		}
		if !intersectsFlag {
			let obs = Observation(box, value:"OBJECT")
			boxesNoText.append(obs)
			result.append(obs)
		}
	}

	print("Box Count:", boxes.count)
	print("Text Count:", texts.count)
	print("boxesNoText Count:", boxesNoText.count)
	print("boxesText count:", boxesText.count)
/*
	var pointBoxes: [CGRect] = []
	for point in texts {
		// print("point: ", point)
		pointBoxes.append(CGRect(x: point.boundingBox.minX-0.1, y: point.boundingBox.minY-0.1, width: 0.2, height: 0.2))
	}
*/

	var boxImage = drawBoxes(cgImage, boxes:boxesText, color:NSColor.green)!
	boxImage = drawBoxes(boxImage, boxes:boxesNoText, color:NSColor.blue)!
	// try? saveImage(boxImage)

	return result
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
		/*
		 if message.contains("document") {
		 Navigation.shared.startOCR(cgImage:cgImage)
		 message += "\n"+Navigation.shared.text()
		 }
		 */
	}else {
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

