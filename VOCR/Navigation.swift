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
    var displayResultsBoxes: [CGRect] = []
	var navigationShortcuts:NavigationShortcuts?
	var cgPosition = CGPoint()
	var cgSize = CGSize()
    var imgSize = CGSize()
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
        if (result.count == 0) {
			Accessibility.speak("Nothing found")
			return
		}
		process(result:&result)
		// Accessibility.speak("Finished!")
		navigationShortcuts = NavigationShortcuts()
	}

	func process(result:inout[VNRecognizedTextObservation]) {
		result = result.sorted(by: sort)
		var line:[VNRecognizedTextObservation] = []
		var y = result[0].boundingBox.midY
		for r in result {
            if r.topCandidates(1) != [] {
                logger.debug("\(r.topCandidates(1)[0]): \(r.boundingBox.debugDescription)")
            } else {
                logger.debug("rectangle: \(r.boundingBox.debugDescription)")
            }
			
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
                displayResultsBoxes.append(displayResults[l][w].boundingBox)
            }
        }
//        print("displayResults results")
//        print(displayResults)
//
//        print("displayResults results")
//        print(displayResults[0][0])
//        print(displayResults[0][0].topCandidates(1)[0])
//        print(displayResults[0][0].topCandidates(1)[0].string)
//        print(displayResults[0][0].boundingBox)
//        print(type(of: displayResults[0][0].boundingBox))
	}
	
    func convertPoint(_ point:CGPoint, normalized:Bool) -> CGPoint {
        var p = point
        if (normalized) {
            p = VNImagePointForNormalizedPoint(point, Int(cgSize.width), Int(cgSize.height))
        } else {
            p = VNNormalizedPointForImagePoint(point, Int(imgSize.width), Int(imgSize.height))
//            var normalized_point = CGPoint.init()
//            normalized_point.x = CGFloat(p.x / imgSize.height)
//            normalized_point.y = CGFloat(p.y / imgSize.width)
            p = VNImagePointForNormalizedPoint(p, Int(cgSize.width), Int(cgSize.height))
        }
        print("p", p, "cgSize", cgSize, "imgSize", imgSize, "cgPosition", cgPosition)
        p.y = cgSize.height-p.y
        p.x += cgPosition.x
        p.y += cgPosition.y
	return p
	}
	
    func convert2coordinates(_ box:CGRect, normalized:Bool) -> CGPoint {
        let center = CGPoint(x:box.midX, y:box.midY)
		if Settings.positionalAudio {
			let frequency = 100+1000*Float(center.y)
			let pan = Float(Double(center.x).normalize(from: 0...1, into: -1...1))
			Player.shared.play(frequency, pan)
		}
        return convertPoint(center, normalized: normalized)
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
        let rect = displayResults[l][w]
        let res = rect.topCandidates(1)
        var point = CGPoint.init()
        if (res != []) {
            point = convert2coordinates(rect.boundingBox, normalized: true)
        } else {
            point = convert2coordinates(rect.boundingBox, normalized: false)
        }
        
		var center = point
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
        
        let rect = displayResults[l][w]
        let res = rect.topCandidates(1)
        var point = CGPoint.init()
        if (res != []) {
            point = convert2coordinates(rect.boundingBox, normalized: true)
            Accessibility.speak(res[0].string)
        } else {
            point = convert2coordinates(rect.boundingBox, normalized: false)
            Accessibility.speak("Icon Detected")
        }
        
        if Settings.moveMouse {
            CGDisplayMoveCursorToPoint(0, point)
        }
	}
	
	func left() {
		if displayResults.count == 0 {
			return
		}
		w -= 1
		c = -1
		correctLimit()
		print("\(l), \(w)")
        
        let rect = displayResults[l][w]
        let res = rect.topCandidates(1)
        var point = CGPoint.init()
        if (res != []) {
            point = convert2coordinates(rect.boundingBox, normalized: true)
            Accessibility.speak(res[0].string)
        } else {
            point = convert2coordinates(rect.boundingBox, normalized: false)
            Accessibility.speak("Icon Detected")
        }
        
        if Settings.moveMouse {
            CGDisplayMoveCursorToPoint(0, point)
        }
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
        
        let rect = displayResults[l][w]
        var point = CGPoint.init()
		var line = ""
		for r in displayResults[l] {
            let res = r.topCandidates(1)
            if (res != []) {
                point = convert2coordinates(rect.boundingBox, normalized: true)
                line += " \(res[0].string)"
            } else {
                point = convert2coordinates(rect.boundingBox, normalized: false)
                line += " Icon Detected!"
            }
//			line += " \(r.topCandidates(1)[0].string)"
		}
        
        if Settings.moveMouse {
            CGDisplayMoveCursorToPoint(0, point)
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
        
        let rect = displayResults[l][w]
        var point = CGPoint.init()
        var line = ""
        for r in displayResults[l] {
            let res = r.topCandidates(1)
            if (res != []) {
                point = convert2coordinates(rect.boundingBox, normalized: true)
                line += " \(res[0].string)"
            } else {
                point = convert2coordinates(rect.boundingBox, normalized: false)
                line += " Icon Detected!"
            }
//            line += " \(r.topCandidates(1)[0].string)"
        }
        
        if Settings.moveMouse {
            CGDisplayMoveCursorToPoint(0, point)
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
        var str = ""
        let curr = displayResults[l][w]
        let res = curr.topCandidates(1)
        if (res != []) {
            str = res[0].string
        } else {
            str = "Icon Detected!"
        }
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
            if (res != []) {
                try box = res[0].boundingBox(for: range)!.boundingBox
                CGDisplayMoveCursorToPoint(0, convert2coordinates(box, normalized: true))
            } else {
                box = curr.boundingBox
                CGDisplayMoveCursorToPoint(0, convert2coordinates(box, normalized: false))
            }
			

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
        var str = ""
        let curr = displayResults[l][w]
        let res = curr.topCandidates(1)
        if (res != []) {
            str = res[0].string
        } else {
            str = "Icon Detected!"
        }
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
            if (res != []) {
                try box = res[0].boundingBox(for: range)!.boundingBox
                CGDisplayMoveCursorToPoint(0, convert2coordinates(box, normalized: true))
            } else {
                box = curr.boundingBox
                CGDisplayMoveCursorToPoint(0, convert2coordinates(box, normalized: false))
            }

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
                let res = word.topCandidates(1)
                if (res == []) {
                    text += "Icon Detected!"
                } else {
                    text += res[0].string+" "
                }
			}
			text = text.dropLast()+"\n"
		}
return text
	}

}

