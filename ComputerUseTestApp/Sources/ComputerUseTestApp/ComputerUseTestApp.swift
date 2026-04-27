import AppKit
import Carbon
import SwiftUI

@main
struct ComputerUseTestApp: App {
    @StateObject private var logger = ActionLogger()
    @StateObject private var computerUse = ComputerUseRunner()
    private let launchPrompt = LaunchArguments.prompt

    var body: some Scene {
        WindowGroup("Computer Use Test App") {
            ContentView()
                .environmentObject(logger)
                .environmentObject(computerUse)
                .frame(minWidth: 960, minHeight: 680)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    maximizeWindow()

                    logger.log("App", "App launched and activated")
                    if let launchPrompt {
                        logger.log("Computer Use", "Launch prompt queued: \(launchPrompt)")
                        computerUse.startAfterWindowAppears(
                            prompt: launchPrompt, logger: logger, quitWhenDone: true)
                    }
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("About Computer Use Test App") {
                    showAboutPanel()
                    logger.log("Menu", "About selected")
                }
            }

            CommandGroup(replacing: .newItem) {
                Button("New Test Session") {
                    logger.clear()
                    logger.log("Menu", "New Test Session selected")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandMenu("Permissions") {
                Button("Request Accessibility Permission") {
                    computerUse.requestAccessibility(logger: logger)
                }

                Button("Request Screen Recording Permission") {
                    computerUse.requestScreenRecording(logger: logger)
                }

                Divider()

                Button("Check All Permissions") {
                    computerUse.requestPermissions(logger: logger)
                }
            }

            CommandMenu("Test Actions") {
                Button("Ask Computer Use...") {
                    computerUse.showPrompt(logger: logger)
                }

                Button("Cancel Computer Use") {
                    computerUse.abort()
                    logger.log("Computer Use", "Cancel requested from menu")
                }
                .keyboardShortcut(.escape, modifiers: [])

                Divider()

                Button("Log Menu Action") {
                    logger.log("Menu", "Log Menu Action selected")
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Divider()

                Button("Clear Action Log") {
                    logger.clear()
                }
                .keyboardShortcut("k", modifiers: [.command])
            }
        }
    }

    private func maximizeWindow() {
        guard let window = NSApp.windows.first(where: { $0.title == "Computer Use Test App" })
        else {
            return
        }

        if let screen = window.screen ?? NSScreen.main {
            window.setFrame(screen.visibleFrame, display: true, animate: true)
        }
    }

    private func showAboutPanel() {
        let alert = NSAlert()
        alert.messageText = "Computer Use Test App"
        alert.informativeText =
            "A macOS test harness for validating VOCR computer-use clicks, drags, typing, menus, shortcuts, and selections."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

enum LaunchArguments {
    static var prompt: String? {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "--prompt") else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else {
            return nil
        }
        return arguments[valueIndex]
    }
}

final class ActionLogger: ObservableObject {
    struct Entry: Identifiable {
        let id = UUID()
        let timestamp: String
        let category: String
        let message: String
    }

    @Published private(set) var entries: [Entry] = []
    @Published private(set) var fullLogText: String = ""

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    func log(_ category: String, _ message: String) {
        let timestamp = formatter.string(from: Date())
        let entry = Entry(
            timestamp: timestamp,
            category: category,
            message: message
        )

        let logLine = "[\(timestamp)] \(category): \(message)\n"

        DispatchQueue.main.async {
            self.entries.insert(entry, at: 0)
            self.fullLogText += logLine

            if self.entries.count > 200 {
                self.entries.removeLast(self.entries.count - 200)
            }
        }
        debugPrint("[\(entry.timestamp)] \(category): \(message)")
    }

    func clear() {
        entries.removeAll()
        fullLogText = ""
        log("Log", "Cleared")
    }
}

func currentClickModifierDescription() -> String {
    let flags = NSEvent.modifierFlags
    var modifiers: [String] = []
    if flags.contains(.command) { modifiers.append("Command") }
    if flags.contains(.control) { modifiers.append("Control") }
    if flags.contains(.option) { modifiers.append("Option") }
    if flags.contains(.shift) { modifiers.append("Shift") }
    return modifiers.isEmpty ? "no modifiers" : modifiers.joined(separator: "+")
}

struct ContentView: View {
    @EnvironmentObject private var logger: ActionLogger
    @EnvironmentObject private var computerUse: ComputerUseRunner
    @State private var messageText = ""
    @State private var computerUsePrompt = ""
    @State private var selectedPopup = "Alpha"
    @State private var selectedRadio = "One"
    @State private var checkboxEnabled = false
    @State private var sliderValue = 50.0
    @State private var selectedCell: Int?
    @State private var dropIsTargeted = false
    @State private var shortcutCaptureRequest = 0

    private let popupOptions = ["Alpha", "Bravo", "Charlie", "Delta"]
    private let radioOptions = ["One", "Two", "Three"]
    private let columns = Array(repeating: GridItem(.fixed(54), spacing: 8), count: 5)

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                computerUseSection
                dragSection
                inputSection
                selectionSection
                tableSection
                shortcutSection
            }
            .frame(width: 560, alignment: .topLeading)

            LogPanel()
                .frame(width: 360)
        }
        .padding(20)
    }

