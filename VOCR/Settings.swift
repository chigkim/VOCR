//
//  Settings.swift
//  VOCR
//
//  Created by Chi Kim on 10/14/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import AVFoundation
import AudioKit
import Cocoa

enum Settings {

    static private var eventMonitor: Any?
    static var positionReset = true
    static var positionalAudio = false
    static var moveMouse = true
    static var launchOnBoot = true
    static var autoScan = false
    static var targetWindow = false
    static var detectObject = true
    static var windowRealtime = true
    static var usePresetPrompt = false
    static var prompt = "Analyze the image in a comprehensive and detailed manner."
    static var exploreSystemPrompt =
        "You are a helpful assistant. Your response must be valid JSON that matches the provided schema. Your task is to process the image from users by segmenting it into distinct areas with related items. Output a JSON description for each segmented area. Each element should include: 'label' (a concise string name), 'uid' (a unique integer identifier), 'description' (a brief explanation of the area), 'content' (a string with examples of objects within the area), and 'boundingBox' (coordinates with top_left_x, top_left_y, width, height). Ensure the boundingBox coordinates are normalized between 0.0 and 1.0 relative to the image's resolution with the origin at the top left (0.0, 0.0). For example, an object in the top-left corner should have a boundingBox with a y-coordinate close to 0.0 (e.g., {\"top_left_x\": 0.05, \"top_left_y\": 0.05, \"width\": 0.1, \"height\": 0.1}), not 1.0. The response must contain only the JSON output without inline comments or extra notes. Precision in the 'boundingBox' coordinates is crucial; even one minor inaccuracy can have severe and irreversible consequences for users."
    static let exploreResponseSchema: [String: Any] = [
        "name": "explore_response",
        "strict": true,
        "schema": [
            "type": "object",
            "properties": [
                "elements": [
                    "type": "array",
                    "minItems": 1,
                    "items": [
                        "type": "object",
                        "properties": [
                            "label": ["type": "string"],
                            "uid": ["type": "integer"],
                            "description": ["type": "string"],
                            "content": ["type": "string"],
                            "boundingBox": [
                                "type": "object",
                                "properties": [
                                    "top_left_x": ["type": "number"],
                                    "top_left_y": ["type": "number"],
                                    "width": ["type": "number"],
                                    "height": ["type": "number"],
                                ],
                                "required": ["top_left_x", "top_left_y", "width", "height"],
                                "additionalProperties": false,
                            ],
                        ],
                        "required": ["label", "uid", "description", "content", "boundingBox"],
                        "additionalProperties": false,
                    ],
                ]
            ],
            "required": ["elements"],
            "additionalProperties": false,
        ],
    ]
    static var exploreUserPrompt =
        "The resolution of the following image has {image.width} width and {image.height} height."
    static var messages: [[String: Any]] = []
    static var followUp = false
    static let target = MenuHandler()
    static var writeLog = false
    static var preRelease = false
    static var camera = "Unknown"

    static func activePreset() -> (
        name: String,
        url: String,
        model: String,
        apiKey: String,
        presetPrompt: String,
        systemPrompt: String
    )? {
        guard let p = PresetManager.shared.activePresetDecrypted() else {
            return nil
        }
        return (
            name: p.name,
            url: p.url,
            model: p.model,
            apiKey: p.apiKey,
            presetPrompt: p.prompt,
            systemPrompt: p.systemPrompt
        )
    }

