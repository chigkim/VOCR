import Cocoa

final class PresetManagerWindowController: NSWindowController {

	let rootVC = PresetManagerViewController()

	init() {
		let win = NSWindow(
			contentRect: NSRect(x: 200, y: 200, width: 500, height: 360),
			styleMask: [.titled, .closable, .miniaturizable, .resizable],
			backing: .buffered,
			defer: false
		)
		win.title = "Preset Manager"

		super.init(window: win)

		window?.contentViewController = rootVC
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
