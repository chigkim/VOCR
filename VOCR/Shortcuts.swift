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
    var modifiers: UInt32
    var keyName: String
}

enum Shortcuts {

    static var handlers: [String: () -> Void] = [:]
    static var hotkeys: [HotKey] = []
    static var shortcuts: [Shortcut] = []
    static var navigationActive = false
    static let globalShortcuts = [
        NSLocalizedString("shortcut.settings", value: "Settings", comment: "Shortcut name for opening settings menu"),
        NSLocalizedString("shortcut.ocr_window", value: "OCR Window", comment: "Shortcut name for OCR window capture"),
        NSLocalizedString("shortcut.ocr_vocursor", value: "OCR VOCursor", comment: "Shortcut name for OCR at VoiceOver cursor"),
        NSLocalizedString("shortcut.capture_camera", value: "Capture Camera", comment: "Shortcut name for capturing from camera"),
        NSLocalizedString("shortcut.realtime_ocr", value: "Realtime OCR", comment: "Shortcut name for starting/stopping realtime OCR"),
        NSLocalizedString("shortcut.ask", value: "Ask", comment: "Shortcut name for asking questions"),
        NSLocalizedString("shortcut.explore", value: "Explore", comment: "Shortcut name for exploring content"),
    ]
    static let navigationShortcuts = [
        NSLocalizedString("shortcut.right", value: "Right", comment: "Shortcut name for moving right in navigation"),
        NSLocalizedString("shortcut.left", value: "Left", comment: "Shortcut name for moving left in navigation"),
        NSLocalizedString("shortcut.down", value: "Down", comment: "Shortcut name for moving down in navigation"),
        NSLocalizedString("shortcut.up", value: "Up", comment: "Shortcut name for moving up in navigation"),
        NSLocalizedString("shortcut.beginning", value: "Beginning", comment: "Shortcut name for jumping to beginning"),
        NSLocalizedString("shortcut.end", value: "End", comment: "Shortcut name for jumping to end"),
        NSLocalizedString("shortcut.top", value: "Top", comment: "Shortcut name for jumping to top"),
        NSLocalizedString("shortcut.bottom", value: "Bottom", comment: "Shortcut name for jumping to bottom"),
        NSLocalizedString("shortcut.next_character", value: "Next Character", comment: "Shortcut name for moving to next character"),
        NSLocalizedString("shortcut.previous_character", value: "Previous Character", comment: "Shortcut name for moving to previous character"),
        NSLocalizedString("shortcut.report_location", value: "Report Location", comment: "Shortcut name for reporting current location"),
        NSLocalizedString("shortcut.identify_object", value: "Identify Object", comment: "Shortcut name for identifying object"),
        NSLocalizedString("shortcut.find_text", value: "Find Text", comment: "Shortcut name for finding text"),
        NSLocalizedString("shortcut.find_next", value: "Find Next", comment: "Shortcut name for finding next occurrence"),
        NSLocalizedString("shortcut.find_previous", value: "Find Previous", comment: "Shortcut name for finding previous occurrence"),
        NSLocalizedString("shortcut.exit_navigation", value: "Exit Navigation", comment: "Shortcut name for exiting navigation mode"),
    ]
    static let allShortcuts = globalShortcuts + navigationShortcuts