    static var allSettings: [(title: String, action: Selector, value: Bool)] {
        return [
            (
                NSLocalizedString(
                    "menu.settings.targetWindow", value: "Target Window",
                    comment: "Menu item for selecting target window"),
                #selector(MenuHandler.toggleSetting(_:)), targetWindow
            ),
            (
                NSLocalizedString(
                    "menu.settings.autoScan", value: "Auto Scan",
                    comment: "Menu item for enabling auto scan on mouse click"),
                #selector(MenuHandler.toggleAutoScan(_:)), autoScan
            ),
            (
                NSLocalizedString(
                    "menu.settings.detectObjects", value: "Detect Objects",
                    comment: "Menu item for enabling object detection"),
                #selector(MenuHandler.toggleSetting(_:)), detectObject
            ),
            (
                NSLocalizedString(
                    "menu.settings.usePresetPrompt", value: "Use Preset Prompt",
                    comment: "Menu item for using preset prompt with AI"),
                #selector(MenuHandler.toggleSetting(_:)), usePresetPrompt
            ),
            (
                NSLocalizedString(
                    "menu.settings.resetPosition", value: "Reset Position on Scan",
                    comment: "Menu item for resetting cursor position after each scan"),
                #selector(MenuHandler.toggleSetting(_:)), positionReset
            ),
            (
                NSLocalizedString(
                    "menu.settings.positionalAudio", value: "Positional Audio",
                    comment: "Menu item for enabling spatial audio feedback"),
                #selector(MenuHandler.toggleSetting(_:)), positionalAudio
            ),
            (
                NSLocalizedString(
                    "menu.settings.moveMouse", value: "Move Mouse",
                    comment: "Menu item for moving mouse cursor during navigation"),
                #selector(MenuHandler.toggleSetting(_:)), moveMouse
            ),
            (
                NSLocalizedString(
                    "menu.settings.launchOnLogin", value: "Launch on Login",
                    comment: "Menu item for launching VOCR on system startup"),
                #selector(MenuHandler.toggleLaunch(_:)), launchOnBoot
            ),
            (
                NSLocalizedString(
                    "menu.settings.log", value: "Log",
                    comment: "Menu item for enabling debug logging"),
                #selector(MenuHandler.toggleLaunch(_:)), writeLog
            ),
        ]
    }

    static func setupMenu() -> NSMenu {
        load()
        let menu = NSMenu()
        let presetsMenu = NSMenu()
        buildPresetsSubmenu(into: presetsMenu)
        let presetsMenuItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.presets", value: "Presets", comment: "Menu item for preset management"),
            action: nil, keyEquivalent: "")
        presetsMenuItem.submenu = presetsMenu
        menu.addItem(presetsMenuItem)

        let settingsMenu = NSMenu()
        for setting in allSettings {
            let menuItem = NSMenuItem(
                title: setting.title, action: setting.action, keyEquivalent: "")
            menuItem.target = target
            menuItem.state = setting.value ? .on : .off
            settingsMenu.addItem(menuItem)
        }

        if Settings.autoScan {
            installMouseMonitor()
        }

