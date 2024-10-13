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
	static let globalShortcuts = ["Settings", "OCR Window", "OCR VOCursor", "Capture Camera", "Realtime OCR", "Ask", "Explore"]
	static let navigationShortcuts = ["Right", "Left", "Down", "Up", "Beginning", "End", "Top", "Bottom", "Next Character", "Previous Character", "Report Location", "Identify Object", "Find Text", "Find Next", "Find Previous", "Exit Navigation"]
	static let allShortcuts = globalShortcuts+navigationShortcuts
	
	static func SetupShortcuts() {
		handlers["Settings"] = settingsHandler
		handlers["OCR Window"] = {
			Navigation.mode = .WINDOW
			Navigation.startOCR()
		}
		handlers["OCR VOCursor"] = {
			if !Accessibility.isVoiceOverRunning() {
				return
			}
			Navigation.mode = .VOCURSOR
			Navigation.startOCR()
		}
		handlers["Capture Camera"] = {
			if MacCamera.shared.isCameraAllowed() {
				MacCamera.shared.takePicture()
			}
		}
		handlers["Realtime OCR"] = realTimeHandler
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
		handlers["Find Text"] = OCRTextSearch.shared.showSearchDialog
		handlers["Find Next"] = {
			OCRTextSearch.shared.search(fromBeginning: false, backward: false)
		}
		handlers["Find Previous"] = {
			OCRTextSearch.shared.search(fromBeginning: false, backward: true)
		}
		handlers["Exit Navigation"] = {
			Accessibility.speak("Exit VOCR navigation.")
			deactivateNavigationShortcuts()
		}
		
		loadShortcuts()
	}
	
	static func getDefaults() -> Data? {
		var data:Data?
		let bundle = Bundle.main
		if let bundlePath = bundle.path(forResource: "Shortcuts", ofType: "json") {
			data = try! Data(contentsOf: URL(fileURLWithPath: bundlePath))
		}
		return data
	}
	
	static func loadDefaults() {
		if let data = getDefaults() {
			UserDefaults.standard.removeObject(forKey: "userShortcuts")
			UserDefaults.standard.set(data, forKey: "userShortcuts")
		}
	}
	
	static func merge() -> [Shortcut]? {
		if let defaultData = getDefaults(),
			let defaultShortcuts = try? JSONDecoder().decode([Shortcut].self, from: defaultData),
			let userData = UserDefaults.standard.data(forKey: "userShortcuts"),
			var userShortcuts = try? JSONDecoder().decode([Shortcut].self, from: userData) {
			for shortcut in defaultShortcuts {
				if !userShortcuts.contains(where: { $0.name == shortcut.name }) {
					userShortcuts.append(shortcut)
				   }
			   }

			   if let mergedData = try? JSONEncoder().encode(userShortcuts) {
				   UserDefaults.standard.set(mergedData, forKey: "userShortcuts")
			   }
			   return userShortcuts
		   }
		return nil
	}

	static func loadShortcuts() {
		if UserDefaults.standard.data(forKey: "userShortcuts") == nil {
loadDefaults()
		}

		if let data = UserDefaults.standard.data(forKey: "userShortcuts"),
			let mergedShortcuts = merge() {
			shortcuts = mergedShortcuts
			for shortcut in shortcuts {
				log("\(shortcut.name), \(shortcut.keyName), \(shortcut.modifiers), \(shortcut.key)")
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
	static func realTimeHandler() {
		if RealTime.run {
			Accessibility.speakWithSynthesizer("Stopping RealTime OCR.")
			RealTime.run = false
		} else {
			Accessibility.speakWithSynthesizer("RealTime OCR started.")
			RealTime.run = true
			RealTime.continuousOCR()
		}
			
	}
}

