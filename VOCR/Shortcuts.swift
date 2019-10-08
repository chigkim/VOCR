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
	
	let start = HotKey(key:.o, modifiers:[.command,.shift])
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

		NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
			if self.myKeyDown(with: $0) {
				return nil
			} else {
				return $0
			}
		}
	}


	func myKeyDown(with event: NSEvent) -> Bool {
		if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command, .shift], event.characters == "n" {
			print("Shortcut fired!")
			NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)!.play()
			Accessibility.speak("NSEvent")
			return true
		} else {
			return false
		}
	}
	
}
