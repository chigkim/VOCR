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

	init() {

		settings.keyDownHandler = {
			let mouseLocation = NSEvent.mouseLocation
			let rect = CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 1)
			guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
			appDelegate.statusItem.menu?.popUp(positioning: nil, at: rect.origin, in: nil)
		}

		window.keyDownHandler = {
			Navigation.shared.initOCR()
		}
		
		vo.keyDownHandler = {
			recognizeVOCursor()
		}
		
	}
}

