import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	var windows:[NSWindow] = []
	let shortcuts = Shortcuts()

	func applicationDidFinishLaunching(_ notification: Notification) {
		if !Accessibility.isTrusted(ask:true) {
			print("Accessibility not enabled.")
			NSApplication.shared.terminate(self)
		}
		// askCameraPermission()

		let menu = NSMenu()
		menu.addItem(withTitle: "Show", action: #selector(AppDelegate.click(_:)), keyEquivalent: "")
		menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "")

		statusItem.menu = menu
		if let button = statusItem.button {
			button.title = "VOCR"
			button.action = #selector(AppDelegate.click(_:))
		}

		windows = NSApplication.shared.windows
		NSApplication.shared.hide(self)
		windows[1].close()

	}

	@objc func click(_ sender: Any?) {
		//windows[1].center()
		NSApplication.shared.activate(ignoringOtherApps: true)
		windows[1].makeKeyAndOrderFront(nil)
	}

	@objc func quit(_ sender: AnyObject?) {
		NSApplication.shared.terminate(self)
	}



}
