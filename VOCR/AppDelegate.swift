import Cocoa
import AudioKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	var windows:[NSWindow] = []
	let shortcuts = Shortcuts()
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		let menu = NSMenu()
		menu.addItem(withTitle: "Sound Output...", action: #selector(AppDelegate.chooseOutput(_:)), keyEquivalent: "")
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
		if let devices = AudioKit.outputDevices {
			for device in devices {
				alert.addButton(withTitle: device.name)
			}
		}
		let modalResult = alert.runModal()
		let n = modalResult.rawValue-1000
		if AudioKit.engine.isRunning {
		try! AudioKit.stop()
		}
		try! AudioKit.setOutputDevice(AudioKit.outputDevices![n])
		try! AudioKit.start()
	}

	@objc func click(_ sender: Any?) {
		print("Clicked")
	}
	
	@objc func quit(_ sender: AnyObject?) {
		NSApplication.shared.terminate(self)
	}
	
}