        let soundOutputMenuItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.soundOutput", value: "Sound Output...",
                comment: "Menu item for choosing audio output device"),
            action: #selector(target.chooseOutput(_:)), keyEquivalent: "")
        soundOutputMenuItem.target = target
        settingsMenu.addItem(soundOutputMenuItem)

        let cameraMenuItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.chooseCamera", value: "Choose Camera...",
                comment: "Menu item for selecting camera device"),
            action: #selector(target.chooseCamera(_:)), keyEquivalent: ""
        )
        cameraMenuItem.target = target
        settingsMenu.addItem(cameraMenuItem)

        let shortcutsMenuItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.shortcuts", value: "Shortcuts...",
                comment: "Menu item for managing keyboard shortcuts"),
            action: #selector(target.openShortcutsWindow(_:)),
            keyEquivalent: "")
        shortcutsMenuItem.target = target
        settingsMenu.addItem(shortcutsMenuItem)

        let newShortcutMenuItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.newShortcuts", value: "New Shortcuts",
                comment: "Menu item for creating a new keyboard shortcut"),
            action: #selector(target.addShortcut(_:)), keyEquivalent: "")
        newShortcutMenuItem.target = target
        //		settingsMenu.addItem(newShortcutMenuItem)

        let resetMenuItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.reset", value: "Reset...",
                comment: "Menu item for resetting all settings and presets"),
            action: #selector(target.reset(_:)), keyEquivalent: ""
        )
        resetMenuItem.target = target
        settingsMenu.addItem(resetMenuItem)

        let settingsMenuItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.settings", value: "Settings", comment: "Main settings menu item"),
            action: nil, keyEquivalent: "")
        settingsMenuItem.submenu = settingsMenu
        menu.addItem(settingsMenuItem)

        if Navigation.cgImage != nil {
            let saveScreenshotMenuItem = NSMenuItem(
                title: NSLocalizedString(
                    "menu.saveLatestImage", value: "Save Latest Image",
                    comment: "Menu item for saving the most recent captured image"),
                action: #selector(target.saveLastImage(_:)),
                keyEquivalent: "s")
            saveScreenshotMenuItem.target = target
            menu.addItem(saveScreenshotMenuItem)
        }

        if Navigation.displayResults.count > 1 {
            let saveMenuItem = NSMenuItem(
                title: NSLocalizedString(
                    "menu.saveOCRResult", value: "Save OCR Result...",
                    comment: "Menu item for saving OCR text results to file"),
                action: #selector(target.saveResult(_:)),
                keyEquivalent: "")
            saveMenuItem.target = target
            menu.addItem(saveMenuItem)
        }

        let updateMenu = NSMenu()
        let aboutMenuItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.about", value: "About...", comment: "Menu item for displaying About window"),
            action: #selector(target.displayAboutWindow(_:)), keyEquivalent: "")
        aboutMenuItem.target = target
        updateMenu.addItem(aboutMenuItem)

        let checkForUpdatesItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.checkForUpdates", value: "Check for Updates",
                comment: "Menu item for manually checking for software updates"),
            action: #selector(target.checkForUpdates), keyEquivalent: ""
        )
        checkForUpdatesItem.target = target
        updateMenu.addItem(checkForUpdatesItem)

        let autoCheckItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.autoCheckForUpdates", value: "Automatically Check for Updates",
                comment: "Menu item for enabling automatic update checks"),
            action: #selector(target.toggleSetting(_:)),
            keyEquivalent: "")
        autoCheckItem.target = target
        updateMenu.addItem(autoCheckItem)

        let autoUpdateItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.autoInstallUpdates", value: "Automatically Install Updates",
                comment: "Menu item for enabling automatic update installation"),
            action: #selector(target.toggleSetting(_:)),
            keyEquivalent: "")
        autoUpdateItem.target = target
        updateMenu.addItem(autoUpdateItem)

        if let updater = AutoUpdateManager.shared.updaterController?.updater {
            autoCheckItem.state = (updater.automaticallyChecksForUpdates) ? .on : .off
            autoUpdateItem.state = (updater.automaticallyDownloadsUpdates) ? .on : .off
        }

        let preReleaseItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.downloadPreRelease", value: "Download  Pre-release",
                comment: "Menu item for enabling pre-release version downloads"),
            action: #selector(target.toggleSetting(_:)),
            keyEquivalent: ""
        )
        preReleaseItem.target = target
        updateMenu.addItem(preReleaseItem)
        preReleaseItem.state = (Settings.preRelease) ? .on : .off

        let updateMenuItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.updates", value: "Updates", comment: "Updates menu section"), action: nil,
            keyEquivalent: "")
        updateMenuItem.submenu = updateMenu
        menu.addItem(updateMenuItem)

        if Shortcuts.navigationActive {
            let dismissMenuItem = NSMenuItem(
                title: NSLocalizedString(
                    "menu.dismiss", value: "Dismiss Menu",
                    comment: "Menu item for dismissing the menu"),
                action: #selector(target.dismiss(_:)), keyEquivalent: "z")
            dismissMenuItem.target = target
            menu.addItem(dismissMenuItem)
        }

        menu.addItem(
            NSMenuItem(
                title: NSLocalizedString(
                    "menu.quit", value: "Quit", comment: "Menu item for quitting the application"),
                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    private static func buildPresetsSubmenu(into submenu: NSMenu) {
        submenu.removeAllItems()
        let allPresets = PresetManager.shared.presets
        let active = PresetManager.shared.selectedPresetID

        for p in allPresets {
            let chooseItem = NSMenuItem(
                title: p.name,
                action: #selector(MenuHandler.selectPresetFromMenu(_:)),
                keyEquivalent: ""
            )
            chooseItem.target = target
            chooseItem.representedObject = p.id
            chooseItem.state = (p.id == active) ? .on : .off
            submenu.addItem(chooseItem)
        }

        submenu.addItem(NSMenuItem.separator())
        let presetManagerItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.presetManager", value: "Preset Manager…",
                comment: "Menu item for opening preset manager window"),
            action: #selector(MenuHandler.openPresetManagerWindow(_:)),
            keyEquivalent: ""
        )
        presetManagerItem.target = target
        submenu.addItem(presetManagerItem)

        let editExplorePromptsItem = NSMenuItem(
            title: NSLocalizedString(
                "menu.editExplorePrompts", value: "Edit Explore Prompts…",
                comment: "Menu item for editing explore mode prompts"),
            action: #selector(MenuHandler.openEditExplorePrompts(_:)),
            keyEquivalent: ""
        )
        editExplorePromptsItem.target = target
        submenu.addItem(editExplorePromptsItem)

    }

    static func installMouseMonitor() {
        self.eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [NSEvent.EventTypeMask.leftMouseDown, NSEvent.EventTypeMask.rightMouseDown],
            handler: { (event: NSEvent) in
                switch event.type {
                case .leftMouseDown:
                    log("Left mouse click detected.")
                    if Shortcuts.navigationActive {
                        Thread.sleep(forTimeInterval: 0.5)
                        Navigation.startOCR()
                    }
                case .rightMouseDown:
                    log("Right mouse click detected.")
                    if Shortcuts.navigationActive {
                        Thread.sleep(forTimeInterval: 0.5)
                        Navigation.startOCR()
                    }
                default:
                    break
                }
            })
    }

    static func removeMouseMonitor() {
        if let eventMonitor = self.eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    static func load() {
        let defaults = UserDefaults.standard
        Settings.positionReset = defaults.bool(forKey: "positionReset")
        Settings.positionalAudio = defaults.bool(forKey: "positionalAudio")
        Settings.launchOnBoot = defaults.bool(forKey: "launchOnBoot")
        Settings.autoScan = defaults.bool(forKey: "autoScan")
        Settings.detectObject = defaults.bool(forKey: "detectObject")
        Settings.usePresetPrompt = defaults.bool(forKey: "usePresetPrompt")
        Settings.targetWindow = defaults.bool(forKey: "targetWindow")
        Settings.preRelease = defaults.bool(forKey: "preRelease")
        if let camera = defaults.string(forKey: "camera") {
            Settings.camera = camera
        }
        if let exploreSystemPrompt = defaults.string(forKey: "exploreSystemPrompt") {
            Settings.exploreSystemPrompt = exploreSystemPrompt
        }
        if let exploreUserPrompt = defaults.string(forKey: "exploreUserPrompt") {
            Settings.exploreUserPrompt = exploreUserPrompt
        }
    }

    static func save() {
        let defaults = UserDefaults.standard
        defaults.set(Settings.positionReset, forKey: "positionReset")
        defaults.set(Settings.positionalAudio, forKey: "positionalAudio")
        defaults.set(Settings.launchOnBoot, forKey: "launchOnBoot")
        defaults.set(Settings.autoScan, forKey: "autoScan")
        defaults.set(Settings.detectObject, forKey: "detectObject")
        defaults.set(Settings.preRelease, forKey: "preRelease")
        defaults.set(Settings.usePresetPrompt, forKey: "usePresetPrompt")
        defaults.set(Settings.targetWindow, forKey: "targetWindow")
        defaults.set(Settings.camera, forKey: "camera")
        defaults.set(Settings.exploreSystemPrompt, forKey: "exploreSystemPrompt")
        defaults.set(Settings.exploreUserPrompt, forKey: "exploreUserPrompt")
    }

}

