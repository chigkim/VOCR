//
//  Shortcuts.swift
//  FloTools
//
//  Created by Chi Kim on 2/3/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Foundation
import Cocoa


class Shortcuts {
	

	let start = HotKey(key:.o, modifiers:[.command,.shift, .control])
	//	let picture = HotKey(key:.p, modifiers:[.command,.shift])

	init() {
		start.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.start()
		}

//		picture.keyDownHandler = {
//			let app = NSApplication.shared.delegate as! AppDelegate
//			app.takePicture()
//		}

	}

}
