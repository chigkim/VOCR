import AppKit
import Carbon
import SwiftUI

@main
struct UIChallengeApp: App {
    @StateObject private var logger = ActionLogger()
    @StateObject private var computerUse = ComputerUseRunner()
    @StateObject private var levels = LevelController()
    private let launchPrompt = LaunchArguments.prompt
    private let launchLevel = LaunchArguments.level

    var body: some Scene {
        WindowGroup("UI Challenge") {
            ContentView()
                .environmentObject(logger)
                .environmentObject(computerUse)
                .environmentObject(levels)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)

                    logger.log("App", "App launched and activated")
                    if let launchLevel {
                        levels.jump(to: launchLevel, logger: logger)
                    }
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
                Button("About UI Challenge") {
                    showAboutPanel()
                    logger.log("Menu", "About selected")
                }
            }

            CommandGroup(replacing: .newItem) {
                Button("New Test Session") {
                    logger.clear()
                    levels.restart(logger: logger)
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
                Button("Run Computer Use...") {
                    computerUse.showPrompt(logger: logger)
                }

                Button("Cancel Computer Use") {
                    computerUse.abort()
                    logger.log("Computer Use", "Cancel requested from menu")
                }
                .keyboardShortcut(.escape, modifiers: [])

                Divider()

                Button("Clear Action Log") {
                    logger.clear()
                }
                .keyboardShortcut("k", modifiers: [.command])
            }

            CommandMenu("Levels") {
                Button("Restart Challenge") {
                    levels.restart(logger: logger)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])

                Button("Reset Current Level") {
                    levels.resetCurrentLevel(logger: logger)
                }
                .keyboardShortcut("r", modifiers: [.command, .option])

                Toggle("Show Validation Details in UI", isOn: $levels.showValidationDetails)
            }
        }
    }

    private func maximizeWindow() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.title == "UI Challenge" })
            else {
                return
            }

            if let screen = window.screen ?? NSScreen.main {
                window.setFrame(screen.visibleFrame, display: true, animate: true)
            }
        }
    }

    private func showAboutPanel() {
        let alert = NSAlert()
        alert.messageText = "UI Challenge"
        alert.informativeText =
            "A macOS test harness for validating VOCR computer-use clicks, drags, typing, menus, shortcuts, and selections."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

enum LaunchArguments {
    static var prompt: String? {
        stringValue(for: "--prompt")
    }

    static var level: LevelID? {
        guard let raw = stringValue(for: "--level") else { return nil }
        if let number = Int(raw) {
            return LevelID(rawValue: number - 1)
        }
        return LevelID.allCases.first {
            $0.title.lowercased() == raw.lowercased()
        }
    }

    private static func stringValue(for flag: String) -> String? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: flag) else { return nil }
        let next = args.index(after: index)
        guard next < args.endIndex else { return nil }
        return args[next]
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

    private let logFileURL: URL = {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("UIChallenge.log")
    }()

    private func writeToFile(_ line: String) {
        let data = (line + "\n").data(using: .utf8) ?? Data()
        if let handle = try? FileHandle(forWritingTo: logFileURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: logFileURL)
        }
    }

    func log(_ category: String, _ message: String) {
        let timestamp = formatter.string(from: Date())
        let entry = Entry(
            timestamp: timestamp,
            category: category,
            message: message
        )
        let line = "[\(entry.timestamp)] \(category): \(message)"

        DispatchQueue.main.async {
            self.entries.insert(entry, at: 0)
            if self.entries.count > 200 {
                self.entries.removeLast()
            }
            // Rebuild fullLogText from entries to keep it in sync and limited
            self.fullLogText =
                self.entries.map { "[\($0.timestamp)] \($0.category): \($0.message)" }.joined(
                    separator: "\n") + (self.entries.isEmpty ? "" : "\n")
        }
        writeToFile(line)
        debugPrint(line)
    }

    func developerLog(_ category: String, _ message: String) {
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] \(category): \(message)"
        writeToFile(line)
        debugPrint(line)
    }

    func clear() {
        entries.removeAll()
        fullLogText = ""
        log("Log", "Cleared")
    }
}

enum LevelID: Int, CaseIterable, Identifiable {
    case acceptChallenge = 0
    case textEntry
    case modalTask
    case selectionControls
    case tableList
    case numericControls
    case contextMenu
    case keyboardShortcut
    case textEditing
    case scrollTask
    case pointerTask
    case stress
    case analogClock
    case summary

    var id: Int { rawValue }
    var number: Int { rawValue + 1 }

