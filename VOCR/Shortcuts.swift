//
//  Shortcuts.swift
//  VOCR
//
//  Created by Chi Kim on 1/12/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Cocoa
import HotKey

struct Shortcut: Codable {
	var name: String
	var key: UInt32
	var modifiers:UInt32
	var keyName:String
}

enum Shortcuts {
	
	static var handlers: [String: () -> Void] = [:]
	static var hotkeys:[HotKey] = []
	static var shortcuts: [Shortcut] = []
	static var navigationActive = false
	static let globalShortcuts = ["Settings", "OCR Window", "OCR VOCursor", "Realtime OCR", "Ask", "Explore"]
	static let navigationShortcuts = ["Right", "Left", "Down", "Up", "Beginning", "End", "Top", "Bottom", "Next Character", "Previous Character", "Report Location", "Identify Object", "Exit Navigation"]
	static let allShortcuts = globalShortcuts+navigationShortcuts

	static func SetupShortcuts() {
		handlers["Settings"] = settingsHandler
		handlers["OCR Window"] = {
			Navigation.mode = .WINDOW
			Navigation.startOCR()
		}
		handlers["OCR VOCursor"] = {
			Navigation.mode = .VOCURSOR
			Navigation.startOCR()
		}
		handlers["Realtime OCR"] = RealTime.continuousOCR
		handlers["Explore"] = Navigation.explore
		handlers["Ask"] = {
			ask()
		}
		handlers["Report Location"] = Navigation.location
		handlers["Identify Object"]  = Navigation.identifyObject
		handlers["Right"] = Navigation.right
		handlers["Left"] = Navigation.left
		handlers["Up"] = Navigation.up
		handlers["Down"] = Navigation.down
		handlers["Top"] = Navigation.top
		handlers["Bottom"] = Navigation.bottom
		handlers["Beginning"] = Navigation.beginning
		handlers["End"] = Navigation.end
		handlers["Next Character"] = Navigation.nextCharacter
		handlers["Previous Character"] = Navigation.previousCharacter
		handlers["Exit Navigation"] = {
			Accessibility.speak("Exit VOCR navigation.")
			deactivateNavigationShortcuts()
		}

		loadShortcuts()
	}

	static func loadDefaults() {
		let bundle = Bundle.main
		if let bundlePath = bundle.path(forResource: "Shortcuts", ofType: "json") {
			let data = try! Data(contentsOf: URL(fileURLWithPath: bundlePath))
			UserDefaults.standard.removeObject(forKey: "userShortcuts")
			UserDefaults.standard.set(data, forKey: "userShortcuts")
		}
	}

	static func loadShortcuts() {
		if UserDefaults.standard.data(forKey: "userShortcuts") == nil {
loadDefaults()
		}

		if let data = UserDefaults.standard.data(forKey: "userShortcuts"),
			   let decodedShortcuts = try? JSONDecoder().decode([Shortcut].self, from: data) {
			shortcuts = decodedShortcuts
			for shortcut in shortcuts {
				debugPrint(shortcut.name, shortcut.keyName, shortcut.modifiers, shortcut.key)
				if !allShortcuts.contains(shortcut.name) {
					Accessibility.speakWithSynthesizer("Resetting shortcuts.")
					loadDefaults()
					loadShortcuts()
					break
				}
			}
			registerAll()
		}
	}

	static func registerAll() {
		hotkeys.removeAll()
		register(names:globalShortcuts)
		if navigationActive {
			register(names:navigationShortcuts)
		}
	}

	static func register(names:[String]) {
		for shortcut in shortcuts {
			if names.contains(shortcut.name) {
				let hotkey = HotKey(carbonKeyCode:shortcut.key, carbonModifiers:shortcut.modifiers)
				hotkey.keyDownHandler = handlers[shortcut.name]
				hotkeys.append(hotkey)
			}
		}
	}
	
	static func deregister(names:[String]) {
		for shortcut in shortcuts {
			if names.contains(shortcut.name) {
				let kc = KeyCombo(carbonKeyCode: shortcut.key, carbonModifiers: shortcut.modifiers)
				hotkeys.removeAll { ($0.keyCombo == kc) }
			}
		}
	}

	static func deactivateNavigationShortcuts() {
		navigationActive = false
		deregister(names:navigationShortcuts)
	}

	static func activateNavigationShortcuts() {
		navigationActive = true
		register(names:navigationShortcuts)
	}

	static func settingsHandler() {
		   let mouseLocation = NSEvent.mouseLocation
		   let rect = CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 1)
		   Settings.setupMenu().popUp(positioning: nil, at: rect.origin, in: nil)
	   }

}

