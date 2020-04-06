//
//  Shortcuts.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa

struct Shortcuts {
	
	let window = HotKey(key:.w, modifiers:[.command,.shift, .control])
	let camera = HotKey(key:.c, modifiers:[.command,.shift,.control])
	let vo = HotKey(key:.v, modifiers:[.command,.shift, .control])
	let resetPosition = HotKey(key:.r, modifiers:[.command,.shift, .control])
	let positionalAudio = HotKey(key:.p, modifiers:[.command,.shift, .control])
	let save = HotKey(key:.s, modifiers:[.command,.shift, .control])
	
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
		
		camera.keyDownHandler = {
			if MacCamera.shared.isCameraAllowed() {
				MacCamera.shared.takePicture()
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
		}
		
		positionalAudio.keyDownHandler = {
			if Settings.positionalAudio {
				Settings.positionalAudio = false
				Accessibility.speak("Disable positional audio.")
			} else {
				Settings.positionalAudio = true
				Accessibility.speak("Enable positional audio.")
			}
		}
		save.keyDownHandler = {
			let savePanel = NSSavePanel()
			savePanel.allowedFileTypes = ["txt"]
			savePanel.allowsOtherFileTypes = false
			savePanel.begin { (result) in
				if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
					if let url = savePanel.url {
						var text = ""
						let displayResults = Navigation.shared.displayResults
						for line in displayResults {
							for word in line {
								text += word.topCandidates(1)[0].string+" "
							}
							text = text.dropLast()+"\n"
						}
						
						try! text.write(to: url, atomically: false, encoding: .utf8)
					}
					
				}
				let windows = NSApplication.shared.windows
				NSApplication.shared.hide(nil)
				windows[1].close()
			}
		}
	}
	
}

