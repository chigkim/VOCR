//
//  Shortcuts.swift
//  FloTools
//
//  Created by Chi Kim on 2/3/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

struct NavigationShortcuts {
	
	let right = HotKey(key:.rightArrow, modifiers:[.command,.control])
	let left = HotKey(key:.leftArrow, modifiers:[.command,.control])
	let up = HotKey(key:.upArrow, modifiers:[.command,.control])
	let down = HotKey(key:.downArrow, modifiers:[.command,.control])
	let nextCharacter = HotKey(key:.rightArrow, modifiers:[.command,.shift,.control])
	let previousCharacter = HotKey(key:.leftArrow, modifiers:[.command,.shift,.control])
	let location = HotKey(key:.l, modifiers:[.command,.control])
	let exit = HotKey(key:.escape, modifiers:[])
	
	init() {
		location.keyDownHandler = {
			Navigation.shared.location()
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
