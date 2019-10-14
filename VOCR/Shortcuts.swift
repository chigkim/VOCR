//
//  Shortcuts.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

class Shortcuts {
	
	let window = HotKey(key:.w, modifiers:[.command,.shift, .control])
	let camera = HotKey(key:.c, modifiers:[.command,.shift,.control])
	let vo = HotKey(key:.v, modifiers:[.command,.shift, .control])
	let resetPosition = HotKey(key:.r, modifiers:[.command,.shift, .control])
	let positionalAudio = HotKey(key:.p, modifiers:[.command,.shift, .control])

	init() {
		window.keyDownHandler = {
			if let  cgImage = TakeScreensShots() {
				Navigation.shared.startOCR(cgImage:cgImage)
			}
		}

		camera.keyDownHandler = {
			if MacCamera.shared.isCameraAllowed() {
				MacCamera.shared.takePicture()
			}
			}

		vo.keyDownHandler = {
			recognizeVOCursor()
		}

		resetPosition.keyDownHandler = {
			if Navigation.shared.positionReset {
				Navigation.shared.positionReset = false
				Accessibility.speak("Disable reset position.")
			} else {
				Navigation.shared.positionReset = true
				Accessibility.speak("Enable reset position.")
			}
		}

		positionalAudio.keyDownHandler = {
			if Navigation.shared.positionalAudio {
				Navigation.shared.positionalAudio = false
				Accessibility.speak("Disable positional audio.")
			} else {
				Navigation.shared.positionalAudio = true
				Accessibility.speak("Enable positional audio.")
			}
		}

	}

}

