import Cocoa
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, SPUUpdaterDelegate {

	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	var updaterController: SPUStandardUpdaterController?

	func applicationDidFinishLaunching(_ notification: Notification) {
		updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
		updaterController?.updater.automaticallyChecksForUpdates = true
		updaterController?.updater.updateCheckInterval = 3600  // Check every hour
		updaterController?.updater.automaticallyDownloadsUpdates = true
		menuNeedsUpdate(NSMenu())
		Shortcuts.SetupShortcuts()
		if let button = statusItem.button {
			button.title = "VOCR"
			button.action = #selector(click(_:))
		}

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

hide()
	}
	
	@objc func click(_ sender: Any?) {
		print("Clicked")
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
	
	func feedURLString(for updater: SPUUpdater) -> String? {
		return "https://example.com/appcast.xml"
	}

}
