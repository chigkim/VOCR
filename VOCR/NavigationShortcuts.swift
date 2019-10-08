//
//  Shortcuts.swift
//  FloTools
//
//  Created by Chi Kim on 2/3/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Foundation
import Cocoa


class NavigationShortcuts {
	
	let right = HotKey(key:.rightArrow, modifiers:[.command,.shift])
	let left = HotKey(key:.leftArrow, modifiers:[.command,.shift])
	let up = HotKey(key:.upArrow, modifiers:[.command,.shift])
	let down = HotKey(key:.downArrow, modifiers:[.command,.shift])
	let nextCharacter = HotKey(key:.rightArrow, modifiers:[.command,.shift,.option])
	let previousCharacter = HotKey(key:.leftArrow, modifiers:[.command,.shift,.option])
	let location = HotKey(key:.l, modifiers:[.command,.shift])
	let exit = HotKey(key:.escape, modifiers:[])
	
	init() {
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
		
		exit.keyDownHandler = {
			Accessibility.speak("Exit navigation.")
			let app = NSApplication.shared.delegate as! AppDelegate
			app.navigationShortcuts = nil
		}
		
	}
	
}
