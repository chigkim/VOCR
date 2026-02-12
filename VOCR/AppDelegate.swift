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
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let launchFolder = home.appendingPathComponent("Library/LaunchAgents")
        if !fileManager.fileExists(atPath: launchFolder.path) {
            try! fileManager.createDirectory(
                at: launchFolder,
                withIntermediateDirectories: false,
                attributes: nil
            )
        }
        let launchPath = "Library/LaunchAgents/com.chikim.VOCR.plist"
        let launchFile = home.appendingPathComponent(launchPath)
        if !Settings.launchOnBoot
            && !fileManager.fileExists(atPath: launchFile.path)
        {
            let bundle = Bundle.main
            let bundlePath = bundle.path(
                forResource: "com.chikim.VOCR",
                ofType: "plist"
            )
            try! fileManager.copyItem(
                at: URL(fileURLWithPath: bundlePath!),
                to: launchFile
            )
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

    @objc func openPresetWindow() {
        // Present a simple Preset Manager window using PresetManagerViewController
        let vc = PresetManagerViewController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString(
            "app.presets.window.title", value: "Presets", comment: "Title for presets window")
        window.contentViewController = vc
        let wc = NSWindowController(window: window)
        wc.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Permissions Onboarding

    private func checkAndShowPermissionsOnboarding() {
        if !PermissionsManager.shared.hasSeenPermissionsOnboarding {
            // Delay onboarding slightly to allow app to fully launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showPermissionsOnboarding()
            }
        }
    }

    private func showPermissionsOnboarding() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString(
            "onboarding.permissions.title",
            value: "Welcome to VOCR",
            comment: "Title for permissions onboarding alert")
        alert.informativeText = NSLocalizedString(
            "onboarding.permissions.message",
            value: "VOCR needs permissions to provide OCR and accessibility features. Would you like to set them up now?",
            comment: "Message for permissions onboarding alert")
        alert.addButton(
            withTitle: NSLocalizedString(
                "onboarding.permissions.setup",
                value: "Set Up Permissions",
                comment: "Button to set up permissions"))
        alert.addButton(
            withTitle: NSLocalizedString(
                "onboarding.permissions.skip",
                value: "Skip for Now",
                comment: "Button to skip permissions setup"))

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // User chose "Set Up Permissions"
            openPermissionsWindow()
        }

        // Mark as seen regardless of choice
        PermissionsManager.shared.markOnboardingComplete()
    }

    @objc func openPermissionsWindow() {
        PermissionsWindowController.shared.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

}