    static func SetupShortcuts() {
        handlers[NSLocalizedString("shortcut.settings", value: "Settings", comment: "Shortcut name for opening settings menu")] = settingsHandler
        handlers[NSLocalizedString("shortcut.ocr_window", value: "OCR Window", comment: "Shortcut name for OCR window capture")] = {
            Navigation.mode = .WINDOW
            Navigation.startOCR()
        }
        handlers[NSLocalizedString("shortcut.ocr_vocursor", value: "OCR VOCursor", comment: "Shortcut name for OCR at VoiceOver cursor")] = {
            if !Accessibility.isVoiceOverRunning() {
                return
            }
            Navigation.mode = .VOCURSOR
            Navigation.startOCR()
        }
        handlers[NSLocalizedString("shortcut.capture_camera", value: "Capture Camera", comment: "Shortcut name for capturing from camera")] = {
            if MacCamera.shared.isCameraAllowed() {
                MacCamera.shared.takePicture()
            }
        }
        handlers[NSLocalizedString("shortcut.realtime_ocr", value: "Realtime OCR", comment: "Shortcut name for starting/stopping realtime OCR")] = realTimeHandler
        handlers[NSLocalizedString("shortcut.explore", value: "Explore", comment: "Shortcut name for exploring content")] = Navigation.explore
        handlers[NSLocalizedString("shortcut.ask", value: "Ask", comment: "Shortcut name for asking questions")] = {
            ask()
        }
        handlers[NSLocalizedString("shortcut.report_location", value: "Report Location", comment: "Shortcut name for reporting current location")] = Navigation.location
        handlers[NSLocalizedString("shortcut.identify_object", value: "Identify Object", comment: "Shortcut name for identifying object")] = Navigation.identifyObject
        handlers[NSLocalizedString("shortcut.right", value: "Right", comment: "Shortcut name for moving right in navigation")] = Navigation.right
        handlers[NSLocalizedString("shortcut.left", value: "Left", comment: "Shortcut name for moving left in navigation")] = Navigation.left
        handlers[NSLocalizedString("shortcut.up", value: "Up", comment: "Shortcut name for moving up in navigation")] = Navigation.up
        handlers[NSLocalizedString("shortcut.down", value: "Down", comment: "Shortcut name for moving down in navigation")] = Navigation.down
        handlers[NSLocalizedString("shortcut.top", value: "Top", comment: "Shortcut name for jumping to top")] = Navigation.top
        handlers[NSLocalizedString("shortcut.bottom", value: "Bottom", comment: "Shortcut name for jumping to bottom")] = Navigation.bottom
        handlers[NSLocalizedString("shortcut.beginning", value: "Beginning", comment: "Shortcut name for jumping to beginning")] = Navigation.beginning
        handlers[NSLocalizedString("shortcut.end", value: "End", comment: "Shortcut name for jumping to end")] = Navigation.end
        handlers[NSLocalizedString("shortcut.next_character", value: "Next Character", comment: "Shortcut name for moving to next character")] = Navigation.nextCharacter
        handlers[NSLocalizedString("shortcut.previous_character", value: "Previous Character", comment: "Shortcut name for moving to previous character")] = Navigation.previousCharacter
        handlers[NSLocalizedString("shortcut.find_text", value: "Find Text", comment: "Shortcut name for finding text")] = OCRTextSearch.shared.showSearchDialog
        handlers[NSLocalizedString("shortcut.find_next", value: "Find Next", comment: "Shortcut name for finding next occurrence")] = {
            OCRTextSearch.shared.search(fromBeginning: false, backward: false)
        }
        handlers[NSLocalizedString("shortcut.find_previous", value: "Find Previous", comment: "Shortcut name for finding previous occurrence")] = {
            OCRTextSearch.shared.search(fromBeginning: false, backward: true)
        }
        handlers[NSLocalizedString("shortcut.exit_navigation", value: "Exit Navigation", comment: "Shortcut name for exiting navigation mode")] = {
            Accessibility.speak(NSLocalizedString("navigation.exit", value: "Exit VOCR navigation.", comment: "Message announced when exiting navigation mode"))
            deactivateNavigationShortcuts()
        }

        loadShortcuts()
    }

    static func getDefaults() -> Data? {
        var data: Data?
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
            var userShortcuts = try? JSONDecoder().decode([Shortcut].self, from: userData)
        {
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
            let mergedShortcuts = merge()
        {
            shortcuts = mergedShortcuts
            for shortcut in shortcuts {
                log("\(shortcut.name), \(shortcut.keyName), \(shortcut.modifiers), \(shortcut.key)")
            }
            registerAll()
        }
    }

    static func registerAll() {
        hotkeys.removeAll()
        register(names: globalShortcuts)
        if navigationActive {
            register(names: navigationShortcuts)
        }
    }

    static func register(names: [String]) {
        for shortcut in shortcuts {
            if names.contains(shortcut.name) {
                let hotkey = HotKey(
                    carbonKeyCode: shortcut.key, carbonModifiers: shortcut.modifiers)
                hotkey.keyDownHandler = handlers[shortcut.name]
                hotkeys.append(hotkey)
            }
        }
    }

    static func deregister(names: [String]) {
        for shortcut in shortcuts {
            if names.contains(shortcut.name) {
                let kc = KeyCombo(carbonKeyCode: shortcut.key, carbonModifiers: shortcut.modifiers)
                hotkeys.removeAll { ($0.keyCombo == kc) }
            }
        }
    }

    static func deactivateNavigationShortcuts() {
        navigationActive = false
        deregister(names: navigationShortcuts)
    }

    static func activateNavigationShortcuts() {
        navigationActive = true
        register(names: navigationShortcuts)
    }

    static func settingsHandler() {
        let mouseLocation = NSEvent.mouseLocation
        let rect = CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 1)
        Settings.setupMenu().popUp(positioning: nil, at: rect.origin, in: nil)
    }
    static func realTimeHandler() {
        if RealTime.run {
            Accessibility.speakWithSynthesizer(NSLocalizedString("message.realtime_ocr_stopping", value: "Stopping RealTime OCR.", comment: "Message announced when stopping realtime OCR"))
            RealTime.run = false
        } else {
            Accessibility.speakWithSynthesizer(NSLocalizedString("message.realtime_ocr_started", value: "RealTime OCR started.", comment: "Message announced when starting realtime OCR"))
            RealTime.run = true
            RealTime.continuousOCR()
        }

    }
}