    private var computerUseSection: some View {
        GroupBox("Computer Use") {
            HStack(spacing: 10) {
                TextField("Enter task (e.g. click cell 5)", text: $computerUsePrompt)
                    .textFieldStyle(.roundedBorder)
                    .disabled(computerUse.isRunning)
                    .accessibilityLabel("Computer Use Prompt")

                Button(computerUse.isRunning ? "Running..." : "Run") {
                    computerUse.start(prompt: computerUsePrompt, logger: logger)
                }
                .disabled(computerUse.isRunning || computerUsePrompt.isEmpty)
                .accessibilityLabel("Run Computer Use")

                Button("Cancel") {
                    computerUse.abort()
                    logger.log("Computer Use", "Cancel requested from button")
                }
                .disabled(!computerUse.isRunning)
                .accessibilityLabel("Cancel Computer Use")
            }
        }
    }

    private var dragSection: some View {
        GroupBox("Drag and Drop Buttons") {
            HStack(spacing: 28) {
                Button {
                    logger.log(
                        "Button", "Drag Source clicked with \(currentClickModifierDescription())")
                } label: {
                    Text("Drag Source")
                        .font(.headline)
                        .frame(width: 150, height: 54)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(Color.accentColor.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
                .cornerRadius(8)
                .accessibilityLabel("Drag Source")
                .onDrag {
                    logger.log("Drag", "Drag Source drag started")
                    return NSItemProvider(object: "Drag Source" as NSString)
                }

                Button {
                    logger.log(
                        "Button", "Drop Target clicked with \(currentClickModifierDescription())")
                } label: {
                    Text("Drop Target")
                        .font(.headline)
                        .frame(width: 150, height: 54)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    dropIsTargeted ? Color.green.opacity(0.28) : Color.secondary.opacity(0.12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(dropIsTargeted ? Color.green : Color.secondary, lineWidth: 2)
                )
                .cornerRadius(8)
                .accessibilityLabel("Drop Target")
                .onDrop(
                    of: [.plainText],
                    isTargeted: Binding(
                        get: { dropIsTargeted },
                        set: { value in
                            dropIsTargeted = value
                            logger.log(
                                "Drag",
                                value ? "Drag entered Drop Target" : "Drag exited Drop Target")
                        }
                    )
                ) { providers in
                    logger.log("Drop", "Drop Target received \(providers.count) item(s)")
                    return true
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var inputSection: some View {
        GroupBox("Edit Box and Send Button") {
            HStack(spacing: 10) {
                TextField("Type a message", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Message")
                    .onChange(of: messageText) { newValue in
                        logger.log("Text", "Edit box changed to '\(newValue)'")
                    }
                    .onSubmit {
                        logger.log("Text", "Return submitted '\(messageText)'")
                    }

                Button("Send") {
                    logger.log(
                        "Button",
                        "Send clicked with '\(messageText)' and \(currentClickModifierDescription())"
                    )
                }
                .keyboardShortcut(.return, modifiers: [])
                .accessibilityLabel("Send")
            }
        }
    }

    private var selectionSection: some View {
        GroupBox("Popup Menu, Radio Box, and Checkbox") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Popup Menu", selection: $selectedPopup) {
                    ForEach(popupOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Options")
                .onChange(of: selectedPopup) { value in
                    logger.log("Popup", "Selected \(value)")
                }

                Picker("Radio Box", selection: $selectedRadio) {
                    ForEach(radioOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.radioGroup)
                .accessibilityLabel("Choice")
                .onChange(of: selectedRadio) { value in
                    logger.log("Radio", "Selected \(value)")
                }

                Toggle("Enable Checkbox", isOn: $checkboxEnabled)
                    .accessibilityLabel("Enable")
                    .onChange(of: checkboxEnabled) { value in
                        logger.log("Checkbox", value ? "Checked" : "Unchecked")
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Slider Value: \(Int(sliderValue))")
                    Slider(value: $sliderValue, in: 0...100, step: 1)
                        .accessibilityLabel("Value")
                        .accessibilityValue("\(Int(sliderValue))")
                        .onChange(of: sliderValue) { value in
                            logger.log("Slider", "Changed to \(Int(value))")
                        }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var tableSection: some View {
        GroupBox("5 by 5 Number Table") {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...25, id: \.self) { number in
                    Button {
                        selectedCell = number
                        logger.log(
                            "Table",
                            "Selected cell \(number) with \(currentClickModifierDescription())")
                    } label: {
                        Text("\(number)")
                            .font(.headline)
                            .frame(width: 54, height: 42)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityLabel("Cell \(number)")
                    .background(
                        selectedCell == number ? Color.accentColor.opacity(0.18) : Color.clear
                    )
                    .cornerRadius(6)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var shortcutSection: some View {
        GroupBox("Shortcut Tests with Modifiers") {
            VStack(alignment: .leading, spacing: 8) {
                Button("Start Shortcut Capture") {
                    shortcutCaptureRequest += 1
                    logger.log(
                        "Shortcut",
                        "Shortcut capture started with \(currentClickModifierDescription())")
                }
                .accessibilityLabel("Start Shortcut Capture")

                ShortcutCaptureView(focusRequest: shortcutCaptureRequest) { description in
                    logger.log("Shortcut", description)
                }
                .frame(height: 78)
                .accessibilityLabel("Shortcut Test Area")
            }
        }
    }
}

struct LogPanel: View {
    @EnvironmentObject private var logger: ActionLogger

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Logs")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button("Clear") {
                    logger.clear()
                    logger.log(
                        "Button", "Clear Log clicked with \(currentClickModifierDescription())")
                }
                .accessibilityLabel("Clear")
            }

            ScrollViewReader { proxy in
                ScrollView {
                    Text(logger.fullLogText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .textSelection(.enabled)
                        .id("LogBottom")
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .onChange(of: logger.fullLogText) { _ in
                    proxy.scrollTo("LogBottom", anchor: .bottom)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Logs")
    }
}

struct ShortcutCaptureView: NSViewRepresentable {
    let focusRequest: Int
    let onShortcut: (String) -> Void

    func makeNSView(context: Context) -> ShortcutCaptureNSView {
        let view = ShortcutCaptureNSView()
        view.onShortcut = onShortcut
        view.focusRequest = focusRequest
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureNSView, context: Context) {
        nsView.onShortcut = onShortcut
        if nsView.focusRequest != focusRequest {
            nsView.focusRequest = focusRequest
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
                nsView.needsDisplay = true
            }
        }
    }
}

final class ShortcutCaptureNSView: NSView {
    var onShortcut: ((String) -> Void)?
    var focusRequest = 0

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        needsDisplay = true
        return true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func draw(_ dirtyRect: NSRect) {
        let focused = window?.firstResponder === self
        (focused
            ? NSColor.selectedControlColor.withAlphaComponent(0.16)
            : NSColor.controlBackgroundColor).setFill()
        bounds.fill()
        (focused ? NSColor.keyboardFocusIndicatorColor : NSColor.separatorColor).setStroke()
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8)
        path.lineWidth = 2
        path.stroke()

        let text = focused ? "Listening for shortcut" : "Press Start Shortcut Capture"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: NSColor.labelColor,
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(
                x: bounds.midX - size.width / 2,
                y: bounds.midY - size.height / 2
            ),
            withAttributes: attributes
        )
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        onShortcut?("Shortcut capture area focused")
    }

    override func keyDown(with event: NSEvent) {
        onShortcut?(describe(event))
    }

    private func describe(_ event: NSEvent) -> String {
        var parts: [String] = []
        if event.modifierFlags.contains(.command) { parts.append("Command") }
        if event.modifierFlags.contains(.control) { parts.append("Control") }
        if event.modifierFlags.contains(.option) { parts.append("Option") }
        if event.modifierFlags.contains(.shift) { parts.append("Shift") }

        let key: String
        switch Int(event.keyCode) {
        case kVK_Escape:
            key = "Escape"
        case kVK_Return:
            key = "Return"
        case kVK_Tab:
            key = "Tab"
        case kVK_Space:
            key = "Space"
        default:
            key = event.charactersIgnoringModifiers?.uppercased() ?? "KeyCode \(event.keyCode)"
        }

        parts.append(key)
        return "Pressed \(parts.joined(separator: "+"))"
    }
}