    var title: String {
        switch self {
        case .acceptChallenge: return "Accept Challenge"
        case .textEntry: return "Text Entry"
        case .modalTask: return "Modal Task"
        case .selectionControls: return "Selection Controls"
        case .tableList: return "Table and List"
        case .numericControls: return "Numeric Controls"
        case .contextMenu: return "Context Menu"
        case .keyboardShortcut: return "Keyboard Shortcut"
        case .textEditing: return "Text Editing"
        case .scrollTask: return "Scroll"
        case .pointerTask: return "Pointer Actions"
        case .stress: return "Stress"
        case .analogClock: return "Analog Clock"
        case .summary: return "Results Summary"
        }
    }

    var instruction: String {
        switch self {
        case .acceptChallenge:
            return "Enable the 'I Accept Challenge' toggle, then click Next."
        case .textEntry:
            return "Type launch code delta-42 in the Message field, click Send, then click Next."
        case .modalTask:
            return
                "Open the approval sheet, type Rivera in the reviewer field, choose Approve, confirm the sheet, then click Next."
        case .selectionControls:
            return
                "Choose Charlie from the popup menu, choose Three in the radio group, enable the checkbox, then click Next."
        case .tableList:
            return "Select table cell 13 and list row Gamma, then click Next."
        case .numericControls:
            return
                "Set the slider between 70 and 80 and the stepper between 3 and 5, then click Next."
        case .contextMenu:
            return "Right-click the Context Target and choose Archive, then click Next."
        case .keyboardShortcut:
            return
                "Click Start Shortcut Capture, press Command+Shift+M in the shortcut test area, then click Next."
        case .textEditing:
            return
                "In the notes editor, make the text exactly: Alpha beta gamma. Then double-click the Word Target and triple-click the Paragraph Target before clicking Next."
        case .scrollTask:
            return "Scroll the list, click Hidden Target 18, then click Next."
        case .pointerTask:
            return "Drag the Drag Source onto the Drop Target, then click Next."
        case .stress:
            return
                "Set the popup to Delta, type final check in the small field, select cell 24, enable Ready, click the lower Confirm button, then click Next."
        case .analogClock:
            return "Drag each hand to set the clock to 9:00:15, then click Next."
        case .summary:
            return "Review your overall performance in the UI Challenge."
        }
    }
}

final class LevelController: ObservableObject {
    @Published var currentLevel: LevelID = .acceptChallenge
    @Published var showValidationDetails = false
    @Published var testResults: [String: Bool] = [:]

    @Published var challengeAccepted = false { didSet { updateResults() } }
    @Published var messageText = "" { didSet { updateResults() } }
    @Published var messageSent = false { didSet { updateResults() } }
    @Published var selectedPopup = "Alpha" { didSet { updateResults() } }
    @Published var selectedRadio = "One" { didSet { updateResults() } }
    @Published var checkboxEnabled = false { didSet { updateResults() } }
    @Published var sliderValue = 50.0 { didSet { updateResults() } }
    @Published var stepperValue = 0 { didSet { updateResults() } }
    @Published var scrollTargetClicked = false { didSet { updateResults() } }
    @Published var modalReviewer = "" { didSet { updateResults() } }
    @Published var modalDecision = "Review" { didSet { updateResults() } }
    @Published var modalConfirmed = false { didSet { updateResults() } }
    @Published var contextChoice = "" { didSet { updateResults() } }
    @Published var notesText = "" { didSet { updateResults() } }
    @Published var wordDoubleClicked = false { didSet { updateResults() } }
    @Published var paragraphTripleClicked = false { didSet { updateResults() } }
    @Published var selectedCell: Int? { didSet { updateResults() } }
    @Published var selectedListRow = "" { didSet { updateResults() } }
    @Published var shortcutCaptureRequest = 0 { didSet { updateResults() } }
    @Published var shortcutPressed = "" { didSet { updateResults() } }
    @Published var dropReceived = false { didSet { updateResults() } }
    @Published var dropIsTargeted = false { didSet { updateResults() } }
    @Published var stressPopup = "Alpha" { didSet { updateResults() } }
    @Published var stressText = "" { didSet { updateResults() } }
    @Published var stressCell: Int? { didSet { updateResults() } }
    @Published var stressReady = false { didSet { updateResults() } }
    @Published var stressLowerConfirmClicked = false { didSet { updateResults() } }
    @Published var clockHour: Int = 3 { didSet { updateResults() } }
    @Published var clockMinute: Int = 30 { didSet { updateResults() } }
    @Published var clockSecond: Int = 45 { didSet { updateResults() } }

    init() {
        updateResults()
    }

    var currentScore: (met: Int, total: Int) {
        let requirements = levelRequirements(for: currentLevel)
        let met = requirements.filter { testResults[$0] == true }.count
        return (met, requirements.count)
    }

