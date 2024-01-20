import Cocoa
import Sparkle
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
	
	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	var autoUpdateManager:AutoUpdateManager?

	func applicationDidFinishLaunching(_ notification: Notification) {
		menuNeedsUpdate(NSMenu())
		Shortcuts.SetupShortcuts()
		if let button = statusItem.button {
			button.title = "VOCR"
			button.action = #selector(click(_:))
		}
		NSApp.setActivationPolicy(.accessory)
		setupAutoLaunch()
		hide()
		Accessibility.speak("VOCR Ready!")
		NSSound(contentsOfFile: "/System/Library/Sounds/Blow.aiff", byReference: true)?.play()
		autoUpdateManager = AutoUpdateManager.shared
	}

	func setupAutoLaunch() {
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
	}

	@objc func click(_ sender: Any?) {
		log("Menu Clicked")
	}
	
	func menuNeedsUpdate(_ menu: NSMenu) {
		let menu = Settings.setupMenu()
		menu.delegate = self
		statusItem.menu = menu
	}
	
	func applicationWillTerminate(_ notification: Notification) {
		Settings.removeMouseMonitor()
	}
	
	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		let fileURL = URL(fileURLWithPath: filename)
		if let image = NSImage(contentsOf: fileURL) {
			var rect = CGRect(origin: .zero, size: image.size)
			if let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) {
				ask(image:cgImage)
				
				return true  // Indicate success
			} else {
				return false
			}
		}
		return false
	}
	

}
