//
//  Settings.swift
//  VOCR
//
//  Created by Chi Kim on 10/14/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa
import AudioKit
import AVFoundation

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
	static var useLastPrompt = false
	static var prompt = "Analyze the image in a comprehensive and detailed manner."
	static var systemPrompt = "A chat between a curious user and an artificial intelligence assistant. The assistant gives helpful, detailed, and polite answers to the user's questions."
	static var GPTAPIKEY = ""
	static var mode = "OCR"
	static let target = MenuHandler()
	static var engine: Engines = .ollama
	static var writeLog = false
	static var preRelease = false
	static var camera = "Unknown"
	
	static var allSettings: [(title: String, action: Selector, value: Bool)] {
		return [
			("Target Window", #selector(MenuHandler.toggleSetting(_:)), targetWindow),
			("Auto Scan", #selector(MenuHandler.toggleAutoScan(_:)), autoScan),
			("Detect Objects", #selector(MenuHandler.toggleSetting(_:)), detectObject),
			("Use Last Prompt", #selector(MenuHandler.toggleSetting(_:)), useLastPrompt),
			("Reset Position on Scan", #selector(MenuHandler.toggleSetting(_:)), positionReset),
			("Positional Audio", #selector(MenuHandler.toggleSetting(_:)), positionalAudio),
			("Move Mouse", #selector(MenuHandler.toggleSetting(_:)), moveMouse),
			("Launch on Login", #selector(MenuHandler.toggleLaunch(_:)), launchOnBoot),
			("Log", #selector(MenuHandler.toggleLaunch(_:)), writeLog),
		]
	}
	
	static func setupMenu() -> NSMenu {
		load()
		let menu = NSMenu()
		let settingsMenu = NSMenu()
		for setting in allSettings {
			let menuItem = NSMenuItem(title: setting.title, action: setting.action, keyEquivalent: "")
			menuItem.target = target
			menuItem.state = setting.value ? .on : .off
			settingsMenu.addItem(menuItem)
		}
		
		if Settings.autoScan {
			installMouseMonitor()
		}
		
		let engineMenu = NSMenu()
		
		let gptItem = NSMenuItem(title: "GPT", action: #selector(target.selectModel(_:)), keyEquivalent: "")
		gptItem.target = target
		gptItem.tag = Engines.gpt.rawValue
		engineMenu.addItem(gptItem)
		
		let ollamaItem = NSMenuItem(title: "Ollama", action: #selector(target.selectModel(_:)), keyEquivalent: "")
		ollamaItem.target = target
		ollamaItem.tag = Engines.ollama.rawValue
		engineMenu.addItem(ollamaItem)
		
		let llamaCppItem = NSMenuItem(title: "LlamaCpp", action: #selector(target.selectModel(_:)), keyEquivalent: "")
		llamaCppItem.target = target
		llamaCppItem.tag = Engines.llamaCpp.rawValue
		engineMenu.addItem(llamaCppItem)
		
		for item in engineMenu.items {
			item.state = (item.tag == Settings.engine.rawValue) ? .on : .off
		}
		
		let enterAPIKeyMenuItem = NSMenuItem(title: "OpenAI API Key...", action: #selector(target.presentApiKeyInputDialog(_:)), keyEquivalent: "")
		enterAPIKeyMenuItem.target = target
		engineMenu.addItem(enterAPIKeyMenuItem)
		
		let systemPromptMenuItem = NSMenuItem(title: "Set System Prompt...", action: #selector(target.presentSystemPromptDialog(_:)), keyEquivalent: "")
		systemPromptMenuItem.target = target
		engineMenu.addItem(systemPromptMenuItem)
		
		
		let engineMenuItem = NSMenuItem(title: "Engine", action: nil, keyEquivalent: "")
		engineMenuItem.submenu = engineMenu
		settingsMenu.addItem(engineMenuItem)
		
		let soundOutputMenuItem = NSMenuItem(title: "Sound Output...", action: #selector(target.chooseOutput(_:)), keyEquivalent: "")
		soundOutputMenuItem.target = target
		settingsMenu.addItem(soundOutputMenuItem)
		
		let cameraMenuItem = NSMenuItem(title: "Choose Camera...", action: #selector(target.chooseCamera(_:)), keyEquivalent: "")
		cameraMenuItem.target = target
		settingsMenu.addItem(cameraMenuItem)
		
		let shortcutsMenuItem = NSMenuItem(title: "Shortcuts...", action: #selector(target.openShortcutsWindow(_:)), keyEquivalent: "")
		shortcutsMenuItem.target = target
		settingsMenu.addItem(shortcutsMenuItem)
		
		let newShortcutMenuItem = NSMenuItem(title: "New Shortcuts", action: #selector(target.addShortcut(_:)), keyEquivalent: "")
		newShortcutMenuItem.target = target
		//		settingsMenu.addItem(newShortcutMenuItem)
		
		let settingsMenuItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
		settingsMenuItem.submenu = settingsMenu
		menu.addItem(settingsMenuItem)
		
		if Navigation.cgImage != nil {
			let saveScreenshotMenuItem = NSMenuItem(title: "Save Latest Image", action: #selector(target.saveLastImage(_:)), keyEquivalent: "s")
			saveScreenshotMenuItem.target = target
			menu.addItem(saveScreenshotMenuItem)
		}
		
		if Navigation.displayResults.count>1 {
			let saveMenuItem = NSMenuItem(title: "Save OCR Result...", action: #selector(target.saveResult(_:)), keyEquivalent: "")
			saveMenuItem.target = target
			menu.addItem(saveMenuItem)
		}
		
		let updateMenu = NSMenu()
		let aboutMenuItem = NSMenuItem(title: "About...", action: #selector(target.displayAboutWindow(_:)), keyEquivalent: "")
		aboutMenuItem.target = target
		updateMenu.addItem(aboutMenuItem)
		
		let checkForUpdatesItem = NSMenuItem(title: "Check for Updates", action: #selector(target.checkForUpdates), keyEquivalent: "")
		checkForUpdatesItem.target = target
		updateMenu.addItem(checkForUpdatesItem)
		
		let autoCheckItem = NSMenuItem(title: "Automatically Chek for Updates", action: #selector(target.toggleSetting(_:)), keyEquivalent: "")
		autoCheckItem.target = target
		updateMenu.addItem(autoCheckItem)
		
		let autoUpdateItem = NSMenuItem(title: "Automatically Install  Updates", action: #selector(target.toggleSetting(_:)), keyEquivalent: "")
		autoUpdateItem.target = target
		updateMenu.addItem(autoUpdateItem)
		
		if let updater = AutoUpdateManager.shared.updaterController?.updater {
			autoCheckItem.state = (updater.automaticallyChecksForUpdates) ? .on : .off
			autoUpdateItem.state = (updater.automaticallyDownloadsUpdates) ? .on : .off
		}
		
		let preReleaseItem = NSMenuItem(title: "Download  Pre-release", action: #selector(target.toggleSetting(_:)), keyEquivalent: "")
		preReleaseItem.target = target
		updateMenu.addItem(preReleaseItem)
		preReleaseItem.state = (Settings.preRelease) ? .on : .off
		
		let updateMenuItem = NSMenuItem(title: "Updates", action: nil, keyEquivalent: "")
		updateMenuItem.submenu = updateMenu
		menu.addItem(updateMenuItem)
		
		if Shortcuts.navigationActive {
			let dismissMenuItem = NSMenuItem(title: "Dismiss Menu", action: #selector(target.dismiss(_:)), keyEquivalent: "z")
			dismissMenuItem.target = target
			menu.addItem(dismissMenuItem)
		}
		
		menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
		return menu
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
	
	static func displayApiKeyDialog() {
		let alert = NSAlert()
		alert.messageText = "OpenAI API Key"
		alert.informativeText = "Type your OpenAI API key below:"
		alert.addButton(withTitle: "Save")
		alert.addButton(withTitle: "Cancel")
		let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
		inputTextField.placeholderString = "API Key"
		inputTextField.stringValue = Settings.GPTAPIKEY
		alert.accessoryView = inputTextField
		let response = alert.runModal()
		hide()
		if response == .alertFirstButtonReturn { // OK button
			let apiKey = inputTextField.stringValue
			Settings.GPTAPIKEY = apiKey
			if let data = apiKey.data(using: .utf8) {
				let status = KeychainManager.store(key: "com.chikim.VOCR.OAIApiKey", data: data)
				if status == noErr {
					log("API key stored successfully.")
				} else {
					log("Failed to store API key with error: \(status)")
				}
			}
			
		}
	}
	
	static func displaySystemPromptDialog() {
		if let prompt = askPrompt(value:Settings.systemPrompt) {
			Settings.systemPrompt = prompt
			Settings.save()
		}
	}
	
	static func load() {
		let defaults = UserDefaults.standard
		Settings.positionReset = defaults.bool(forKey:"positionReset")
		Settings.positionalAudio = defaults.bool(forKey:"positionalAudio")
		Settings.launchOnBoot = defaults.bool(forKey:"launchOnBoot")
		Settings.autoScan = defaults.bool(forKey:"autoScan")
		Settings.detectObject = defaults.bool(forKey:"detectObject")
		Settings.engine = Engines(rawValue: defaults.integer(forKey:"engine"))!
		Settings.useLastPrompt = defaults.bool(forKey:"useLastPrompt")
		Settings.targetWindow = defaults.bool(forKey:"targetWindow")
		Settings.preRelease = defaults.bool(forKey:"preRelease")
		if let retrievedData = KeychainManager.retrieve(key: "com.chikim.VOCR.OAIApiKey"),
		   let retrievedApiKey = String(data: retrievedData, encoding: .utf8) {
			Settings.GPTAPIKEY = retrievedApiKey
		} else {
			log("Failed to retrieve API key.")
		}
		if let mode = defaults.string(forKey: "mode") {
			Settings.mode = mode
		}
		if let camera = defaults.string(forKey: "camera") {
			Settings.camera = camera
		}
		if let prompt = defaults.string(forKey: "prompt") {
			Settings.prompt = prompt
		}
		if let systemPrompt = defaults.string(forKey: "systemPrompt") {
			Settings.systemPrompt = systemPrompt
		}
		
	}
	
	static func save() {
		let defaults = UserDefaults.standard
		defaults.set(Settings.positionReset, forKey:"positionReset")
		defaults.set(Settings.positionalAudio, forKey:"positionalAudio")
		defaults.set(Settings.launchOnBoot, forKey:"launchOnBoot")
		defaults.set(Settings.autoScan, forKey:"autoScan")
		defaults.set(Settings.detectObject, forKey:"detectObject")
		defaults.set(Settings.preRelease, forKey:"preRelease")
		defaults.set(Settings.engine.rawValue, forKey:"engine")
		defaults.set(Settings.useLastPrompt, forKey:"useLastPrompt")
		defaults.set(Settings.targetWindow, forKey:"targetWindow")
		defaults.set(Settings.prompt, forKey:"prompt")
		defaults.set(Settings.systemPrompt, forKey:"systemPrompt")
		defaults.set(Settings.mode, forKey:"mode")
		defaults.set(Settings.camera, forKey:"camera")
	}
	
	
}

class MenuHandler: NSObject {
	@objc func toggleSetting(_ sender: NSMenuItem) {
		hide()
		sender.state = (sender.state == .off) ? .on : .off
		switch sender.title {
		case "Target Window":
			Settings.targetWindow = sender.state == .on
		case "Detect Objects":
			Settings.detectObject = sender.state == .on
		case "Auto Scan":
			Settings.autoScan = sender.state == .on
		case "Reset Position on Scan":
			Settings.positionReset = sender.state == .on
		case "Positional Audio":
			Settings.positionalAudio = sender.state == .on
		case "Use Last Prompt":
			Settings.useLastPrompt = sender.state == .on
		case "Move Mouse":
			Settings.moveMouse = sender.state == .on
		case "Launch on Login":
			Settings.launchOnBoot = sender.state == .on
		case "Log":
			Settings.writeLog = sender.state == .on
		case "Download  Pre-release":
			Settings.preRelease = sender.state == .on
		case "Automatically Chek for Updates":
			if let updater = AutoUpdateManager.shared.updaterController?.updater {
				updater.automaticallyChecksForUpdates = sender.state == .on
			}
		case "Automatically Install  Updates":
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
				try!fileManager.removeItem(at: launchFile)
			}
		}
	}
	
	@objc func presentApiKeyInputDialog(_ sender: AnyObject?) {
		Settings.displayApiKeyDialog()
	}
	
	@objc func presentSystemPromptDialog(_ sender: AnyObject?) {
		Settings.displaySystemPromptDialog()
	}
	
	@objc func displayAboutWindow(_ sender: Any?) {
		let storyboardName = NSStoryboard.Name(stringLiteral: "Main")
		let storyboard = NSStoryboard(name: storyboardName, bundle: nil)
		let storyboardID = NSStoryboard.SceneIdentifier(stringLiteral: "aboutWindowStoryboardID")
		if let aboutWindowController = storyboard.instantiateController(withIdentifier: storyboardID) as? NSWindowController {
			NSApplication.shared.activate(ignoringOtherApps: true)
			aboutWindowController.showWindow(nil)
		}
	}
	
	@objc func chooseOutput(_ sender: Any?) {
		let alert = NSAlert()
		alert.alertStyle = .informational
		alert.messageText = "Sound Output"
		alert.informativeText = "Choose an Output for positional audio feedback."
		let devices = AudioEngine.outputDevices
		for device in devices {
			alert.addButton(withTitle: device.name)
		}
		
		let modalResult = alert.runModal()
		hide()
		let n = modalResult.rawValue-1000
		Player.shared.engine.stop()
		try! Player.shared.engine.setDevice(AudioEngine.outputDevices[n])
		try! Player.shared.engine.start()
	}
	
	@objc func chooseCamera(_ sender: Any?) {
		let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera,.externalUnknown], mediaType: .video, position: .unspecified).devices
		if devices.count>1 {
			let alert = NSAlert()
			alert.alertStyle = .informational
			alert.messageText = "Camera"
			alert.informativeText = "Choose a camera for VOCR to use."
			for device in devices {
				alert.addButton(withTitle: device.localizedName)
			}
			let modalResult = alert.runModal()
			hide()
			let n = modalResult.rawValue-1000
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
	
	@objc func selectMode(_ sender: NSMenuItem) {
		guard let menu = sender.menu else { return }
		for item in menu.items {
			item.state = (item.title == sender.title) ? .on : .off
		}
		Settings.mode = sender.title
		Settings.save()
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
		alert.messageText = "New Shortcut"
		alert.addButton(withTitle: "Create")
		alert.addButton(withTitle: "Cancel")
		let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
		inputTextField.placeholderString = "Shortcut Name"
		alert.accessoryView = inputTextField
		let response = alert.runModal()
		hide()
		if response == .alertFirstButtonReturn { // OK button
			Shortcuts.shortcuts.append(Shortcut(name: inputTextField.stringValue, key: UInt32(0), modifiers: UInt32(0), keyName:"Unassigned"))
			let data = try? JSONEncoder().encode(Shortcuts.shortcuts)
			UserDefaults.standard.set(data, forKey: "userShortcuts")
			Shortcuts.loadShortcuts()
		}
	}
	
	@objc func selectModel(_ sender: NSMenuItem) {
		Settings.engine = Engines(rawValue: sender.tag)!
		if Settings.engine == .ollama {
			Ollama.setModel()
		}
		Settings.save()
	}
	
	@objc func checkForUpdates() {
		AutoUpdateManager.shared.checkForUpdates()
	}
	
}