    var totalScore: (met: Int, total: Int) {
        var totalMet = 0
        var totalPossible = 0
        for level in LevelID.allCases {
            if level == .summary { continue }
            let requirements = levelRequirements(for: level)
            totalPossible += requirements.count
            totalMet += requirements.filter { checkRequirement(level: level, requirement: $0) }.count
        }
        return (totalMet, totalPossible)
    }

    var scoreReport: String {
        if currentLevel == .summary {
            let total = totalScore
            return "Final Score: \(total.met)/\(total.total)"
        }
        let current = currentScore
        let total = totalScore
        return "Level: \(currentLevel.number)/\(LevelID.allCases.count) | Level Score: \(current.met)/\(current.total) | Total Score: \(total.met)/\(total.total)"
    }

    func updateResults() {
        if currentLevel == .summary {
            testResults = [:]
            return
        }
        let requirements = levelRequirements(for: currentLevel)
        var newResults: [String: Bool] = [:]
        for req in requirements {
            newResults[req] = checkRequirement(level: currentLevel, requirement: req)
        }
        testResults = newResults
    }

    func restart(logger: ActionLogger) {
        currentLevel = .acceptChallenge
        resetStateForAllLevels()
        logger.log("Level", "Restarted challenge.")
    }

    func jump(to level: LevelID, logger: ActionLogger) {
        currentLevel = level
        updateResults()
        logger.log("Level", "Jumped to Level \(level.number): \(level.title).")
    }

    func resetCurrentLevel(logger: ActionLogger) {
        resetState(for: currentLevel)
        logger.log("Level", "Current level reset.")
    }

    func nextLevel(logger: ActionLogger) {
        if let next = LevelID(rawValue: currentLevel.rawValue + 1) {
            currentLevel = next
            updateResults()
            logger.log("Level", "Advanced to Level \(next.number).")
        }
    }

    func previousLevel(logger: ActionLogger) {
        if let prev = LevelID(rawValue: currentLevel.rawValue - 1) {
            currentLevel = prev
            updateResults()
            logger.log("Level", "Went back to Level \(prev.number).")
        }
    }

    private func resetStateForAllLevels() {
        for level in LevelID.allCases {
            resetState(for: level)
        }
    }

    private func resetState(for level: LevelID) {
        switch level {
        case .acceptChallenge: challengeAccepted = false
        case .textEntry: messageText = ""; messageSent = false
        case .modalTask: modalReviewer = ""; modalDecision = "Review"; modalConfirmed = false
        case .selectionControls: selectedPopup = "Alpha"; selectedRadio = "One"; checkboxEnabled = false
        case .tableList: selectedCell = nil; selectedListRow = ""
        case .numericControls: sliderValue = 50; stepperValue = 0
        case .contextMenu: contextChoice = ""
        case .keyboardShortcut: shortcutCaptureRequest = 0; shortcutPressed = ""
        case .textEditing: notesText = ""; wordDoubleClicked = false; paragraphTripleClicked = false
        case .scrollTask: scrollTargetClicked = false
        case .pointerTask: dropReceived = false; dropIsTargeted = false
        case .stress: stressPopup = "Alpha"; stressText = ""; stressCell = nil; stressReady = false; stressLowerConfirmClicked = false
        case .analogClock: clockHour = 3; clockMinute = 30; clockSecond = 45
        case .summary: break
        }
        updateResults()
    }

    func levelRequirements(for level: LevelID) -> [String] {
        switch level {
        case .acceptChallenge: return ["I Accept Challenge enabled"]
        case .textEntry: return ["Message is 'launch code delta-42'", "Send clicked"]
        case .modalTask: return ["Reviewer is Rivera", "Decision is Approve", "Sheet confirmed"]
        case .selectionControls: return ["Popup is Charlie", "Radio is Three", "Checkbox enabled"]
        case .tableList: return ["Cell 13 selected", "Row Gamma selected"]
        case .numericControls: return ["Slider 70-80", "Stepper 3-5"]
        case .contextMenu: return ["Choice is Archive"]
        case .keyboardShortcut: return ["Cmd+Shift+M pressed"]
        case .textEditing: return ["Text is 'Alpha beta gamma.'", "Word double-clicked", "Paragraph triple-clicked"]
        case .scrollTask: return ["Target 18 clicked"]
        case .pointerTask: return ["Drag and drop complete"]
        case .stress: return ["Popup Delta", "Text 'final check'", "Cell 24", "Ready enabled", "Lower Confirm clicked"]
        case .analogClock: return ["Hour is 9", "Minute is 0", "Second is 15"]
        case .summary: return []
        }
    }

