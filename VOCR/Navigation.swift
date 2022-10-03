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

class Navigation {

	static let shared = Navigation()
	var displayResults:[[VNRecognizedTextObservation]] = []
	var navigationShortcuts:NavigationShortcuts?
	var cgPosition = CGPoint()
	var cgSize = CGSize()
	var l = -1
	var w = -1
	var c = -1

	func startOCR(cgImage:CGImage) {
		if Settings.positionReset {
			l = -1
			w = -1
			c = -1
		}
		displayResults = []
		navigationShortcuts = nil
		NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
		var result = performOCR(cgImage:cgImage)
		if result.count == 0 {
			Accessibility.speak("Nothing found")
			return
		}
		process(result:&result)
		Accessibility.speak("Finished!")
		navigationShortcuts = NavigationShortcuts()
	}

	func process(result:inout[VNRecognizedTextObservation]) {
		result = result.sorted(by: sort)
		var line:[VNRecognizedTextObservation] = []
		var y = result[0].boundingBox.midY
		for r in result {
			logger.debug("\(r.topCandidates(1)[0]): \(r.boundingBox.debugDescription)")
			if abs(r.boundingBox.midY-y)>0.01 {
				displayResults.append(line)
				line = []
				y = r.boundingBox.midY
			}
			line.append(r)
		}
		displayResults.append(line)
	}
	
	func convertPoint(_ point:CGPoint) -> CGPoint {
			var p = VNImagePointForNormalizedPoint(point, Int(cgSize.width), Int(cgSize.height))
			p.y = cgSize.height-p.y
			p.x += cgPosition.x
			p.y += cgPosition.y
	return p
	}
	
func convert2coordinates(_ box:CGRect) -> CGPoint {
			let center = CGPoint(x:box.midX, y:box.midY)
		if Settings.positionalAudio {
			let frequency = 100+1000*Float(center.y)
			let pan = Float(Double(center.x).normalize(from: 0...1, into: -1...1))
			Player.shared.play(frequency, pan)
		}
		return convertPoint(center)
	}

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

	func location() {
		var center = convert2coordinates(displayResults[l][w].boundingBox)
		center.x -= cgPosition.x
		center.y -= cgPosition.y
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
		if displayResults.count == 0 {
			return
		}
		w += 1
		c = -1
		correctLimit()
		print("\(l), \(w)")
        if Settings.moveMouse {
		CGDisplayMoveCursorToPoint(0, convert2coordinates(displayResults[l][w].boundingBox))
        }
		Accessibility.speak(displayResults[l][w].topCandidates(1)[0].string)
	}
	
	func left() {
		if displayResults.count == 0 {
			return
		}
		w -= 1
		c = -1
		correctLimit()
		print("\(l), \(w)")
        if Settings.moveMouse {
		CGDisplayMoveCursorToPoint(0, convert2coordinates(displayResults[l][w].boundingBox))
        }
		Accessibility.speak(displayResults[l][w].topCandidates(1)[0].string)
	}

	func down() {
		if displayResults.count == 0 {
			return
		}
		l += 1
			w = 0
		c = -1
		correctLimit()
		print("\(l), \(w)")
        if Settings.moveMouse {
		CGDisplayMoveCursorToPoint(0, convert2coordinates(displayResults[l][w].boundingBox))
        }
		var line = ""
		for r in displayResults[l] {
			line += " \(r.topCandidates(1)[0].string)"
		}
		Accessibility.speak(line)
	}

	func up() {
		if displayResults.count == 0 {
			return
		}
		l -= 1
			w = 0
		c = -1
		correctLimit()
		print("\(l), \(w)")
        if Settings.moveMouse {
		CGDisplayMoveCursorToPoint(0, convert2coordinates(displayResults[l][w].boundingBox))
        }
		var line = ""
		for r in displayResults[l] {
			line += " \(r.topCandidates(1)[0].string)"
		}
		Accessibility.speak(line)
	}

	func top() {
		if displayResults.count == 0 {
			return
		}
		l = 1
		w = 0
		up()
	}

	func bottom() {
		if displayResults.count == 0 {
			return
		}
		l = displayResults.count-2
		w = 0
		down()
	}

	func beginning() {
		if displayResults.count == 0 {
			return
		}
		w = 1
		left()
	}
	
	func end() {
		if displayResults.count == 0 {
			return
		}
		w = displayResults[l].count-2
		right()
	}

	func nextCharacter() {
		if displayResults.count == 0 {
			return
		}
		correctLimit()
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
			str = String(character)
			var box:CGRect
			try box = candidate.boundingBox(for: range)!.boundingBox
			CGDisplayMoveCursorToPoint(0, convert2coordinates(box))

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

	func previousCharacter() {
		if displayResults.count == 0 {
			return
		}
		correctLimit()
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
			str = String(character)
			var box:CGRect
			try box = candidate.boundingBox(for: range)!.boundingBox
			CGDisplayMoveCursorToPoint(0, convert2coordinates(box))

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

	func text() -> String {
var text = ""
		for line in displayResults {
			for word in line {
				text += word.topCandidates(1)[0].string+" "
			}
			text = text.dropLast()+"\n"
		}
return text
	}

}

