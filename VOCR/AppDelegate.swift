import Cocoa
import Sparkle
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )
    var autoUpdateManager: AutoUpdateManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        killInstance()
        menuNeedsUpdate(NSMenu())
        Shortcuts.SetupShortcuts()
        if let button = statusItem.button {
            button.title = "VOCR"
            button.action = #selector(click(_:))
        }
        NSApp.setActivationPolicy(.accessory)
        setupAutoLaunch()
        hide()
        DispatchQueue.main.async { [weak self] in
            self?.releaseWindowlessFocus()
        }
        Accessibility.speak(
            NSLocalizedString(
                "app.ready", value: "VOCR Ready!", comment: "Message when app is ready"))
        NSSound(
            contentsOfFile: "/System/Library/Sounds/Blow.aiff",
            byReference: true
        )?.play()
        autoUpdateManager = AutoUpdateManager.shared

        // Check if should show permissions onboarding
        checkAndShowPermissionsOnboarding()
    }

    func killInstance() {
        let appId = Bundle.main.bundleIdentifier!
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.bundleIdentifier == appId
                && app != NSRunningApplication.current
            {
                app.forceTerminate()
            }
        }
    }

    func setupAutoLaunch() {
        if LaunchAgentManager.installDefaultIfNeeded(launchOnBoot: Settings.launchOnBoot) {
            Settings.launchOnBoot = true
            Settings.save()
        }
    }

    @objc func click(_ sender: Any?) {
        log("Menu Clicked")
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let menu = StatusMenuController.makeMenu()
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
            if let cgImage = image.cgImage(
                forProposedRect: &rect,
                context: nil,
                hints: nil
            ) {
                ask(image: cgImage)

                return true  // Indicate success
            } else {
                return false
            }
        }
        return false
    }

    // MARK: - Permissions Onboarding

    private func checkAndShowPermissionsOnboarding() {
        // Delay slightly to allow app to fully launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let statuses = PermissionsManager.shared.checkAllStatuses()
            let hasMissing = PermissionsManager.Permission.allCases.contains { permission in
                permission.isRequired && statuses[permission] != .granted
            }
            if hasMissing {
                self?.openPermissionsWindow()
            } else {
                self?.releaseWindowlessFocus()
            }
        }
    }

    @objc func openPermissionsWindow() {
        PermissionsWindowController.shared.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func releaseWindowlessFocus() {
        guard NSApp.windows.allSatisfy({ !$0.isVisible }) else { return }
        NSApp.hide(nil)
        NSApp.deactivate()
    }

}
