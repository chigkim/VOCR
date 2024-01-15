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

var task:URLSessionDataTask?

func performRequest(_ request:inout URLRequest, name:String, completion: @escaping (Data) -> Void) {
		request.httpMethod = "POST"
	request.timeoutInterval = 300
	request.setValue("application/json", forHTTPHeaderField: "Content-Type")
	task?.cancel()
	task = URLSession.shared.dataTask(with: request) { data, response, error in
		if let error = error {
			if error.localizedDescription != "cancelled" {
				Accessibility.speakWithSynthesizer("Connection error: \(error.localizedDescription)")
			}
			return
		}

		guard let httpResponse = response as? HTTPURLResponse else {
			Accessibility.speakWithSynthesizer("Invalid response from server.")
			return
		}

		guard httpResponse.statusCode == 200 else {
			Accessibility.speakWithSynthesizer("HTTP Error: Status code \(httpResponse.statusCode)")
			return
		}

		guard let data = data else {
			Accessibility.speakWithSynthesizer("No data received from server.")
			return
		}

		completion(data)
	}
	Accessibility.speakWithSynthesizer("Getting response from \(name)... Please wait...")
	task?.resume()
}


func hide() {
	let windows = NSApplication.shared.windows
	NSApplication.shared.hide(nil)
	windows[1].close()
}

func askPrompt(value:String) -> String? {
	let alert = NSAlert()
	alert.messageText = "Prompt"
	alert.addButton(withTitle: "Ok")
	alert.addButton(withTitle: "Cancel")
	let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
	inputTextField.stringValue = value
		alert.accessoryView = inputTextField
	let response = alert.runModal()
	if response == .alertFirstButtonReturn {
		hide()
		Thread.sleep(forTimeInterval: 0.1)
		let prompt = inputTextField.stringValue
		return prompt
	}
	return nil
}

func grabScreenshot() -> CGImage? {
	var rect:CGRect?
	if Navigation.mode == .WINDOW {
		rect = Navigation.getWindow()
	} else {
		rect = Navigation.getVOCursor()
	}
	if let rect = rect,
	let screenshot = TakeScreensShots(rect:rect) {
		return screenshot
	} else {
		Accessibility.speakWithSynthesizer("Faild to access \(Navigation.appName), \(Navigation.windowName)")
	}
return nil
}

func ask(image:CGImage?=nil) {
	if !Settings.useLastPrompt {
		if let prompt = askPrompt(value:Settings.prompt) {
			Settings.prompt = prompt
		} else {
			return
		}
	}

	let cgImage = image ?? grabScreenshot()
	guard let cgImage = cgImage else { return }
	getModel(for: Settings.model).ask(image: cgImage)
}

func imageToBase64(image: CGImage) -> String {
	let bitmapRep = NSBitmapImageRep(cgImage: image)
	guard let imageData = bitmapRep.representation(using: .jpeg, properties: [:]) else {
		fatalError("Could not convert image to JPEG.")
	}
	let base64_image = imageData.base64EncodedString(options: [])
	return base64_image
}

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
	savePanel.nameFieldStringValue = Navigation.appName+".png"
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
				ctx.setLineWidth(1)
				debugPrint("Drawing boxes:")
				let rects = boxes.map { VNImageRectForNormalizedRect($0.boundingBox, cgImageInput.width, cgImageInput.height) }
				for box in rects {
					debugPrint(box)
					ctx.stroke(box, width: 1.0)
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

func TakeScreensShots(rect:CGRect) -> CGImage? {
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
	if let cgImage = CGDisplayCreateImage(activeDisplays[0], rect:rect) {
		debugPrint("Original:", cgImage.width, cgImage.height)
		Navigation.cgImage = cgImage
		return cgImage
	}
	return nil
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
	if Settings.detectObject {
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
		
//		var boxImage = drawBoxes(cgImage, boxes:boxesText, color:NSColor.green)!
//		 var boxImage = drawBoxes(cgImage, boxes:boxesNoText, color:NSColor.red)!
//		 try? saveImage(boxImage)
	}
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
	}else {
		Accessibility.speak("Unknown")
	}
	return message
}

func runAppleScript(file:String) -> String? {
	let bundle = Bundle.main
	let script = bundle.url(forResource: file, withExtension: "scpt")
	debugPrint(script!)
	var error:NSDictionary?
	if let scriptObject = NSAppleScript(contentsOf: script!, error: &error) {
		var outputError:NSDictionary?
		if let output = scriptObject.executeAndReturnError(&outputError).stringValue {
			debugPrint(output)
			return output
		} else {
			debugPrint("Output Error: \(String(describing: outputError))")
		}
	}
	return nil
}


