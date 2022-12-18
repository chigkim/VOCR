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
import Socket
import SwiftyJSON
let logger = Logger()

let labelIdToLabel = [0: "arrow",
					  1: "button",
					  2: "dropdown",
					  3: "icon",
					  4: "knob",
					  5: "light",
					  6: "meter",
					  7: "multiple elements",
					  8: "multiple knobs",
					  9: "needle",
					  10: "non-interactive",
					  11: "radio button",
					  12: "slider",
					  13: "switch",
					  14: "unknown"]

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

func chooseFile() -> URL? {
	var url:URL?
	let openPanel = NSOpenPanel()
	openPanel.title                   = "Choose an Image"
	openPanel.canChooseDirectories = false
	openPanel.canChooseFiles = true
	openPanel.allowsMultipleSelection = false
	openPanel.allowedContentTypes = [.png, .jpeg, .gif, .bmp]
	if (openPanel.runModal() == .OK) {
		let windows = NSApplication.shared.windows
		NSApplication.shared.hide(nil)
		windows[1].close()
		url =  openPanel.url
	}
	return url
}

func loadImage(_ url:URL) -> CGImage? {
	if let dataImage = try? Data(contentsOf:url) {
		let dataProvider = CGDataProvider(data: dataImage as CFData)
		if ["png", "PNG"].contains(url.pathExtension) {
			if let cgImage = CGImage(pngDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
				return cgImage
			}
		}
		if ["jpg", "jpeg", "JPG", "JPEG"].contains(url.pathExtension) {
			if let cgImage = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
				return cgImage
			}
		}
	}
	return nil
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
				//                debugPrint("Drawing boxes:")
				for box in boxes {
					//                    debugPrint(box)
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
	//    let appID = currentApp!.processIdentifier
	//    let appElement = AXUIElementCreateApplication(appID)
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
	Navigation.shared.windowSize = cgSize
	Navigation.shared.windowPosition = cgPosition
	//    print("\(cgPosition), \(cgSize)")
	return CGDisplayCreateImage(activeDisplays[0], rect:CGRect(origin: cgPosition, size: cgSize))
}

func performOCR(cgImage:CGImage) -> [DetectedRectangle] {
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
	
	let textResults = textRecognitionRequest.results ?? []
	//    print("textboxes", textResults)
	
	
	var textRectsArray: [[Float]] = []
	var textLabelsArray: [String] = []
	for result in textResults {
		let rect = result.boundingBox
		textRectsArray.append([Float(rect.minX), Float(rect.minY), Float(rect.width), Float(rect.height)])
		textLabelsArray.append(result.topCandidates(1)[0].string)
	}
	
	let pythonResult = predict(cgImage: cgImage, rects: textRectsArray, texts: textLabelsArray)
	
	Navigation.shared.imgSize.width = CGFloat(cgImage.width)
	Navigation.shared.imgSize.height = CGFloat(cgImage.height)
	
	let pythonBoxes = pythonResult?.0 ?? []
	let pythonLabels = pythonResult?.1 ?? []
	
	//    print("Got python results. Boxes: ", pythonBoxes)
	//    print("Got python results. Labels: ", pythonLabels)
	
	var rectBoxes: [CGRect] = []
	var scaledRectBoxes: [CGRect] = []
	//    var rectResults: [VNRecognizedTextObservation] = []
	var rectLabels: [String] = []
	for i in 0..<(pythonLabels.count) {
		let box = pythonBoxes[i]
		let label = pythonLabels[i]
		let rect = CGRectMake(CGFloat(box[0]), CGFloat(box[1]), CGFloat(box[2]), CGFloat(box[3]))
		let scaledRect = Navigation.shared.convertRect2NormalizedImageCoords(rect)
		
		var collidesWithText = false
		for textBox in textResults {
			if textBox.boundingBox.intersects(scaledRect) {
				let intersection = textBox.boundingBox.intersection(scaledRect)
				let intersectionArea = intersection.height*intersection.width
				if intersectionArea > scaledRect.height*scaledRect.width*0.5 {
					collidesWithText = true
				}
			}
		}
//		let imageRect = VNImageRectForNormalizedRect(scaledRect, cgImage.width, cgImage.height)
		if !collidesWithText {
			//            let rectObservation = VNRecognizedTextObservation(boundingBox: scaledRect)
			//            rectResults.append(rectObservation)
			rectBoxes.append(scaledRect)
			rectLabels.append(label)
		}
//		scaledRectBoxes.append(imageRect)
		
	}
//	rectBoxes.append(CGRectMake(0, 0, CGFloat(cgImage.width), CGFloat(cgImage.height)))
//	rectLabels.append("unknown")
	
	var pointBoxes: [CGRect] = []
	let texts = textResults.map{VNImageRectForNormalizedRect($0.boundingBox, cgImage.width, cgImage.height)}
	for point in texts {
		pointBoxes.append(CGRect(x:point.minX-0.1, y:point.minY-0.1, width:0.2, height:0.2))
	}
	
	//    print("Got pruned rects. Boxes: ", rectBoxes)
	//    print("Got pruned labels. Labels: ", rectLabels)
	
	//    if let url = chooseFolder() {
	//        let boxImage = drawBoxes(cgImage, boxes:rectBoxes)!
	//        try? saveImage(boxImage, url.appendingPathComponent("boxes2.png"))
	//        let scaledBoxImage = drawBoxes(cgImage, boxes:scaledRectBoxes)!
	//        try? saveImage(scaledBoxImage, url.appendingPathComponent("scaledBoxes2.png"))
	//        let textImage = drawBoxes(cgImage, boxes:pointBoxes)!
	//        try? saveImage(textImage, url.appendingPathComponent("text_points2.png"))
	//    }
	//    print("Width of image: ", cgImage.width, ", Height of image: ", cgImage.height)
	
	// rectBoxes is contour results, textResults is textRecognitionRequest results
	var allRects: [CGRect] = []
	var allLabels: [String] = []
	
	for i in 0..<rectBoxes.count {
		allRects.append(rectBoxes[i])
		allLabels.append(rectLabels[i])
	}
	
	for textResult in textResults {
		//        allRects.append(Navigation.shared.convert2coordinates(textResult.boundingBox))
		allRects.append(textResult.boundingBox)
		allLabels.append(textResult.topCandidates(1)[0].string)
	}
	
	print("Got rects to return. Rects: ", allRects)
	print("Got labels to return. Labels: ", allLabels)
	
	var allResults: [DetectedRectangle] = []
	
	for i in 0..<allRects.count {
		allResults.append(DetectedRectangle(string: allLabels[i], boundingBox: allRects[i]))
	}
	
	return allResults
	
}

