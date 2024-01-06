//
//  Shortcuts.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa
import HotKey

struct Shortcuts {
	let describer = HotKey(key:.d, modifiers:[.command,.shift, .control])
	let window = HotKey(key:.w, modifiers:[.command,.shift, .control])
	let vo = HotKey(key:.v, modifiers:[.command,.shift, .control])
	let resetPosition = HotKey(key:.r, modifiers:[.command,.shift, .control])
	let positionalAudio = HotKey(key:.p, modifiers:[.command,.shift, .control])
	let moveMouse = HotKey(key:.m, modifiers:[.command, .shift, .control])
	let targetWindow = HotKey(key:.t, modifiers:[.command, .shift, .control])
	
	init() {

		describer.keyDownHandler = {
			setWindow(0)
			if Navigation.shared.cgSize != CGSize() {
				if let  cgImage = TakeScreensShots() {
					debugPrint(Navigation.shared.cgSize.width, Navigation.shared.cgSize.height)
					let prompt = "Can you describe the user interface in the following JSON format?\n[{'label': 'label', 'short string', 'uid': id_int, 'description': 'description string', 'content': 'string of some examples of contents in the area', 'boundingBox': [top_left_x_pixel, top_left_y_pixel, width_pixel, height_pixel]]\nThe image has dimensions of \(cgImage.width) and \(cgImage.height) height, so scale the pixel coordinates accordingly."
					print(prompt)
					Navigation.shared.askGPT(cgImage: cgImage, prompt: prompt)
				} else {
					Accessibility.speakWithSynthesizer("Faild to take a screenshot of \(Navigation.shared.appName), \(Navigation.shared.windowName)")
				}
			} else {
				Accessibility.speakWithSynthesizer("Faild to access \(Navigation.shared.appName), \(Navigation.shared.windowName)")
			}
		}

		window.keyDownHandler = {
			if !Accessibility.isTrusted(ask:true) {
				print("Accessibility not enabled.")
				return
			}
			setWindow(0)
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
		
		targetWindow.keyDownHandler = {
			if !Accessibility.isTrusted(ask:true) {
				print("Accessibility not enabled.")
				return
			}
			setWindow(-1)
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
		
		vo.keyDownHandler = {
			recognizeVOCursor()
		}
		
		resetPosition.keyDownHandler = {
			if Settings.positionReset {
				Settings.positionReset = false
				Accessibility.speak("Disable reset position.")
			} else {
				Settings.positionReset = true
				Accessibility.speak("Enable reset position.")
			}
			Settings.save()
		}
		
		positionalAudio.keyDownHandler = {
			if Settings.positionalAudio {
				Settings.positionalAudio = false
				Accessibility.speak("Disable positional audio.")
			} else {
				Settings.positionalAudio = true
				Accessibility.speak("Enable positional audio.")
			}
			Settings.save()
		}
		moveMouse.keyDownHandler = {
			if Settings.moveMouse {
				Settings.moveMouse = false
				Accessibility.speak("Disabled mouse movement")
			} else {
				Settings.moveMouse = true
				Accessibility.speak("Enabled mouse movement.")
			}
		}
		
	}
}

