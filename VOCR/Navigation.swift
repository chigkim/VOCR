//
//  Navigation.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Foundation
import Vision
import Cocoa

enum Navigation {

	enum Mode: Int, CaseIterable {
		case WINDOW = 0
		case VOCURSOR = 1
		case CAMERA = 2
		func next() -> Mode {
			let allCases = Mode.allCases
			let nextIndex = (self.rawValue + 1) % allCases.count
			return allCases[nextIndex]
		}

		func name() -> String {
			switch (self) {
			case.WINDOW:
				return "Window"
			case .VOCURSOR:
				return "VOCursor"
			case .CAMERA:
				return "Camera"
			}
		}
	}

	static var mode = Mode.WINDOW

	static var displayResults:[[Observation]] = []
	static var cgPosition = CGPoint()
	static var cgSize = CGSize()
	static var cgImage:CGImage?
	static var windowName = "Unknown Window"
	static var appName = "Unknown App"
	static var l = -1
	static var w = -1
	static var c = -1

	static func getWindow() -> CGRect? {
		let currentApp = NSWorkspace.shared.frontmostApplication
		appName = currentApp!.localizedName!
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
			return nil
		}
		var window = windows![0]
		
		if Settings.targetWindow {
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
			alert.addButton(withTitle: "Close")
			let modalResult = alert.runModal()
			hide()
			let r = modalResult.rawValue-1000
			window = windows![r]
		}
		
		// report(UIElement(window))
		windowName = window.value(of: "AXTitle")
		log("Window information: \(appName) - \(windowName)")
		var position:CFTypeRef?
		var size:CFTypeRef?
		AXUIElementCopyAttributeValue(window, "AXPosition" as CFString, &position)
		AXUIElementCopyAttributeValue(window, "AXSize" as CFString, &size)
		