func pixelValues(fromCGImage imageRef: CGImage?) -> (pixelValues: [UInt8]?, width: Int, height: Int)
{
	var width = 0
	var height = 0
	var pixelValues: [UInt8]?
	if let imageRef = imageRef {
		width = imageRef.width
		height = imageRef.height
		let bitsPerComponent = imageRef.bitsPerComponent
		let bytesPerRow = imageRef.bytesPerRow
		let totalBytes = height * bytesPerRow
		let bitmapInfo = imageRef.bitmapInfo
		
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		var intensities = [UInt8](repeating: 0, count: totalBytes)
		
		let contextRef = CGContext(data: &intensities, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
		contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
		
		pixelValues = intensities
	}
	
	return (pixelValues, width, height)
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

func predict(cgImage:CGImage, rects:[[Float]], texts:[String]) -> ([[Float]], [String])? {
	let cicontext = CIContext()
	let ciimage = CIImage(cgImage: cgImage)
	let imageData = cicontext.jpegRepresentation(of: ciimage, colorSpace: ciimage.colorSpace!)
	var boxes:[[Float]] = []
	var labels:[String] = []
	
	if Client.connect() {
		print("Sending image data")
		Client.send(imageData!)
		guard  let  data = Client.recv() else { return nil }
		if String(decoding: data, as: UTF8.self) != "Got Image" {
			return nil
		}
		var j:JSON = [:]
		j["boxes"] = JSON(rects)
		j["texts"] = JSON(texts)
		guard let jstr = j.rawString() else { return nil }
		Client.send(Data(jstr.utf8))
		guard  let  data = Client.recv() else { return nil }
		j = JSON(data)
		let res = j.arrayValue
		print("Results:", res.count)
		
		for r in res {
			let box = r.arrayValue.map { $0.floatValue }
			
			let intLabel = Int(box[4]);
			
			let boxWidth = box[2]
			let boxHeight = box[3]
			//            let area = box[2] * box[3]
			var keepBox = true
			switch intLabel {
			case 4:
				keepBox = (boxWidth > 20 && boxHeight > 20) ? true : false
			default:
				keepBox = (boxWidth > 4 && boxHeight > 4) ? true : false
			}
			
			if keepBox {
				boxes.append(Array(box[0...3]))
				let label = labelIdToLabel[intLabel]!
				labels.append(label)
			}
		}
		print("Python returned following boxes: ", boxes)
		print("Python returned following labels: ", labels)
	}
	return (boxes, labels)
}
