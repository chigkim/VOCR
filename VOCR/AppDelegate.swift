import Cocoa
import AudioKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
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

		let menu = NSMenu()
		let menuItem = NSMenuItem(title: "Launch on Login", action: #selector(AppDelegate.toggleLaunch(_:)), keyEquivalent: "")
		if fileManager.fileExists(atPath: launchFile.path) {
			menuItem.state = .on
		}
		menu.addItem(menuItem)
		menu.addItem(withTitle: "Sound Output...", action: #selector(AppDelegate.chooseOutput(_:)), keyEquivalent: "")
		menu.addItem(withTitle: "OpenAI API Key...", action: #selector(AppDelegate.presentApiKeyInputDialog(_:)), keyEquivalent: "")
		menu.addItem(withTitle: "About", action: #selector(AppDelegate.displayAboutWindow(_:)), keyEquivalent: "")
		menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "")
		
		statusItem.menu = menu
		
		if let button = statusItem.button {
			button.title = "VOCR"
			button.action = #selector(AppDelegate.click(_:))
		}
		
		windows = NSApplication.shared.windows
		NSApplication.shared.hide(self)
		windows[1].close()
		Settings.load()
	}

	@objc func presentApiKeyInputDialog(_ sender: AnyObject?) {
	 let alert = NSAlert()
	 alert.messageText = "Enter API Key"
	 alert.informativeText = "Type your API key below:"
	 alert.addButton(withTitle: "OK")
	 alert.addButton(withTitle: "Cancel")

	 // Create the input text field and set properties
	 let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
	 inputTextField.placeholderString = "API Key"
		inputTextField.stringValue = Settings.GPTAPIKEY

	 // Add the text field to the alert
	 alert.accessoryView = inputTextField

	 // Present the alert
	 let response = alert.runModal()

	 // Handle the user's response
	 if response == .alertFirstButtonReturn { // OK button
		 let apiKey = inputTextField.stringValue
		 // Use the API Key as needed
		 print("User's API Key: \(apiKey)")
		 Settings.GPTAPIKEY = apiKey
		 Settings.save()
	 }
 }

	@objc func toggleLaunch(_ sender: AnyObject?) {
		let fileManager = FileManager.default
		let home = fileManager.homeDirectoryForCurrentUser
		let launchPath = "Library/LaunchAgents/com.chikim.VOCR.plist"
		let launchFile = home.appendingPathComponent(launchPath)
		let menu = statusItem.menu
		let menuItem = menu?.item(withTitle:"Launch on Login")
		if menuItem?.state == .off {
			if !fileManager.fileExists(atPath: launchFile.path) {
				let bundle = Bundle.main
				let bundlePath = bundle.path(forResource: "com.chikim.VOCR", ofType: "plist")
				try! fileManager.copyItem(at: URL(fileURLWithPath: bundlePath!), to: launchFile)
				Settings.launchOnBoot = true
				Settings.save()
			}
			menuItem?.state = .on
		} else {
			try!fileManager.removeItem(at: launchFile)
			Settings.launchOnBoot = false
			Settings.save()
			menuItem?.state = .off
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
	
}
