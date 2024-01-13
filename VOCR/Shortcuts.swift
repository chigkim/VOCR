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

struct Shortcuts {
	
	static var handlers: [String: () -> Void] = [:]
	static var hotkeys:[HotKey] = []
	static var shortcuts: [Shortcut] = []
	static var navigationActive = false
	static let globalShortcuts = ["Settings", "OCR Window", "OCR VoCursor", "Explore Window with GPT", "Ask GPT about VOCursor", "Realtime OCR VOCursor"]
	static let navigationShortcuts = ["Right", "Left", "Down", "Up", "Beginning", "End", "Top", "Bottom", "Next Character", "Previous Character", "Report Location", "Identify Object", "Exit Navigation"]

	static func SetupShortcuts() {
		handlers["Settings"] = settingsHandler
		handlers["OCR Window"] = windowHandler
		handlers["Explore Window with GPT"] = exploreHandler
		handlers["Ask GPT about VOCursor"] = askHandler
		handlers["OCR VoCursor"] = voHandler
		handlers["Realtime OCR VOCursor"] = realTimeHandler
		handlers["Report Location"] = Navigation.shared.location
		handlers["Identify Object"]  = Navigation.shared.identifyObject
		handlers["Right"] = Navigation.shared.right
		handlers["Left"] = Navigation.shared.left
		handlers["Up"] = Navigation.shared.up
		handlers["Down"] = Navigation.shared.down
		handlers["Top"] = Navigation.shared.top
		handlers["Bottom"] = Navigation.shared.bottom
		handlers["Beginning"] = Navigation.shared.beginning
		handlers["End"] = Navigation.shared.end
		handlers["Next Character"] = Navigation.shared.nextCharacter
		handlers["Previous Character"] = Navigation.shared.previousCharacter
		handlers["Exit Navigation"] = {
			Accessibility.speak("Exit VOCR navigation.")
			deactivateNavigationShortcuts()
		}

		loadShortcuts()
		register(names:globalShortcuts)
	}

	static func loadShortcuts() {
//		UserDefaults.standard.removeObject(forKey: "userShortcuts")
		if UserDefaults.standard.data(forKey: "userShortcuts") == nil {
			let bundle = Bundle.main
			if let bundlePath = bundle.path(forResource: "Shortcuts", ofType: "json") {
				let data = try! Data(contentsOf: URL(fileURLWithPath: bundlePath))
				UserDefaults.standard.set(data, forKey: "userShortcuts")
			}
		}

		if let data = UserDefaults.standard.data(forKey: "userShortcuts"),
			   let decodedShortcuts = try? JSONDecoder().decode([Shortcut].self, from: data) {
			debugPrint(String(data: data, encoding: .utf8))
			shortcuts = decodedShortcuts
			for shortcut in shortcuts {
				debugPrint(shortcut.name, shortcut.keyName, shortcut.modifiers, shortcut.key)
			}
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
				debugPrint("Registering \(shortcut.name) \(shortcut.keyName)")
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
		debugPrint("ok")
		navigationActive = false
		deregister(names:navigationShortcuts)
	}

	static func activateNavigationShortcuts() {
		debugPrint("ok")
		navigationActive = true
		register(names:navigationShortcuts)
	}

	static func settingsHandler() {
		   let mouseLocation = NSEvent.mouseLocation
		   let rect = CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 1)
		   Settings.setupMenu().popUp(positioning: nil, at: rect.origin, in: nil)
	   }

	   static func windowHandler() {
		   Navigation.shared.prepare(mode:"OCR")
	   }

	   static func exploreHandler() {
		   Navigation.shared.prepare(mode:"Explore")
	   }

	   static func voHandler() {
		   recognizeVOCursor(mode: "OCR")
	   }

	   static func askHandler() {
		   recognizeVOCursor(mode:"GPT")
	   }

	   static func realTimeHandler() {
		   RealTime.continuousOCR()
	   }



}

