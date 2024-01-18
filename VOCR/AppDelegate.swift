import Cocoa
import Sparkle
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, SPUUpdaterDelegate, SPUStandardUserDriverDelegate, UNUserNotificationCenterDelegate {
	
	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	var updaterController: SPUStandardUpdaterController?
	let UPDATE_NOTIFICATION_IDENTIFIER = "VOCRUpdateCheck"
	var supportsGentleScheduledUpdateReminders: Bool {
		return true
	}
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
		updaterController?.updater.automaticallyChecksForUpdates = true
		updaterController?.updater.automaticallyDownloadsUpdates = true
		updaterController?.updater.checkForUpdatesInBackground()
		updaterController?.updater.updateCheckInterval = 3600  // Check every hour
		menuNeedsUpdate(NSMenu())
		Shortcuts.SetupShortcuts()
		if let button = statusItem.button {
			button.title = "VOCR"
			button.action = #selector(click(_:))
		}
		NSApp.setActivationPolicy(.accessory)
		UNUserNotificationCenter.current().delegate = self
		
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
		Accessibility.speak("VOCR Ready!")
		NSSound(contentsOfFile: "/System/Library/Sounds/Blow.aiff", byReference: true)?.play()
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
	
	func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval) {
		UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { granted, error in
			// Examine granted outcome and error if desired...
		}
	}
	
	func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
		NSApp.setActivationPolicy(.regular)
		if !state.userInitiated {
			NSApp.dockTile.badgeLabel = "1"
			do {
				let content = UNMutableNotificationContent()
				content.title = "A new update is available"
				content.body = "Version \(update.displayVersionString) is now available"
				let request = UNNotificationRequest(identifier: UPDATE_NOTIFICATION_IDENTIFIER, content: content, trigger: nil)
				UNUserNotificationCenter.current().add(request)
			}
		}
	}

	func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
		NSApp.dockTile.badgeLabel = ""
		UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [UPDATE_NOTIFICATION_IDENTIFIER])
	}
	
	func standardUserDriverWillFinishUpdateSession() {
		NSApp.setActivationPolicy(.accessory)
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		if response.notification.request.identifier == UPDATE_NOTIFICATION_IDENTIFIER && response.actionIdentifier == UNNotificationDefaultActionIdentifier {
			updaterController?.checkForUpdates(nil)
		}
		completionHandler()
	}

}