    func checkRequirement(level: LevelID, requirement: String) -> Bool {
        switch level {
        case .acceptChallenge:
            return challengeAccepted
        case .textEntry:
            if requirement.contains("Message") { return messageText == "launch code delta-42" }
            return messageSent
        case .modalTask:
            if requirement.contains("Reviewer") { return modalReviewer == "Rivera" }
            if requirement.contains("Decision") { return modalDecision == "Approve" }
            return modalConfirmed
        case .selectionControls:
            if requirement.contains("Popup") { return selectedPopup == "Charlie" }
            if requirement.contains("Radio") { return selectedRadio == "Three" }
            return checkboxEnabled
        case .tableList:
            if requirement.contains("Cell") { return selectedCell == 13 }
            return selectedListRow == "Gamma"
        case .numericControls:
            if requirement.contains("Slider") { return (70...80).contains(Int(sliderValue)) }
            return (3...5).contains(stepperValue)
        case .contextMenu:
            return contextChoice == "Archive"
        case .keyboardShortcut:
            return shortcutPressed == "Pressed Command+Shift+M"
        case .textEditing:
            if requirement.contains("Text") { return notesText == "Alpha beta gamma." }
            if requirement.contains("Word") { return wordDoubleClicked }
            return paragraphTripleClicked
        case .scrollTask:
            return scrollTargetClicked
        case .pointerTask:
            return dropReceived
        case .stress:
            if requirement.contains("Popup") { return stressPopup == "Delta" }
            if requirement.contains("Text") { return stressText == "final check" }
            if requirement.contains("Cell") { return stressCell == 24 }
            if requirement.contains("Ready") { return stressReady }
            return stressLowerConfirmClicked
        case .analogClock:
            if requirement.contains("Hour") { return clockHour == 9 }
            if requirement.contains("Minute") { return clockMinute == 0 }
            return clockSecond == 15
        case .summary:
            return true
        }
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
    @EnvironmentObject private var levels: LevelController
    @State private var showingApprovalSheet = false

    private let popupOptions = ["Alpha", "Bravo", "Charlie", "Delta"]
    private let radioOptions = ["One", "Two", "Three"]
    private let columns = Array(repeating: GridItem(.fixed(54), spacing: 8), count: 5)
    private let listRows = ["Alpha", "Bravo", "Gamma", "Delta", "Epsilon"]

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                levelHeader
                levelBody
                navigationAndRequirements
            }
            .frame(minWidth: 300, alignment: .topLeading)

