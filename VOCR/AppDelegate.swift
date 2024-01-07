import Cocoa
import AudioKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	private var eventMonitor: Any?
	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	var windows:[NSWindow] = []
	let shortcuts = Shortcuts()
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		let fileManager = FileManager.default
		let home = fileManager.homeDirectoryForCurrentUser
		let launchFolder = home.appendingPathComponent("Library/LaunchAgents")
		if !fileManager.fileExists(atPath: launchFolder.path) {
			try! fileManager.createDirectory(at: launchFolder, withIntermediateDirectories: false, attributes: nil)
		}
		let launchPath = "Library/LaunchAgents/com.chikim.VOCR.plist"
		let launchFile = home.appendingPathComponent(launchPath)
		if !Settings.launchOnBoot && !fileManager.fileExists(atPath: launchFile.path) {
			let bundle = Bundle.main
			let bundlePath = bundle.path(forResource: "com.chikim.VOCR", ofType: "plist")
			try! fileManager.copyItem(at: URL(fileURLWithPath: bundlePath!), to: launchFile)
			Settings.launchOnBoot = true
			Settings.save()
		}
		Settings.load()
		
		let menu = NSMenu()
		
		let autoScanMenuItem = NSMenuItem(title: "Auto Scan", action: #selector(toggleAutoScan(_:)), keyEquivalent: "")
		autoScanMenuItem.state = (Settings.autoScan) ? .on : .off
		menu.addItem(autoScanMenuItem)
		if Settings.autoScan {
			installMouseMonitor()
		}
		let positionResetMenuItem = NSMenuItem(title: "Reset Position on Scan", action: #selector(togglepositionReset(_:)), keyEquivalent: "")
		positionResetMenuItem.state = (Settings.positionReset) ? .on : .off
		menu.addItem(positionResetMenuItem)
		
		let positionalAudioMenuItem = NSMenuItem(title: "Positional Audio", action: #selector(togglePositionalAudio(_:)), keyEquivalent: "")
		positionalAudioMenuItem.state = (Settings.positionalAudio) ? .on : .off
		menu.addItem(positionalAudioMenuItem)
		
		let moveMouseMenuItem = NSMenuItem(title: "Move Mouse", action: #selector(toggleMoveMouse(_:)), keyEquivalent: "")
		moveMouseMenuItem.state = (Settings.moveMouse) ? .on : .off
		menu.addItem(moveMouseMenuItem)
		
		let menuItem = NSMenuItem(title: "Launch on Login", action: #selector(toggleLaunch(_:)), keyEquivalent: "")
		if fileManager.fileExists(atPath: launchFile.path) {
			menuItem.state = .on
		}
		menu.addItem(menuItem)
		menu.addItem(withTitle: "Sound Output...", action: #selector(chooseOutput(_:)), keyEquivalent: "")
		menu.addItem(withTitle: "OpenAI API Key...", action: #selector(presentApiKeyInputDialog(_:)), keyEquivalent: "")
		menu.addItem(withTitle: "About", action: #selector(displayAboutWindow(_:)), keyEquivalent: "")
		menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "")
		
		statusItem.menu = menu
		
		if let button = statusItem.button {
			button.title = "VOCR"
			button.action = #selector(click(_:))
		}
		
		windows = NSApplication.shared.windows
		NSApplication.shared.hide(self)
		windows[1].close()
		
	}
	
	@objc func toggleAutoScan(_ sender: NSMenuItem) {
		sender.state = (sender.state == .off) ? .on : .off
		Settings.autoScan = (sender.state == .on) ? true : false
		Settings.save()
		if Settings.autoScan {
			installMouseMonitor()
		} else {
			removeMouseMonitor()
		}
	}
	
	@objc func togglepositionReset(_ sender: NSMenuItem) {
		sender.state = (sender.state == .off) ? .on : .off
		Settings.positionReset = (sender.state == .on) ? true : false
		Settings.save()
	}
	
	@objc func togglePositionalAudio(_ sender: NSMenuItem) {
		sender.state = (sender.state == .off) ? .on : .off
		Settings.positionalAudio = (sender.state == .on)
		Settings.save()
	}
	
	
	@objc func toggleMoveMouse(_ sender: NSMenuItem) {
		sender.state = (sender.state == .off) ? .on : .off
		Settings.moveMouse = (sender.state == .on)
		Settings.save()
	}
	
	@objc func presentApiKeyInputDialog(_ sender: AnyObject?) {
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
		if response == .alertFirstButtonReturn { // OK button
			let apiKey = inputTextField.stringValue
			Settings.GPTAPIKEY = apiKey
			Settings.save()
		}
	}
	
	@objc func toggleLaunch(_ sender: NSMenuItem) {
		let fileManager = FileManager.default
		let home = fileManager.homeDirectoryForCurrentUser
		let launchPath = "Library/LaunchAgents/com.chikim.VOCR.plist"
		let launchFile = home.appendingPathComponent(launchPath)
		if sender.state == .off {
			if !fileManager.fileExists(atPath: launchFile.path) {
				let bundle = Bundle.main
				let bundlePath = bundle.path(forResource: "com.chikim.VOCR", ofType: "plist")
				try! fileManager.copyItem(at: URL(fileURLWithPath: bundlePath!), to: launchFile)
				Settings.launchOnBoot = true
				Settings.save()
			}
			sender.state = .on
		} else {
			try!fileManager.removeItem(at: launchFile)
			Settings.launchOnBoot = false
			Settings.save()
			sender.state = .off
		}
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
		let n = modalResult.rawValue-1000
		Player.shared.engine.stop()
		try! Player.shared.engine.setDevice(AudioEngine.outputDevices[n])
		try! Player.shared.engine.start()
	}
	
	@objc func click(_ sender: Any?) {
		print("Clicked")
	}
	
	@objc func quit(_ sender: AnyObject?) {
		NSApplication.shared.terminate(self)
	}
	
	func installMouseMonitor() {
		self.eventMonitor = NSEvent.addGlobalMonitorForEvents(
			matching: [NSEvent.EventTypeMask.leftMouseDown],
			handler: { (event: NSEvent) in
				switch event.type {
				case .leftMouseDown:
					print("Left mouse click detected.")
					if Navigation.shared.navigationShortcuts != nil {
						Thread.sleep(forTimeInterval: 0.5)
						initOCR()
					}
				case .rightMouseDown:
					print("Right mouse click detected.")
					if Navigation.shared.navigationShortcuts != nil {
						Thread.sleep(forTimeInterval: 0.5)
						initOCR()
					}
					
					
				default:
					break
				}
			})
	}
	
	func removeMouseMonitor() {
		if let eventMonitor = self.eventMonitor {
			NSEvent.removeMonitor(eventMonitor)
		}
	}
	
	func applicationWillTerminate(_ notification: Notification) {
		removeMouseMonitor()
	}
	
	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		let fileURL = URL(fileURLWithPath: filename)
		if let image = NSImage(contentsOf: fileURL) {
			var rect = CGRect(origin: .zero, size: image.size)
			if let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) {
				let alert = NSAlert()
				alert.messageText = "Ask GPT-4V"
				alert.informativeText = "Type your question for GPT  below:"
				alert.addButton(withTitle: "Ask")
				alert.addButton(withTitle: "Cancel")
				let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
				inputTextField.placeholderString = "Question"
				inputTextField.stringValue = "Describe the image."
				alert.accessoryView = inputTextField
				let response = alert.runModal()
				if response == .alertFirstButtonReturn { // OK button
					let prompt = inputTextField.stringValue
					let system = "You are a helpful assistant."
					GPT.describe(image:cgImage, system:system, prompt:prompt) { description in
						Accessibility.speak(description)
						copyToClipboard(description)
					}
				}
				return true  // Indicate success
			} else {
				return false
			}
		}
		return false
	}
	
}
