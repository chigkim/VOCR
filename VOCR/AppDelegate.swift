import Cocoa
import AudioKit
import PythonKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate	 {
	
	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	var windows:[NSWindow] = []
	let shortcuts = Shortcuts()
	let task = Process()
	func applicationDidFinishLaunching(_ notification: Notification) {
		DispatchQueue.global().async {
			let bundle = Bundle.main
			let url = bundle.url(forResource: "server", withExtension: "")
			self.task.executableURL = url!
			do {
				//				try self.task.run()
			} catch {
				print("Can't run server.")
			}
		}
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
		
		PythonLibrary.useVersion(3)
		PythonLibrary.useLibrary(at: "/usr/local/bin/python3")
	}
	
	func applicationWillTerminate(_ notification: Notification) {
		print("Terminating server...")
		task.terminate()
		task.interrupt()
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