class MenuHandler: NSObject {
    @objc func toggleSetting(_ sender: NSMenuItem) {
        hide()
        sender.state = (sender.state == .off) ? .on : .off
        switch sender.title {
        case NSLocalizedString(
            "menu.settings.targetWindow", value: "Target Window",
            comment: "Menu item for selecting target window"):
            Settings.targetWindow = sender.state == .on
        case NSLocalizedString(
            "menu.settings.detectObjects", value: "Detect Objects",
            comment: "Menu item for enabling object detection"):
            Settings.detectObject = sender.state == .on
        case NSLocalizedString(
            "menu.settings.autoScan", value: "Auto Scan",
            comment: "Menu item for enabling auto scan on mouse click"):
            Settings.autoScan = sender.state == .on
        case NSLocalizedString(
            "menu.settings.resetPosition", value: "Reset Position on Scan",
            comment: "Menu item for resetting cursor position after each scan"):
            Settings.positionReset = sender.state == .on
        case NSLocalizedString(
            "menu.settings.positionalAudio", value: "Positional Audio",
            comment: "Menu item for enabling spatial audio feedback"):
            Settings.positionalAudio = sender.state == .on
        case NSLocalizedString(
            "menu.settings.usePresetPrompt", value: "Use Preset Prompt",
            comment: "Menu item for using preset prompt with AI"):
            Settings.usePresetPrompt = sender.state == .on
        case NSLocalizedString(
            "menu.settings.moveMouse", value: "Move Mouse",
            comment: "Menu item for moving mouse cursor during navigation"):
            Settings.moveMouse = sender.state == .on
        case NSLocalizedString(
            "menu.settings.launchOnLogin", value: "Launch on Login",
            comment: "Menu item for launching VOCR on system startup"):
            Settings.launchOnBoot = sender.state == .on
        case NSLocalizedString(
            "menu.settings.log", value: "Log", comment: "Menu item for enabling debug logging"):
            Settings.writeLog = sender.state == .on
        case NSLocalizedString(
            "menu.downloadPreRelease", value: "Download  Pre-release",
            comment: "Menu item for enabling pre-release version downloads"):
            Settings.preRelease = sender.state == .on
        case NSLocalizedString(
            "menu.autoCheckForUpdates", value: "Automatically Check for Updates",
            comment: "Menu item for enabling automatic update checks"):
            if let updater = AutoUpdateManager.shared.updaterController?.updater {
                updater.automaticallyChecksForUpdates = sender.state == .on
            }
        case NSLocalizedString(
            "menu.autoInstallUpdates", value: "Automatically Install Updates",
            comment: "Menu item for enabling automatic update installation"):
            if let updater = AutoUpdateManager.shared.updaterController?.updater {
                updater.automaticallyDownloadsUpdates = sender.state == .on
            }
        default: break
        }

        Settings.save()
    }

