import Cocoa
import Vision


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	var results: [VNRecognizedTextObservation]?
	var requestHandler: VNImageRequestHandler?
	var textRecognitionRequest: VNRecognizeTextRequest!
	let shortcuts = Shortcuts()
	var cgPosition = CGPoint(x: 0, y: 0)
	var cgSize = CGSize(width: 0, height: 0)
	var displayResults:[[VNRecognizedTextObservation]] = []
	var l = -1
	var w = -1
	var c = -1

	var windows:[NSWindow] = []
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		if !Accessibility.isTrusted(ask:true) {
			print("Accessibility not enabled.")
		}

		let menu = NSMenu()
		menu.addItem(withTitle: "Show", action: #selector(AppDelegate.click(_:)), keyEquivalent: "")
		menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "")

		statusItem.menu = menu
		if let button = statusItem.button {
			button.title = "VOCR"
			button.action = #selector(AppDelegate.click(_:))
		}

		windows = NSApplication.shared.windows
		NSApplication.shared.hide(self)
		windows[1].close()

		textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
		textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
		textRecognitionRequest.minimumTextHeight = 0
		textRecognitionRequest.usesLanguageCorrection = true
		textRecognitionRequest.customWords = []
		textRecognitionRequest.usesCPUOnly = false
	/*
		let osc = AKOscillator()
		let env = AKAmplitudeEnvelope(osc)
		env.attackDuration = 0.01
		env.decayDuration = 0.1
		env.sustainLevel = 0.0
		env.releaseDuration = 0.3
		AudioKit.output = env
		try! AudioKit.start()
		osc.start()
		env.start()
		*/

	}

	@objc func click(_ sender: Any?) {
		//windows[1].center()
		NSApplication.shared.activate(ignoringOtherApps: true)
		windows[1].makeKeyAndOrderFront(nil)
	}

	@objc func quit(_ sender: AnyObject?) {
		NSApplication.shared.terminate(self)
	}

	func start() {
		NSSound(contentsOfFile: "/System/Library/Sounds/Tink.aiff", byReference: true)?.play()
		if let  cgImage = TakeScreensShots() {
			requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
			performOCRRequest()
		}
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
		let appID = currentApp!.processIdentifier
		let appElement = AXUIElementCreateApplication(appID)
		let windows = currentApp?.windows()
		let window = windows![0]
		print("Window information")
		print(window.value(of: "AXTitle"))
		var position:CFTypeRef?
		var size:CFTypeRef?
		AXUIElementCopyAttributeValue(window, "AXPosition" as CFString, &position)
		AXUIElementCopyAttributeValue(window, "AXSize" as CFString, &size)
		AXValueGetValue(position as! AXValue, AXValueType.cgPoint, &cgPosition)
		AXValueGetValue(size as! AXValue, AXValueType.cgSize, &cgSize)
		print("\(cgPosition), \(cgSize)")
		let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[0], rect:CGRect(origin: cgPosition, size: cgSize))!
		return screenShot
	}

	func performOCRRequest() {
		textRecognitionRequest.cancel()
		DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async { [unowned self] in
			do {
				try self.requestHandler?.perform([self.textRecognitionRequest])
			} catch _ {}
		}
	}

	func convert2coordinates(_ box:CGRect) -> CGPoint {
			var center = CGPoint(x:box.midX, y:box.midY)
		center = VNImagePointForNormalizedPoint(center, Int(cgSize.width), Int(cgSize.height))
		center.y = cgSize.height-center.y
		center.x += cgPosition.x
		center.y += cgPosition.y
		return center
	}

	func recognizeTextHandler(request: VNRequest, error: Error?) {
		DispatchQueue.main.async { [unowned self] in
			if var results = self.textRecognitionRequest.results as? [VNRecognizedTextObservation] {

				func sort(_ a:VNRecognizedTextObservation, _ b:VNRecognizedTextObservation) -> Bool {
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
				results = results.sorted(by: sort)
				self.displayResults = []
				var line:[VNRecognizedTextObservation] = []
				var y = results[0].boundingBox.midY
				for r in results {
					print("\(r.topCandidates(1)[0]): \(r.boundingBox)")
					if abs(r.boundingBox.midY-y)>0.01 {
						self.displayResults.append(line)
						line = []
						y = r.boundingBox.midY
					}
					line.append(r)
				}
				self.displayResults.append(line)
			}
			Accessibility.speak("Finished!")
		}
	}

	func location() {
		let center = convert2coordinates(displayResults[l][w].boundingBox)
		Accessibility.speak("\(Int(center.x)), \(Int(center.y))")
	}

	
	func correctLimit() {
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

	func right() {
		w += 1
		c = -1
		correctLimit()
		print("\(l), \(w)")
		CGDisplayMoveCursorToPoint(0, convert2coordinates(displayResults[l][w].boundingBox))
		Accessibility.speak(displayResults[l][w].topCandidates(1)[0].string)
	}
	
	func left() {
		w -= 1
		c = -1
		correctLimit()
		print("\(l), \(w)")
		CGDisplayMoveCursorToPoint(0, convert2coordinates(displayResults[l][w].boundingBox))
		Accessibility.speak(displayResults[l][w].topCandidates(1)[0].string)
	}

	func down() {
		l += 1
			w = 0
		c = -1
		correctLimit()
		print("\(l), \(w)")
		CGDisplayMoveCursorToPoint(0, convert2coordinates(displayResults[l][w].boundingBox))
		var line = ""
		for r in displayResults[l] {
			line += " \(r.topCandidates(1)[0].string)"
		}
		Accessibility.speak(line)
	}

	func up() {
		l -= 1
			w = 0
		c = -1
		correctLimit()
		print("\(l), \(w)")
		CGDisplayMoveCursorToPoint(0, convert2coordinates(displayResults[l][w].boundingBox))
		var line = ""
		for r in displayResults[l] {
			line += " \(r.topCandidates(1)[0].string)"
		}
		Accessibility.speak(line)
	}

	func nextCharacter() {
		let candidate = displayResults[l][w].topCandidates(1)[0]
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
			var box:CGRect
			try box = candidate.boundingBox(for: range)!.boundingBox
			CGDisplayMoveCursorToPoint(0, convert2coordinates(box))
			str = String(character)
			let u = str.unicodeScalars
			let uName = u[u.startIndex].properties.name!
			if !uName.contains("LETTER") {
				str = uName
			}
			Accessibility.speak(str)
		} catch {
		}
	}

	func previousCharacter() {
		let candidate = displayResults[l][w].topCandidates(1)[0]
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
			var box:CGRect
			try box = candidate.boundingBox(for: range)!.boundingBox
			CGDisplayMoveCursorToPoint(0, convert2coordinates(box))
			str = String(character).description
			let u = str.unicodeScalars
			let uName = u[u.startIndex].properties.name!
			if !uName.contains("LETTER") {
				str = uName
			}

			Accessibility.speak(str)
		} catch {
		}

	}


}
