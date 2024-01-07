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
	let targetWindow = HotKey(key:.t, modifiers:[.command, .shift, .control])
	
	init() {
		
		describer.keyDownHandler = {
			setWindow(0)
			if Navigation.shared.cgSize != CGSize() {
				if let  cgImage = TakeScreensShots() {
					debugPrint(Navigation.shared.cgSize.width, Navigation.shared.cgSize.height)
					Navigation.shared.exploreWithGPT(cgImage: cgImage)
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
			initOCR()
		}
		
		targetWindow.keyDownHandler = {
			if !Accessibility.isTrusted(ask:true) {
				print("Accessibility not enabled.")
				return
			}
			setWindow(-1)
			initOCR()
		}
		
		vo.keyDownHandler = {
			recognizeVOCursor()
		}
		
	}
}

