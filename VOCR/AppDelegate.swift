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

}
