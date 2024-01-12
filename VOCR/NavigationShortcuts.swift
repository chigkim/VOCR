//
//  Shortcuts.swift
//  FloTools
//
//  Created by Chi Kim on 2/3/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa
import HotKey

struct NavigationShortcuts {
	
	let right = HotKey(key:.rightArrow, modifiers:[.command,.control])
	let left = HotKey(key:.leftArrow, modifiers:[.command,.control])
	let up = HotKey(key:.upArrow, modifiers:[.command,.control])
	let down = HotKey(key:.downArrow, modifiers:[.command,.control])
	let top = HotKey(key:.pageUp, modifiers:[.command,.control])
	let bottom = HotKey(key:.pageDown, modifiers:[.command,.control])
	let beginning = HotKey(key:.home, modifiers:[.command,.control])
	let end = HotKey(key:.end, modifiers:[.command,.control])
	let nextCharacter = HotKey(key:.rightArrow, modifiers:[.command,.shift,.control])
	let previousCharacter = HotKey(key:.leftArrow, modifiers:[.command,.shift,.control])
	let location = HotKey(key:.l, modifiers:[.command,.control])
	let identify = HotKey(key:.i, modifiers:[.command,.control])
	let exit = HotKey(key:.escape, modifiers:[])

	init() {
		location.keyDownHandler = {
			Navigation.shared.location()
		}
		identify.keyDownHandler = {
			Navigation.shared.identifyObject()
		}

		right.keyDownHandler = {
			Navigation.shared.right()
		}
		
		left.keyDownHandler = {
			Navigation.shared.left()
		}
		
		up.keyDownHandler = {
			Navigation.shared.up()
		}
		
		down.keyDownHandler = {
			Navigation.shared.down()
		}
		
		top.keyDownHandler = {
			Navigation.shared.top()
		}
		
		bottom.keyDownHandler = {
			Navigation.shared.bottom()
		}
		
		beginning.keyDownHandler = {
			Navigation.shared.beginning()
		}
		
		end.keyDownHandler = {
			Navigation.shared.end()
		}
		
		nextCharacter.keyDownHandler = {
			Navigation.shared.nextCharacter()
		}
		
		previousCharacter.keyDownHandler = {
			Navigation.shared.previousCharacter()
		}
		
		exit.keyDownHandler = {
			Accessibility.speak("Exit VOCR navigation.")
			Navigation.shared.navigationShortcuts = nil
		}
		
	}
	
}

