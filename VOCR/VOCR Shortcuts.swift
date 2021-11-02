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
	
	let window = HotKey(key:.w, modifiers:[.command,.shift, .control])
	let vo = HotKey(key:.v, modifiers:[.command,.shift, .control])
	let resetPosition = HotKey(key:.r, modifiers:[.command,.shift, .control])
	let positionalAudio = HotKey(key:.p, modifiers:[.command,.shift, .control])
	
	init() {
		window.keyDownHandler = {
			if !Accessibility.isTrusted(ask:true) {
				print("Accessibility not enabled.")
				return
			}
			
			if let  cgImage = TakeScreensShots() {
				Navigation.shared.startOCR(cgImage:cgImage)
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
		
	}
	
}