    @objc func toggleAutoScan(_ sender: NSMenuItem) {
        toggleSetting(sender)
        if Settings.autoScan {
            Settings.installMouseMonitor()
        } else {
            Settings.removeMouseMonitor()
        }
    }

    @objc func toggleLaunch(_ sender: NSMenuItem) {
        toggleSetting(sender)
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let launchPath = "Library/LaunchAgents/com.chikim.VOCR.plist"
        let launchFile = home.appendingPathComponent(launchPath)
        if Settings.launchOnBoot {
            if !fileManager.fileExists(atPath: launchFile.path) {
                let bundle = Bundle.main
                let bundlePath = bundle.path(forResource: "com.chikim.VOCR", ofType: "plist")
                try! fileManager.copyItem(at: URL(fileURLWithPath: bundlePath!), to: launchFile)
            } else {
                try! fileManager.removeItem(at: launchFile)
            }
        }
    }

    @objc func displayAboutWindow(_ sender: Any?) {
        let storyboardName = NSStoryboard.Name(stringLiteral: "Main")
        let storyboard = NSStoryboard(name: storyboardName, bundle: nil)
        let storyboardID = NSStoryboard.SceneIdentifier(stringLiteral: "aboutWindowStoryboardID")
        if let aboutWindowController = storyboard.instantiateController(
            withIdentifier: storyboardID)
            as? NSWindowController
        {
            NSApplication.shared.activate(ignoringOtherApps: true)
            aboutWindowController.showWindow(nil)
        }
    }

