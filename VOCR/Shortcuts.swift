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
			Shortcuts.deactivateNavigationShortcuts()
		}

		loadShortcuts()
		register()
	}

	static func loadShortcuts() {
		if let data = UserDefaults.standard.data(forKey: "userShortcuts"),
		   let decodedShortcuts = try? JSONDecoder().decode([Shortcut].self, from: data) {
			debugPrint(String(data: data, encoding: .utf8))
			Shortcuts.shortcuts = decodedShortcuts
			for shortcut in shortcuts {
				debugPrint(shortcut.name, shortcut.keyName, shortcut.modifiers, shortcut.key)
			}
		}
	}

	static func register() {
		deregister()
		for shortcut in shortcuts {
			if !Shortcuts.navigationActive && navigationShortcuts.contains(shortcut.name) {
				continue
			}
			let hotkey = HotKey(carbonKeyCode:shortcut.key, carbonModifiers:shortcut.modifiers)
			hotkey.keyDownHandler = handlers[shortcut.name]
			Shortcuts.hotkeys.append(hotkey)
			debugPrint("Registering \(shortcut.name) \(shortcut.keyName)")
		}
	}
	
	static func deregister() {
		hotkeys.removeAll()
	}

	static func deactivateNavigationShortcuts() {
		debugPrint("ok")
		Shortcuts.navigationActive = false
		register()
	}

	static func activateNavigationShortcuts() {
		debugPrint("ok")
		Shortcuts.navigationActive = true
		register()
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

