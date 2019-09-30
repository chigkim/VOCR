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
	let picture = HotKey(key:.p, modifiers:[.command,.shift])
	let right = HotKey(key:.rightArrow, modifiers:[.command,.shift])
	let left = HotKey(key:.leftArrow, modifiers:[.command,.shift])
	let up = HotKey(key:.upArrow, modifiers:[.command,.shift])
	let down = HotKey(key:.downArrow, modifiers:[.command,.shift])
	let nextCharacter = HotKey(key:.rightArrow, modifiers:[.command,.shift,.option])
	let previousCharacter = HotKey(key:.leftArrow, modifiers:[.command,.shift,.option])
	let location = HotKey(key:.l, modifiers:[.command,.shift])
	let test = HotKey(key:.t, modifiers:[.command,.shift])

	init() {
		test.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
		Accessibility.notify("Ready")
		}


		start.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.start()
		}

		picture.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.takePicture()
		}

		location.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.location()
		}

		right.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.right()
		}
		
		left.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.left()
		}
		
		up.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.up()
		}
		
		down.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.down()
		}

		nextCharacter.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.nextCharacter()
		}

		previousCharacter.keyDownHandler = {
			let app = NSApplication.shared.delegate as! AppDelegate
			app.previousCharacter()
		}

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