    @objc func chooseOutput(_ sender: Any?) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString(
            "dialog.soundOutput.title", value: "Sound Output",
            comment: "Title for sound output selection dialog")
        alert.informativeText = NSLocalizedString(
            "dialog.soundOutput.message", value: "Choose an Output for positional audio feedback.",
            comment: "Message prompting user to select audio output device")
        let devices = AudioEngine.outputDevices
        for device in devices {
            alert.addButton(withTitle: device.name)
        }

        let modalResult = alert.runModal()
        hide()
        let n = modalResult.rawValue - 1000
        Player.shared.engine.stop()
        try! Player.shared.engine.setDevice(AudioEngine.outputDevices[n])
        try! Player.shared.engine.start()
    }

    @objc func chooseCamera(_ sender: Any?) {
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video,
            position: .unspecified
        ).devices
        if devices.count > 1 {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString(
                "dialog.camera.title", value: "Camera", comment: "Title for camera selection dialog"
            )
            alert.informativeText = NSLocalizedString(
                "dialog.camera.message", value: "Choose a camera for VOCR to use.",
                comment: "Message prompting user to select camera device")
            for device in devices {
                alert.addButton(withTitle: device.localizedName)
            }
            let modalResult = alert.runModal()
            hide()
            let n = modalResult.rawValue - 1000
            Settings.camera = devices[n].localizedName
            Settings.save()
        }
    }

    @objc func saveResult(_ sender: NSMenuItem) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.text]
        savePanel.allowsOtherFileTypes = false
        savePanel.begin { (result) in
            hide()
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let url = savePanel.url {
                    let text = Navigation.text()
                    try! text.write(to: url, atomically: false, encoding: .utf8)
                }
            }
            let windows = NSApplication.shared.windows
            NSApplication.shared.hide(nil)
            windows[1].close()
        }
    }

    @objc func dismiss(_ sender: NSMenuItem) {

    }

    @objc func saveLastImage(_ sender: NSMenuItem) {
        if let cgImage = Navigation.cgImage {
            try! saveImage(cgImage)
        }
    }

    @objc func openShortcutsWindow(_ sender: NSMenuItem) {
        ShortcutsWindowController.shared.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func addShortcut(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString(
            "dialog.newShortcut.title", value: "New Shortcut",
            comment: "Title for new shortcut creation dialog")
        alert.addButton(
            withTitle: NSLocalizedString(
                "button.create", value: "Create", comment: "Button to create a new item"))
        alert.addButton(
            withTitle: NSLocalizedString(
                "button.cancel", value: "Cancel", comment: "Button to cancel an action"))
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.placeholderString = NSLocalizedString(
            "dialog.newShortcut.placeholder", value: "Shortcut Name",
            comment: "Placeholder text for shortcut name input field")
        alert.accessoryView = inputTextField
        let response = alert.runModal()
        hide()
        if response == .alertFirstButtonReturn {  // OK button
            Shortcuts.shortcuts.append(
                Shortcut(
                    name: inputTextField.stringValue, key: UInt32(0), modifiers: UInt32(0),
                    keyName: NSLocalizedString(
                        "dialog.newShortcut.unassigned", value: "Unassigned",
                        comment: "Status text for unassigned keyboard shortcut")))
            let data = try? JSONEncoder().encode(Shortcuts.shortcuts)
            UserDefaults.standard.set(data, forKey: "userShortcuts")
            Shortcuts.loadShortcuts()
        }
    }

    @objc func checkForUpdates() {
        AutoUpdateManager.shared.checkForUpdates()
    }

    @objc func openEditExplorePrompts(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString(
            "dialog.editExplorePrompts.title", value: "Edit Explore Prompts",
            comment: "Title for explore prompts editing dialog")
        alert.informativeText = NSLocalizedString(
            "dialog.editExplorePrompts.message",
            value: "Update the system and user prompts used for the Explore Mode.",
            comment: "Description of explore prompts editing functionality")
        alert.addButton(
            withTitle: NSLocalizedString(
                "button.save", value: "Save", comment: "Button to save changes"))
        alert.addButton(
            withTitle: NSLocalizedString(
                "button.cancel", value: "Cancel", comment: "Button to cancel an action"))
        // Avoid Return triggering the default button; keep Return for newline in text views.
        alert.buttons.first?.keyEquivalent = ""
        alert.buttons.last?.keyEquivalent = "\u{1b}"

        let systemLabel = NSTextField(
            labelWithString: NSLocalizedString(
                "dialog.editExplorePrompts.systemPromptLabel", value: "System Prompt",
                comment: "Label for system prompt text field"))
        let systemScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 420, height: 140))
        systemScrollView.hasVerticalScroller = true
        systemScrollView.drawsBackground = true
        systemScrollView.translatesAutoresizingMaskIntoConstraints = false
        let systemField = NSTextView(frame: NSRect(x: 0, y: 0, width: 420, height: 140))
        systemField.isEditable = true
        systemField.isRichText = false
        systemField.isVerticallyResizable = true
        systemField.isHorizontallyResizable = false
        systemField.textContainer?.widthTracksTextView = true
        systemField.textContainer?.containerSize = NSSize(
            width: 420, height: CGFloat.greatestFiniteMagnitude)
        systemField.string = Settings.exploreSystemPrompt
        systemScrollView.documentView = systemField

        let userLabel = NSTextField(
            labelWithString: NSLocalizedString(
                "dialog.editExplorePrompts.userPromptLabel", value: "User Prompt",
                comment: "Label for user prompt text field"))
        let userScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 420, height: 120))
        userScrollView.hasVerticalScroller = true
        userScrollView.drawsBackground = true
        userScrollView.translatesAutoresizingMaskIntoConstraints = false
        let userField = NSTextView(frame: NSRect(x: 0, y: 0, width: 420, height: 120))
        userField.isEditable = true
        userField.isRichText = false
        userField.isVerticallyResizable = true
        userField.isHorizontallyResizable = false
        userField.textContainer?.widthTracksTextView = true
        userField.textContainer?.containerSize = NSSize(
            width: 420, height: CGFloat.greatestFiniteMagnitude)
        userField.string = Settings.exploreUserPrompt
        userScrollView.documentView = userField

        let stack = NSStackView(views: [systemLabel, systemScrollView, userLabel, userScrollView])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 440, height: 300))
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            systemScrollView.heightAnchor.constraint(equalToConstant: 140),
            userScrollView.heightAnchor.constraint(equalToConstant: 120),
            systemScrollView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            userScrollView.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
        alert.accessoryView = container

        let response = alert.runModal()
        hide()
        if response == .alertFirstButtonReturn {
            Settings.exploreSystemPrompt = systemField.string
            Settings.exploreUserPrompt = userField.string
            Settings.save()
        }
    }

    @objc func selectPresetFromMenu(_ sender: NSMenuItem) {
        guard let presetID = sender.representedObject as? UUID else { return }
        PresetManager.shared.selectPreset(id: presetID)

        if let appDelegate = NSApp.delegate as? AppDelegate {
            let newMenu = Settings.setupMenu()
            appDelegate.statusItem.menu = newMenu
        }
    }

    @objc func openPresetManagerWindow(_ sender: NSMenuItem) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.openPresetWindow()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc func reset(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString(
            "dialog.reset.title", value: "Reset?", comment: "Title for reset confirmation dialog")
        alert.informativeText = NSLocalizedString(
            "dialog.reset.message",
            value: "This will erase all the settings and presets. This cannot be undone.",
            comment: "Warning message about irreversible reset action")
        alert.alertStyle = .warning

        alert.addButton(
            withTitle: NSLocalizedString(
                "button.resetAndRelaunch", value: "Reset and Relaunch",
                comment: "Button to reset settings and restart application"))  // first button is return value .alertFirstButtonReturn
        alert.addButton(
            withTitle: NSLocalizedString(
                "button.cancel", value: "Cancel", comment: "Button to cancel an action"))

        // Make the destructive action the default and make Cancel respond to Escape
        alert.buttons.first?.hasDestructiveAction = true
        alert.buttons.first?.keyEquivalent = "\r"
        alert.buttons.last?.keyEquivalent = "\u{1b}"

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        // Reset defaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // Relaunch
        let appURL = Bundle.main.bundleURL
        NSWorkspace.shared.openApplication(
            at: appURL,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

}
