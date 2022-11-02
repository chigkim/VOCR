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

func saveImage(_ cgimage: CGImage) throws {
	let savePanel = NSSavePanel()
	savePanel.allowedContentTypes = [.png]
	savePanel.allowsOtherFileTypes = false
	savePanel.begin { (result) in
		let windows = NSApplication.shared.windows
		NSApplication.shared.hide(nil)
		windows[1].close()
		if result == .OK {
			if let url = savePanel.url {
				let cicontext = CIContext()
				let ciimage = CIImage(cgImage: cgimage)
				try? cicontext.writePNGRepresentation(of: ciimage, to: url, format: .RGBA8, colorSpace: ciimage.colorSpace!)
			}
		}
	}
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
    
	let rectDetectRequest = VNDetectRectanglesRequest()
	rectDetectRequest.maximumObservations = 100
    rectDetectRequest.minimumConfidence = 0
	rectDetectRequest.minimumAspectRatio = 0
	rectDetectRequest.minimumSize = 0.01
	rectDetectRequest.cancel()
    
	let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
	do {
		try requestHandler.perform([textRecognitionRequest, rectDetectRequest])
	} catch _ {}
	
    
	guard let results = textRecognitionRequest.results else {
		return []
	}
    
    //
    var displayResults:[[VNRecognizedTextObservation]] = []
    var displayResultsBoxes: [CGPoint] = []
    var line:[VNRecognizedTextObservation] = []
    var y = results[0].boundingBox.midY
    for r in results {
        logger.debug("\(r.topCandidates(1)[0]): \(r.boundingBox.debugDescription)")
        if abs(r.boundingBox.midY-y)>0.01 {
            displayResults.append(line)
            line = []
            y = r.boundingBox.midY
        }
        line.append(r)
    }
    displayResults.append(line)
    
    for l in 0...displayResults.count-1 {
        for w in 0...displayResults[l].count-1 {
            displayResultsBoxes.append(Navigation.shared.convert2coordinates(displayResults[l][w].boundingBox))
        }
    }
    //
    
    let boxes = rectDetectRequest.results!.map { VNImageRectForNormalizedRect($0.boundingBox, cgImage.width, cgImage.height) }
//    let texts = displayResultsBoxes.map { VNImagePointForNormalizedPoint($0, cgImage.width, cgImage.height) }
    let texts = displayResultsBoxes

    print("image results")
    print(boxes)
    
    if boxes.count > 0 {

//        print("scaled Boxes")
//        print(scaledBoxes)
        
        var boxesNoText: [CGRect] = []
        var boxesText: [CGRect] = []
        var pointBoxes: [CGRect] = []
        print("boxes Count", boxes.count)
        for box in boxes {
            var intersectsFlag: Bool = false
            for point in texts {
                if box.contains(point) {
                    print("got here", box, point)
                    intersectsFlag = true
//                    print("intersection")
                    break
                } else {
                    if (box.minX < point.x && (box.maxX > point.x)) {
                        print("X matches for ", box, point)
                    }
                }
            }
            if !intersectsFlag {
                boxesNoText.append(box)
            } else {
                boxesText.append(box)
            }
        }
        print("Number Boxes:", texts.count)
        for point in texts {
            print("point: ", point)
            pointBoxes.append(CGRect(x: point.x-0.1, y: point.y-0.1, width: 0.2, height: 0.2))
        }
        for box in boxes {
            print("box: ", box)
        }
        print("boxesNoText Count", boxesNoText.count)
        print("boxes: ", boxesText.count)
//        print("total", cgImage.width, cgImage.height)
        
//        var scaledBoxes: [CGRect] = []
//        debugPrint("Boxes coordinates adjusted to window")
//        for r in boxesNoText {
//            let tl = Navigation.shared.convertPoint(r.topLeft)
//            let tr = Navigation.shared.convertPoint(r.topRight)
//            let bl = Navigation.shared.convertPoint(r.bottomLeft)
//            let br = Navigation.shared.convertPoint(r.bottomRight)
//            let box = CGRect(x: tl.x, y: tl.y, width: br.x-bl.x, height: br.y-tr.y)
//            scaledBoxes.append(box)
//            debugPrint("Box: \(box)")
//        }
//
        
        Accessibility.speak("\(boxes.count) boxes")
        Accessibility.speak("\(boxesNoText.count) boxesNoText")
        let pointImage = drawBoxes(cgImage, boxes:pointBoxes)!
        try? saveImage(pointImage)
//        let boxImage = drawBoxes(cgImage, boxes:boxesText )!
//        try? saveImage(boxImage)
    }
    
    print("results")
    print(results)
	return results
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