            LogPanel()
                .frame(minWidth: 200)
                .frame(height: 450)
        }
        .padding(20)
        .fixedSize()
    }

    private var levelHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Level \(levels.currentLevel.number): \(levels.currentLevel.title)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text(levels.scoreReport)
                    .font(.headline.monospacedDigit())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
            }

            Text(levels.currentLevel.instruction)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
        }
    }

    @ViewBuilder
    private var levelBody: some View {
        switch levels.currentLevel {
        case .acceptChallenge: acceptChallengeLevel
        case .textEntry: textEntryLevel
        case .modalTask: modalTaskLevel
        case .selectionControls: selectionControlsLevel
        case .tableList: tableListLevel
        case .numericControls: numericControlsLevel
        case .contextMenu: contextMenuLevel
        case .keyboardShortcut: keyboardShortcutLevel
        case .textEditing: textEditingLevel
        case .scrollTask: scrollTaskLevel
        case .pointerTask: pointerTaskLevel
        case .stress: stressLevel
        case .analogClock: analogClockLevel
        case .summary: summaryLevel
        }
    }

    private var navigationAndRequirements: some View {
        VStack(alignment: .leading, spacing: 12) {
            if levels.currentLevel != .summary {
                GroupBox("Requirements Status") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(levels.testResults.keys.sorted(), id: \.self) { key in
                            HStack {
                                Image(
                                    systemName: levels.testResults[key] == true
                                        ? "checkmark.circle.fill" : "circle"
                                )
                                .foregroundColor(
                                    levels.testResults[key] == true ? .green : .secondary
                                )
                                Text(key)
                                    .strikethrough(levels.testResults[key] == true)
                                    .foregroundColor(
                                        levels.testResults[key] == true ? .secondary : .primary)
                            }
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack {
                Button("Previous") {
                    levels.previousLevel(logger: logger)
                }
                .disabled(levels.currentLevel.rawValue == 0)

                Button("Next") {
                    levels.nextLevel(logger: logger)
                }
                .disabled(levels.currentLevel.rawValue == LevelID.allCases.count - 1)

                Spacer()

                Button("Reset Level") {
                    levels.resetCurrentLevel(logger: logger)
                }
            }
        }
    }

    private var summaryLevel: some View {
        GroupBox("Performance Summary") {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("Lvl").frame(width: 30, alignment: .leading)
                    Text("Short Test Name").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Pass").frame(width: 70, alignment: .leading)
                }
                .font(.headline)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.secondary.opacity(0.1))

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(LevelID.allCases.filter { $0 != .summary }) { level in
                            let requirements = levels.levelRequirements(for: level)
                            ForEach(requirements, id: \.self) { req in
                                let pass = levels.checkRequirement(level: level, requirement: req)
                                HStack(spacing: 0) {
                                    Text("\(level.number)").frame(width: 30, alignment: .leading)
                                    Text(req).frame(maxWidth: .infinity, alignment: .leading)
                                    HStack(spacing: 4) {
                                        Image(
                                            systemName: pass
                                                ? "checkmark.circle.fill" : "xmark.circle.fill"
                                        )
                                        .foregroundColor(pass ? .green : .red)
                                        Text(pass ? "Pass" : "Fail")
                                    }
                                    .frame(width: 70, alignment: .leading)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)

                                Divider()
                            }
                        }
                    }
                }
            }
            .frame(height: 380)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private var acceptChallengeLevel: some View {
        GroupBox("Challenge") {
            VStack(alignment: .leading, spacing: 20) {
                Text("This test harness validates VOCR computer-use capabilities across various macOS UI controls.")
                    .font(.body)

                Toggle("I Accept Challenge", isOn: $levels.challengeAccepted)
                    .toggleStyle(.button)
                    .font(.headline)
                    .padding()
                    .accessibilityLabel("I Accept Challenge")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var textEntryLevel: some View {
        GroupBox("Message") {
            HStack(spacing: 10) {
                TextField("Message", text: $levels.messageText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Message")
                    .onChange(of: levels.messageText) { _ in
                        levels.messageSent = false
                        logger.log("Text", "Message field changed.")
                    }

                Button("Send") {
                    levels.messageSent = true
                    logger.log("Button", "Send clicked.")
                }
                .keyboardShortcut(.return, modifiers: [])
                .accessibilityLabel("Send")
            }
        }
    }

    private var selectionControlsLevel: some View {
        GroupBox("Popup Menu, Radio Box, and Checkbox") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Popup Menu", selection: $levels.selectedPopup) {
                    ForEach(popupOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Options")
                .onChange(of: levels.selectedPopup) { value in
                    logger.log("Popup", "Selected \(value).")
                }

                Picker("Radio Box", selection: $levels.selectedRadio) {
                    ForEach(radioOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.radioGroup)
                .accessibilityLabel("Choice")
                .onChange(of: levels.selectedRadio) { value in
                    logger.log("Radio", "Selected \(value).")
                }

                Toggle("Enable Checkbox", isOn: $levels.checkboxEnabled)
                    .accessibilityLabel("Enable")
                    .onChange(of: levels.checkboxEnabled) { value in
                        logger.log("Checkbox", value ? "Checked." : "Unchecked.")
                    }
            }
            .padding(.vertical, 4)
        }
    }

    private var numericControlsLevel: some View {
        GroupBox("Numeric Controls") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Slider Value: \(Int(levels.sliderValue))")
                Slider(value: $levels.sliderValue, in: 0...100, step: 1)
                    .accessibilityLabel("Value")
                    .accessibilityValue("\(Int(levels.sliderValue))")
                    .onChange(of: levels.sliderValue) { value in
                        logger.log("Slider", "Changed to \(Int(value)).")
                    }

                Stepper(
                    "Stepper Value: \(levels.stepperValue)", value: $levels.stepperValue, in: 0...10
                )
                .accessibilityLabel("Stepper Value")
                .onChange(of: levels.stepperValue) { value in
                    logger.log("Stepper", "Changed to \(value).")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var scrollTaskLevel: some View {
        GroupBox("Scrollable Targets") {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(1...24, id: \.self) { index in
                        Button(index == 18 ? "Hidden Target 18" : "Practice Target \(index)") {
                            if index == 18 {
                                levels.scrollTargetClicked = true
                                logger.log("Scroll", "Hidden Target 18 clicked.")
                            } else {
                                logger.log("Scroll", "Practice Target \(index) clicked.")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(
                            index == 18 ? "Hidden Target 18" : "Practice Target \(index)")
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(height: 240)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        }
    }

    private var modalTaskLevel: some View {
        GroupBox("Approval Sheet") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Reviewer: \(levels.modalReviewer.isEmpty ? "None" : levels.modalReviewer)")
                Text("Decision: \(levels.modalDecision)")
                Text("Confirmed: \(levels.modalConfirmed ? "Yes" : "No")")

                Button("Open Approval Sheet") {
                    showingApprovalSheet = true
                    logger.log("Modal", "Approval sheet opened.")
                }
                .accessibilityLabel("Open Approval Sheet")
            }
            .sheet(isPresented: $showingApprovalSheet) {
                approvalSheet
            }
        }
    }

    private var approvalSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Approval Sheet")
                .font(.title3)
                .fontWeight(.semibold)

            TextField("Reviewer", text: $levels.modalReviewer)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Reviewer")

            Picker("Decision", selection: $levels.modalDecision) {
                Text("Review").tag("Review")
                Text("Approve").tag("Approve")
                Text("Reject").tag("Reject")
            }
            .pickerStyle(.radioGroup)
            .accessibilityLabel("Decision")

            HStack {
                Spacer()
                Button("Cancel") {
                    showingApprovalSheet = false
                    logger.log("Modal", "Approval sheet canceled.")
                }
                Button("Confirm") {
                    levels.modalConfirmed = true
                    showingApprovalSheet = false
                    logger.log("Modal", "Approval sheet confirmed.")
                }
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private var contextMenuLevel: some View {
        GroupBox("Context Menu") {
            Text("Context Target")
                .font(.headline)
                .frame(width: 220, height: 72)
                .background(Color(nsColor: .controlBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary, lineWidth: 2))
                .cornerRadius(8)
                .accessibilityLabel("Context Target")
                .contextMenu {
                    Button("Open") {
                        levels.contextChoice = "Open"
                        logger.log("Context Menu", "Open selected.")
                    }
                    Button("Archive") {
                        levels.contextChoice = "Archive"
                        logger.log("Context Menu", "Archive selected.")
                    }
                    Button("Delete") {
                        levels.contextChoice = "Delete"
                        logger.log("Context Menu", "Delete selected.")
                    }
                }
        }
    }

    private var textEditingLevel: some View {
        GroupBox("Text Editing") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $levels.notesText)
                    .font(.body)
                    .frame(height: 110)
                    .border(Color.secondary.opacity(0.5))
                    .accessibilityLabel("Notes Editor")
                    .onChange(of: levels.notesText) { _ in
                        logger.log("Text", "Notes editor changed.")
                    }

                HStack(spacing: 16) {
                    Text("Word Target")
                        .font(.headline)
                        .frame(width: 150, height: 46)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                        .accessibilityLabel("Word Target")
                        .onTapGesture(count: 2) {
                            levels.wordDoubleClicked = true
                            logger.log("Text", "Word Target double-clicked.")
                        }

                    Text("Paragraph Target")
                        .font(.headline)
                        .frame(width: 180, height: 46)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                        .accessibilityLabel("Paragraph Target")
                        .onTapGesture(count: 3) {
                            levels.paragraphTripleClicked = true
                            logger.log("Text", "Paragraph Target triple-clicked.")
                        }
                }
            }
        }
    }

    private var tableListLevel: some View {
        GroupBox("Table and List") {
            HStack(alignment: .top, spacing: 18) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(1...25, id: \.self) { number in
                        Button {
                            levels.selectedCell = number
                            logger.log("Table", "Selected cell \(number).")
                        } label: {
                            Text("\(number)")
                                .font(.headline)
                                .frame(width: 54, height: 42)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .accessibilityLabel("Cell \(number)")
                        .background(
                            levels.selectedCell == number
                                ? Color.accentColor.opacity(0.18) : Color.clear
                        )
                        .cornerRadius(6)
                    }
                }

                List(listRows, id: \.self, selection: $levels.selectedListRow) { row in
                    Text(row)
                }
                .frame(width: 150, height: 240)
                .accessibilityLabel("Rows")
                .onChange(of: levels.selectedListRow) { row in
                    if !row.isEmpty {
                        logger.log("List", "Selected row \(row).")
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var pointerTaskLevel: some View {
        GroupBox("Drag and Drop") {
            HStack(spacing: 28) {
                dragSource
                dropTarget
            }
            .padding(.vertical, 8)
        }
    }

    private var keyboardShortcutLevel: some View {
        GroupBox("Shortcut Test") {
            VStack(alignment: .leading, spacing: 8) {
                Button("Start Shortcut Capture") {
                    levels.shortcutCaptureRequest += 1
                    levels.shortcutPressed = ""
                    logger.log("Shortcut", "Shortcut capture started.")
                }
                .accessibilityLabel("Start Shortcut Capture")

                ShortcutCaptureView(focusRequest: levels.shortcutCaptureRequest) { description in
                    levels.shortcutPressed = description
                    logger.log("Shortcut", description)
                }
                .frame(height: 78)
                .accessibilityLabel("Shortcut Test Area")
            }
        }
    }

    private var dragSource: some View {
        Text("Drag Source")
            .font(.headline)
            .frame(width: 150, height: 54)
            .background(Color.accentColor.opacity(0.18))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 2))
            .cornerRadius(8)
            .accessibilityLabel("Drag Source")
            .onDrag {
                logger.log("Drag", "Drag Source drag started.")
                return NSItemProvider(object: "Drag Source" as NSString)
            }
    }

    private var dropTarget: some View {
        Text("Drop Target")
            .font(.headline)
            .frame(width: 150, height: 54)
            .background(
                levels.dropIsTargeted ? Color.green.opacity(0.28) : Color.secondary.opacity(0.12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(
                    levels.dropIsTargeted ? Color.green : Color.secondary, lineWidth: 2)
            )
            .cornerRadius(8)
            .accessibilityLabel("Drop Target")
            .onDrop(
                of: [.plainText],
                isTargeted: Binding(
                    get: { levels.dropIsTargeted },
                    set: { value in
                        levels.dropIsTargeted = value
                        logger.log(
                            "Drag", value ? "Drag entered Drop Target." : "Drag exited Drop Target."
                        )
                    }
                )
            ) { providers in
                levels.dropReceived = true
                logger.log("Drop", "Drop Target received \(providers.count) item(s).")
                return true
            }
    }

    private var analogClockLevel: some View {
        GroupBox("Analog Clock") {
            VStack(spacing: 16) {
                Text(String(format: "%d:%02d:%02d", levels.clockHour, levels.clockMinute, levels.clockSecond))
                    .font(.system(size: 36, weight: .medium, design: .monospaced))
                    .accessibilityLabel("Clock Time")
                    .accessibilityValue(String(format: "%d:%02d:%02d", levels.clockHour, levels.clockMinute, levels.clockSecond))

                AnalogClockWidget(
                    hour: $levels.clockHour,
                    minute: $levels.clockMinute,
                    second: $levels.clockSecond
                ) {
                    logger.log(
                        "Clock",
                        String(format: "Time set to %d:%02d:%02d", levels.clockHour, levels.clockMinute, levels.clockSecond)
                    )
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    private var stressLevel: some View {
        GroupBox("Crowded Mixed Controls") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Button("Confirm") {
                        logger.log("Stress", "Upper Confirm clicked.")
                    }
                    Button("Confirm") {
                        logger.log("Stress", "Middle Confirm clicked.")
                    }
                    Button("Confirm") {
                        levels.stressLowerConfirmClicked = true
                        logger.log("Stress", "Lower Confirm clicked.")
                    }
                    .accessibilityLabel("Lower Confirm")
                }

                HStack {
                    Picker("Stress Popup", selection: $levels.stressPopup) {
                        ForEach(popupOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Stress Popup")

                    TextField("Small Field", text: $levels.stressText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                        .accessibilityLabel("Small Field")

                    Toggle("Ready", isOn: $levels.stressReady)
                        .accessibilityLabel("Ready")
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(21...25, id: \.self) { number in
                        Button("Cell \(number)") {
                            levels.stressCell = number
                            logger.log("Stress", "Selected cell \(number).")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Stress Cell \(number)")
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct LogPanel: View {
    @EnvironmentObject private var logger: ActionLogger

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Visible Log")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button("Clear") {
                    logger.clear()
                    logger.log("Button", "Clear Log clicked.")
                }
                .accessibilityLabel("Clear")
            }

            ScrollView {
                Text(logger.fullLogText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .textSelection(.enabled)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Visible Log")
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

struct AnalogClockWidget: View {
    @Binding var hour: Int
    @Binding var minute: Int
    @Binding var second: Int
    let onChange: () -> Void

    private let size: CGFloat = 220
    private var center: CGFloat { size / 2 }
    private var radius: CGFloat { size / 2 - 8 }

    private var hourAngle: Double {
        (Double(hour % 12) / 12.0 + Double(minute) / 720.0) * 2 * .pi
    }
    private var minuteAngle: Double { Double(minute) / 60.0 * 2 * .pi }
    private var secondAngle: Double { Double(second) / 60.0 * 2 * .pi }

    private func tip(angle: Double, length: CGFloat) -> CGPoint {
        CGPoint(
            x: center + CGFloat(sin(angle)) * length,
            y: center - CGFloat(cos(angle)) * length
        )
    }

    private func clockAngle(from location: CGPoint) -> Double {
        let dx = Double(location.x - center)
        let dy = Double(location.y - center)
        var a = atan2(dx, -dy)
        if a < 0 { a += 2 * .pi }
        return a
    }

    var body: some View {
        ZStack {
            Canvas { ctx, canvasSize in
                let c = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let r = min(canvasSize.width, canvasSize.height) / 2 - 8

                // Face
                let faceRect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: faceRect), with: .color(Color(nsColor: .windowBackgroundColor)))
                ctx.stroke(Path(ellipseIn: faceRect), with: .color(.secondary.opacity(0.5)), lineWidth: 2)

                // Tick marks
                for i in 0..<60 {
                    let a = Double(i) * 2 * .pi / 60 - .pi / 2
                    let major = i % 5 == 0
                    var tick = Path()
                    tick.move(to: CGPoint(x: c.x + cos(a) * (r - (major ? 10 : 5)), y: c.y + sin(a) * (r - (major ? 10 : 5))))
                    tick.addLine(to: CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r))
                    ctx.stroke(tick, with: .color(major ? .primary : .secondary.opacity(0.4)),
                               style: StrokeStyle(lineWidth: major ? 2 : 1))
                }

                // Hour numbers
                for h in 1...12 {
                    let a = Double(h) * 2 * .pi / 12 - .pi / 2
                    ctx.draw(
                        Text("\(h)").font(.system(size: 11, weight: .medium)),
                        at: CGPoint(x: c.x + cos(a) * (r - 18), y: c.y + sin(a) * (r - 18))
                    )
                }

                // Hour hand
                var hPath = Path()
                hPath.move(to: c)
                hPath.addLine(to: CGPoint(
                    x: c.x + CGFloat(sin(hourAngle)) * r * 0.55,
                    y: c.y - CGFloat(cos(hourAngle)) * r * 0.55
                ))
                ctx.stroke(hPath, with: .color(.primary), style: StrokeStyle(lineWidth: 6, lineCap: .round))

                // Minute hand
                var mPath = Path()
                mPath.move(to: c)
                mPath.addLine(to: CGPoint(
                    x: c.x + CGFloat(sin(minuteAngle)) * r * 0.75,
                    y: c.y - CGFloat(cos(minuteAngle)) * r * 0.75
                ))
                ctx.stroke(mPath, with: .color(.primary), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))

                // Second hand with tail
                var sPath = Path()
                sPath.move(to: CGPoint(
                    x: c.x - CGFloat(sin(secondAngle)) * r * 0.15,
                    y: c.y + CGFloat(cos(secondAngle)) * r * 0.15
                ))
                sPath.addLine(to: CGPoint(
                    x: c.x + CGFloat(sin(secondAngle)) * r * 0.88,
                    y: c.y - CGFloat(cos(secondAngle)) * r * 0.88
                ))
                ctx.stroke(sPath, with: .color(.red), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                // Center cap
                ctx.fill(
                    Path(ellipseIn: CGRect(x: c.x - 5, y: c.y - 5, width: 10, height: 10)),
                    with: .color(.primary)
                )
            }

            // Hour hand drag handle
            let hTip = tip(angle: hourAngle, length: radius * 0.55)
            Circle()
                .fill(Color.primary.opacity(0.65))
                .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .position(hTip)
                .accessibilityLabel("Hour Hand")
                .accessibilityValue("\(hour) o'clock")
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("clockFace"))
                        .onChanged { v in
                            let a = clockAngle(from: v.location)
                            let h = Int(round(a / (2 * .pi / 12))) % 12
                            hour = h == 0 ? 12 : h
                            onChange()
                        }
                )

            // Minute hand drag handle
            let mTip = tip(angle: minuteAngle, length: radius * 0.75)
            Circle()
                .fill(Color.gray.opacity(0.7))
                .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                .frame(width: 40, height: 40)
                .contentShape(Circle())
                .position(mTip)
                .accessibilityLabel("Minute Hand")
                .accessibilityValue("\(minute) minutes")
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("clockFace"))
                        .onChanged { v in
                            let a = clockAngle(from: v.location)
                            minute = Int(round(a / (2 * .pi / 60))) % 60
                            onChange()
                        }
                )

            // Second hand drag handle
            let sTip = tip(angle: secondAngle, length: radius * 0.88)
            Circle()
                .fill(Color.red.opacity(0.8))
                .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                .frame(width: 36, height: 36)
                .contentShape(Circle())
                .position(sTip)
                .accessibilityLabel("Second Hand")
                .accessibilityValue("\(second) seconds")
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("clockFace"))
                        .onChanged { v in
                            let a = clockAngle(from: v.location)
                            second = Int(round(a / (2 * .pi / 60))) % 60
                            onChange()
                        }
                )
        }
        .frame(width: size, height: size)
        .coordinateSpace(name: "clockFace")
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Analog Clock")
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
