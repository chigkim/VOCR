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
    // "name" stores the stable shortcut id (e.g., "shortcut.settings"), not the localized label.
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
    struct Definition {
        let id: String
        let defaultName: String
        let isNavigation: Bool
        let comment: String
    }

    static let definitions: [Definition] = [
        Definition(
            id: "shortcut.settings", defaultName: "Settings", isNavigation: false,
            comment: "Shortcut name for opening settings menu"),
        Definition(
            id: "shortcut.ocr_window", defaultName: "OCR Window", isNavigation: false,
            comment: "Shortcut name for OCR window capture"),
        Definition(
            id: "shortcut.ocr_vocursor", defaultName: "OCR VOCursor", isNavigation: false,
            comment: "Shortcut name for OCR at VoiceOver cursor"),
        Definition(
            id: "shortcut.capture_camera", defaultName: "Capture Camera", isNavigation: false,
            comment: "Shortcut name for capturing from camera"),
        Definition(
            id: "shortcut.realtime_ocr", defaultName: "Realtime OCR", isNavigation: false,
            comment: "Shortcut name for starting/stopping realtime OCR"),
        Definition(
            id: "shortcut.ask", defaultName: "Ask", isNavigation: false,
            comment: "Shortcut name for asking questions"),
        Definition(
            id: "shortcut.explore", defaultName: "Explore", isNavigation: false,
            comment: "Shortcut name for exploring content"),
        Definition(
            id: "shortcut.right", defaultName: "Right", isNavigation: true,
            comment: "Shortcut name for moving right in navigation"),
        Definition(
            id: "shortcut.left", defaultName: "Left", isNavigation: true,
            comment: "Shortcut name for moving left in navigation"),
        Definition(
            id: "shortcut.down", defaultName: "Down", isNavigation: true,
            comment: "Shortcut name for moving down in navigation"),
        Definition(
            id: "shortcut.up", defaultName: "Up", isNavigation: true,
            comment: "Shortcut name for moving up in navigation"),
        Definition(
            id: "shortcut.beginning", defaultName: "Beginning", isNavigation: true,
            comment: "Shortcut name for jumping to beginning"),
        Definition(
            id: "shortcut.end", defaultName: "End", isNavigation: true,
            comment: "Shortcut name for jumping to end"),
        Definition(
            id: "shortcut.top", defaultName: "Top", isNavigation: true,
            comment: "Shortcut name for jumping to top"),
        Definition(
            id: "shortcut.bottom", defaultName: "Bottom", isNavigation: true,
            comment: "Shortcut name for jumping to bottom"),
        Definition(
            id: "shortcut.next_character", defaultName: "Next Character", isNavigation: true,
            comment: "Shortcut name for moving to next character"),
        Definition(
            id: "shortcut.previous_character", defaultName: "Previous Character",
            isNavigation: true, comment: "Shortcut name for moving to previous character"),
        Definition(
            id: "shortcut.report_location", defaultName: "Report Location", isNavigation: true,
            comment: "Shortcut name for reporting current location"),
        Definition(
            id: "shortcut.identify_object", defaultName: "Identify Object", isNavigation: true,
            comment: "Shortcut name for identifying object"),
        Definition(
            id: "shortcut.find_text", defaultName: "Find Text", isNavigation: true,
            comment: "Shortcut name for finding text"),
        Definition(
            id: "shortcut.find_next", defaultName: "Find Next", isNavigation: true,
            comment: "Shortcut name for finding next occurrence"),
        Definition(
            id: "shortcut.find_previous", defaultName: "Find Previous", isNavigation: true,
            comment: "Shortcut name for finding previous occurrence"),
        Definition(
            id: "shortcut.exit_navigation", defaultName: "Exit Navigation", isNavigation: true,
            comment: "Shortcut name for exiting navigation mode"),
    ]

    static let globalShortcuts = definitions.filter { !$0.isNavigation }.map { $0.id }
    static let navigationShortcuts = definitions.filter { $0.isNavigation }.map { $0.id }
    static let allShortcuts = globalShortcuts + navigationShortcuts

    static func SetupShortcuts() {
        handlers["shortcut.settings"] = settingsHandler
        handlers["shortcut.ocr_window"] = {
            Navigation.mode = .WINDOW
            Navigation.startOCR()
        }
        handlers["shortcut.ocr_vocursor"] = {
            if !Accessibility.isVoiceOverRunning() {
                return
            }
            Navigation.mode = .VOCURSOR
            Navigation.startOCR()
        }
        handlers["shortcut.capture_camera"] = {
            if MacCamera.shared.isCameraAllowed() {
                MacCamera.shared.takePicture()
            }
        }
        handlers["shortcut.realtime_ocr"] = realTimeHandler
        handlers["shortcut.explore"] = Navigation.explore
        handlers["shortcut.ask"] = {
            ask()
        }
        handlers["shortcut.report_location"] = Navigation.location
        handlers["shortcut.identify_object"] = Navigation.identifyObject
        handlers["shortcut.right"] = Navigation.right
        handlers["shortcut.left"] = Navigation.left
        handlers["shortcut.up"] = Navigation.up
        handlers["shortcut.down"] = Navigation.down
        handlers["shortcut.top"] = Navigation.top
        handlers["shortcut.bottom"] = Navigation.bottom
        handlers["shortcut.beginning"] = Navigation.beginning
        handlers["shortcut.end"] = Navigation.end
        handlers["shortcut.next_character"] = Navigation.nextCharacter
        handlers["shortcut.previous_character"] = Navigation.previousCharacter
        handlers["shortcut.find_text"] = OCRTextSearch.shared.showSearchDialog
        handlers["shortcut.find_next"] = {
            OCRTextSearch.shared.search(fromBeginning: false, backward: false)
        }
        handlers["shortcut.find_previous"] = {
            OCRTextSearch.shared.search(fromBeginning: false, backward: true)
        }
        handlers["shortcut.exit_navigation"] = {
            Accessibility.speak(
                NSLocalizedString(
                    "navigation.exit", value: "Exit VOCR navigation.",
                    comment: "Message announced when exiting navigation mode"))
            deactivateNavigationShortcuts()
        }

        loadShortcuts()
    }

    static func localizedName(for id: String) -> String {
        if let def = definitions.first(where: { $0.id == id }) {
            return NSLocalizedString(def.id, value: def.defaultName, comment: def.comment)
        }
        return id
    }

    private static func nameToIDMap() -> [String: String] {
        var map: [String: String] = [:]
        var bundles: [Bundle] = [Bundle.main]

        for localization in Bundle.main.localizations {
            if let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
                let bundle = Bundle(path: path)
            {
                bundles.append(bundle)
            }
        }

        for def in definitions {
            map[def.id] = def.id
            map[def.defaultName] = def.id
            for bundle in bundles {
                let localized = bundle.localizedString(
                    forKey: def.id, value: def.defaultName, table: nil)
                map[localized] = def.id
            }
        }
        return map
    }

    private static func normalize(_ shortcut: Shortcut, nameMap: [String: String]) -> Shortcut {
        var updated = shortcut
        if let mapped = nameMap[shortcut.name] {
            updated.name = mapped
        }
        return updated
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
            let nameMap = nameToIDMap()
            let normalizedDefaults = defaultShortcuts.map { normalize($0, nameMap: nameMap) }
            userShortcuts = userShortcuts.map { normalize($0, nameMap: nameMap) }

            for shortcut in normalizedDefaults {
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

        if let mergedShortcuts = merge() {
            let nameMap = nameToIDMap()
            shortcuts = mergedShortcuts.map { normalize($0, nameMap: nameMap) }
            if let normalizedData = try? JSONEncoder().encode(shortcuts) {
                UserDefaults.standard.set(normalizedData, forKey: "userShortcuts")
            }
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
            Accessibility.speakWithSynthesizer(
                NSLocalizedString(
                    "message.realtime_ocr_stopping", value: "Stopping RealTime OCR.",
                    comment: "Message announced when stopping realtime OCR"))
            RealTime.run = false
        } else {
            Accessibility.speakWithSynthesizer(
                NSLocalizedString(
                    "message.realtime_ocr_started", value: "RealTime OCR started.",
                    comment: "Message announced when starting realtime OCR"))
            RealTime.run = true
            RealTime.continuousOCR()
        }

    }
}
