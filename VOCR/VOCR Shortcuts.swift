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

	var settings:HotKey? = HotKey(key:.s, modifiers:[.command,.shift, .control])
	var window:HotKey? = HotKey(key:.w, modifiers:[.command,.shift, .control])
	var vo:HotKey? = HotKey(key:.v, modifiers:[.command,.shift, .control])
	var explore:HotKey? = HotKey(key:.e, modifiers:[.command,.shift, .control])
	var ask:HotKey? = HotKey(key:.a, modifiers:[.command,.shift, .control])
	var realTime:HotKey? = HotKey(key:.r, modifiers:[.command,.shift, .control])

	init() {

		settings?.keyDownHandler = {
			let mouseLocation = NSEvent.mouseLocation
			let rect = CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 1)
			Settings.setupMenu().popUp(positioning: nil, at: rect.origin, in: nil)
		}

		window?.keyDownHandler = {
			Navigation.shared.prepare(mode:"OCR")
		}

		explore?.keyDownHandler = {
			Navigation.shared.prepare(mode:"GPT")
		}

		vo?.keyDownHandler = {
			recognizeVOCursor(mode: "OCR")
		}
		
		ask?.keyDownHandler = {
			recognizeVOCursor(mode:"GPT")
		}

		realTime?.keyDownHandler = {
			RealTime.continuousOCR()
		}

		settings = nil
		window = nil
		vo = nil
		explore = nil
		ask = nil
		realTime = nil

	}
}