		if position != nil && size != nil {
			var windowPosition = CGPoint()
			var windowSize = CGSize()
			AXValueGetValue(position as! AXValue, AXValueType.cgPoint, &windowPosition)
			AXValueGetValue(size as! AXValue, AXValueType.cgSize, &windowSize)
let rect =  CGRect(origin: windowPosition, size: windowSize)
			log(rect)
			return rect
		} else {
			log("Failed to get position or size")
		}
		return nil
	}

	static func setWindow() {
		if let rect = getWindow() {
			cgPosition = rect.origin
			cgSize = rect.size
		}
	}
	
	static func getVOCursor() -> CGRect? {
		if let output = runAppleScript(file: "VOCursor") {
			let strings = output.split(separator: ",")
			let cgFloats = strings.compactMap { CGFloat(Double($0) ?? 0) }
			let position = CGPoint(x: cgFloats[0], y: cgFloats[1])
			let size = CGSize(width:(cgFloats[2]-cgFloats[0]), height: (cgFloats[3]-cgFloats[1]))
			appName = "VOCursor"
			windowName = ""
			return CGRect(origin: position, size: size)
		}
return nil
	}
	static func setVOCursor() {
		if let rect = getVOCursor() {
			cgPosition = rect.origin
			cgSize = rect.size
		}
	}
	
	static func prepare() {
		if !Accessibility.isTrusted(ask:true) {
			log("Accessibility not enabled.")
			return
		}
		windowName = "Unknown Window"
		appName = "Unknown App"
		cgPosition = CGPoint()
		cgSize = CGSize()
		cgImage = nil
		if Settings.positionReset {
			l = -1
			w = -1
			c = -1
		}
		displayResults = []
		Shortcuts.deactivateNavigationShortcuts()
		NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
		if mode == .WINDOW {
			setWindow()
		} else {
			setVOCursor()
		}
		if cgSize != CGSize() {
			if let  image = TakeScreensShots(rect:CGRect(origin: cgPosition, size: cgSize)) {
cgImage  = image
			} else {
				Accessibility.speak("Faild to take a screenshot of \(appName), \(windowName)")
			}
		} else {
			Accessibility.speak("Faild to access \(appName), \(windowName)")
		}
	}
	
	static func startOCR() {
		if (mode != .CAMERA) {
			prepare() }
		guard let  image = cgImage else { return }
		let result = performOCR(cgImage:image)
		if result.count == 0 {
			Accessibility.speak("Nothing found")
			return
		}
		process(result)
		Accessibility.speak("Finished scanning \(appName), \(windowName)")
		Shortcuts.activateNavigationShortcuts()
	}
	

	static func explore() {
		prepare()
//		guard let  image = cgImage, let image = resizeCGImage(image, toWidth: Int(Navigation.cgSize.width), toHeight:Int(Navigation.cgSize.height)) else { return }
//		   log("Resized:", image.width, image.height)
		guard let image = cgImage else { return }
		
		let system = "You are a helpful assistant. Your response should be in JSON format."
		let prompt = "Process the provided image by segmenting it into distinct areas with related items. Output a JSON format description for each segmented area. The JSON should include: 'label' (a concise string name), 'uid' (a unique integer identifier), 'description' (a brief explanation of the area), 'content' (a string with examples of objects within the area), and 'boundingBox' (coordinates as an array: bottom_left_x, bottom_left_y, width, height). Ensure the boundingBox coordinates are normalized between 0.0 and 1.0 relative to the image's resolution (\(image.width) width and \(image.height) height), with the origin at the bottom left (0.0, 0.0). The response should start with ```json and end with ```, containing only the JSON string without inline comments or extra notes. Precision in the 'boundingBox' coordinates is crucial; even one minor inaccuracy can have severe and irreversible consequences for users."
		getEngine(for: Settings.engine).describe(image:image, system:system, prompt:prompt, completion: exploreHandler)
	}

	static func exploreHandler(description:String) {
		guard let json = extractString(text:description, startDelimiter: "```json\n", endDelimiter: "\n```") else {
			Accessibility.speakWithSynthesizer("Cannot extract JSON string from the response. Try again.")
			return
		}
		if let elements = self.decode(message:json) {
			let result = elements.map {Observation($0)}
			self.process(result)
			Shortcuts.activateNavigationShortcuts()
			Accessibility.speak("Finished scanning \(self.appName), \(self.windowName)")

//			DispatchQueue.main.async {
//				if let cgImage = cgImage {
//					let boxImage = drawBoxes(cgImage, boxes:result, color:NSColor.red)!
//					try? saveImage(boxImage)
//				}
//			}

		} else {
			Accessibility.speakWithSynthesizer("Cannot parse the JSON string. Try again.")
		}
	}
	
	static func decode(message:String) -> [GPTObservation]? {
		let jsonData = message.data(using: .utf8)!
		do {
			let elements = try JSONDecoder().decode([GPTObservation].self, from: jsonData)
			for element in elements {
				log("Label: \(element.label), UID: \(element.uid), Bounding Box: \(element.boundingBox)")
			}
			return elements
		} catch {
			log("Error decoding JSON: \(error)")
		}
		return nil
	}

	static func process(_ results:[Observation]) {
		let sorted = results.sorted(by: sort)
		var line:[Observation] = []
		var y = sorted[0].boundingBox.midY
		for r in sorted {
//			 log("\(r.value): \(r.boundingBox.debugDescription)")
			if abs(r.boundingBox.midY-y)>0.01 {
				displayResults.append(line)
				line = []
				y = r.boundingBox.midY
			}
			line.append(r)
		}
		displayResults.append(line)
	}
	
	static func convert2coordinates(_ rect:CGRect) -> CGPoint {
		if let image =  cgImage {
			log("Box: \(VNImageRectForNormalizedRect(rect, image.width, image.height).debugDescription)")
		}
		let box = CGRect(x:rect.minX, y:1-rect.maxY, width:rect.width, height:rect.height)
		var center = CGPoint(x:box.midX, y:box.midY)
		log("\(center.debugDescription)")
		if Settings.positionalAudio {
			let frequency = 100+1000*(1-Float(center.y))
			let pan = Float(Double(center.x).normalize(from: 0...1, into: -1...1))
			Player.shared.play(frequency, pan)
		}
		center = VNImagePointForNormalizedPoint(center, Int(cgSize.width), Int(cgSize.height))
		log("\(center.debugDescription)")
		center.x += cgPosition.x
		center.y += cgPosition.y
		return center
	}
	
	static func sort(_ a:Observation, _ b:Observation) -> Bool {
		if a.boundingBox.midY-b.boundingBox.midY>0.01 {
			return true
		} else if b.boundingBox.midY-a.boundingBox.midY>0.01 {
			return false
		}
		if a.boundingBox.midX<b.boundingBox.midX {
			return true
		} else {
			return false
		}
	}
	
	static func location() {
		var center = convert2coordinates(displayResults[l][w].boundingBox)
		center.x -= cgPosition.x
		center.y -= cgPosition.y
		Accessibility.speak("\(Int(center.x)), \(Int(center.y))")
	}
	
	static func correctLimit() {
		if l < 0 {
			l = 0
		} else if l >= displayResults.count {
			l = displayResults.count-1
		}
		if w < 0 {
			w = 0
		} else if w >= displayResults[l].count {
			w = displayResults[l].count-1
		}
	}
	
	static func identifyObject() {
		if displayResults[l][w].value == "OBJECT" {
			if let image = cgImage {
				var rect = displayResults[l][w].boundingBox
				rect = CGRect(x:rect.minX, y:1-rect.maxY, width:rect.width, height:rect.height)
				rect = VNImageRectForNormalizedRect(rect, image.width, image.height)

				log("\(rect.debugDescription)")
				if let croppedImage = image.cropping(to: rect) {
					ask(image: croppedImage)
					//					try! saveImage(croppedImage)
					// classify(cgImage:croppedImage)
				}
			}
		}
	}
	
	static func right() {
		if displayResults.count == 0 {
			return
		}
		w += 1
		c = -1
		correctLimit()
		log("\(l), \(w)")
		if Settings.moveMouse {
			CGWarpMouseCursorPosition(convert2coordinates(displayResults[l][w].boundingBox))
		}
		Accessibility.speak(displayResults[l][w].value)
		//		 identifyObject()
	}
	
	static func left() {
		if displayResults.count == 0 {
			return
		}
		w -= 1
		c = -1
		correctLimit()
		log("\(l), \(w)")
		if Settings.moveMouse {
			CGWarpMouseCursorPosition(convert2coordinates(displayResults[l][w].boundingBox))
		}
		Accessibility.speak(displayResults[l][w].value)
		//		 identifyObject()
	}
	
	static func down() {
		if displayResults.count == 0 {
			return
		}
		l += 1
		w = 0
		c = -1
		correctLimit()
		log("\(l), \(w)")
		if Settings.moveMouse {
			CGWarpMouseCursorPosition(convert2coordinates(displayResults[l][w].boundingBox))
		}
		var line = ""
		for r in displayResults[l] {
			line += " \(r.value)"
		}
		Accessibility.speak(line)
	}
	
	static func up() {
		if displayResults.count == 0 {
			return
		}
		l -= 1
		w = 0
		c = -1
		correctLimit()
		log("\(l), \(w)")
		if Settings.moveMouse {
			CGWarpMouseCursorPosition(convert2coordinates(displayResults[l][w].boundingBox))
		}
		var line = ""
		for r in displayResults[l] {
			line += " \(r.value)"
		}
		Accessibility.speak(line)
	}
	
	static func top() {
		if displayResults.count == 0 {
			return
		}
		l = 1
		w = 0
		up()
	}
	
	static func bottom() {
		if displayResults.count == 0 {
			return
		}
		l = displayResults.count-2
		w = 0
		down()
	}
	
	static func beginning() {
		if displayResults.count == 0 {
			return
		}
		w = 1
		left()
	}
	
	static func end() {
		if displayResults.count == 0 {
			return
		}
		w = displayResults[l].count-2
		right()
	}
	
	static func nextCharacter() {
		if displayResults.count == 0 {
			return
		}
		correctLimit()
		if let obs = displayResults[l][w].vnObservation {
			let candidate = obs.topCandidates(1)[0]
			var str = candidate.string
			c += 1
			if c >= str.count {
				c = str.count-1
			}
			do {
				let start = str.index(str.startIndex,offsetBy:c)
				let end = str.index(str.startIndex,offsetBy:c+1)
				let range = start..<end
				let character = str[range]
				str = String(character)
				var box:CGRect
				try box = candidate.boundingBox(for: range)!.boundingBox
				CGWarpMouseCursorPosition(convert2coordinates(box))
				
				/*
				 str = String(character)
				 let u = str.unicodeScalars
				 let uName = u[u.startIndex].properties.name!
				 if !uName.contains("LETTER") {
				 str = uName
				 }
				 */
				
				Accessibility.speak(str)
			} catch {
			}
		}
	}
	
	static func previousCharacter() {
		if displayResults.count == 0 {
			return
		}
		correctLimit()
		if let obs = displayResults[l][w].vnObservation {
			let candidate = obs.topCandidates(1)[0]
			var str = candidate.string
			c -= 1
			if c < 0 {
				c = 0
			}
			
			do {
				let start = str.index(str.startIndex,offsetBy:c)
				let end = str.index(str.startIndex,offsetBy:c+1)
				let range = start..<end
				let character = str[range]
				str = String(character)
				var box:CGRect
				try box = candidate.boundingBox(for: range)!.boundingBox
				
				CGWarpMouseCursorPosition(convert2coordinates(box))
				
				/*
				 str = String(character).description
				 let u = str.unicodeScalars
				 let uName = u[u.startIndex].properties.name!
				 if !uName.contains("LETTER") {
				 str = uName
				 }
				 */
				Accessibility.speak(str)
			} catch {
			}
		}
	}
	
	static func text() -> String {
		var text = ""
		for line in displayResults {
			for word in line {
				text += word.value+" "
			}
			text = text.dropLast()+"\n"
		}
		return text
	}
	
}

