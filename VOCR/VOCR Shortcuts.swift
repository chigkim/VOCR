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

	let settings = HotKey(key:.s, modifiers:[.command,.shift, .control])
	let window = HotKey(key:.w, modifiers:[.command,.shift, .control])
	let vo = HotKey(key:.v, modifiers:[.command,.shift, .control])
	let explore = HotKey(key:.e, modifiers:[.command,.shift, .control])
	let ask = HotKey(key:.a, modifiers:[.command,.shift, .control])
	let realTime = HotKey(key:.r, modifiers:[.command,.shift, .control])

	init() {

		settings.keyDownHandler = {
			let mouseLocation = NSEvent.mouseLocation
			let rect = CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 1)
			Settings.setupMenu().popUp(positioning: nil, at: rect.origin, in: nil)
		}

		window.keyDownHandler = {
			Navigation.shared.prepare(mode:"OCR")
		}

		explore.keyDownHandler = {
			Navigation.shared.prepare(mode:"Explore")
		}

		vo.keyDownHandler = {
			recognizeVOCursor(mode: "OCR")
		}
		
		ask.keyDownHandler = {
			recognizeVOCursor(mode:"GPT")
		}

		realTime.keyDownHandler = {
			RealTime.continuousOCR()
		}
	}
}

