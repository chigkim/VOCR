//
//  Shortcut.swift
//  VOCR
//
//  Created by Chi Kim on 1/11/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Cocoa
import Carbon.HIToolbox.Events  // Import this to use Carbon keycodes

struct Shortcut: Codable {
	var name: String
	var key: UInt32
	var modifiers:UInt32
	var keyName:String {
		get {
		if let event = createKeyEvent(keyCode: key, keyModifiers: modifiers) {
			return event.modifierFlags.description+event.charactersIgnoringModifiers!
		} else {
			return "Unassigned"
		}
		}
	}


}
