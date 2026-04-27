import AppKit
import Carbon
import SwiftUI

@main
struct UIChallengeApp: App {
    @StateObject private var logger = ActionLogger()
    @StateObject private var computerUse = ComputerUseRunner()
    @StateObject private var levels = LevelController()
    private let launchPrompt = LaunchArguments.prompt

    var body: some Scene {
        WindowGroup("UI Challenge") {
            ContentView()
                .environmentObject(logger)
                .environmentObject(computerUse)
                .environmentObject(levels)
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

            CommandMenu("Levels") {
                Button("Restart From Level 1") {
                    levels.restart(logger: logger)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])

                Button("Reset Current Level") {
                    levels.resetCurrentLevel(logger: logger)
                }
                .keyboardShortcut("r", modifiers: [.command, .option])

                Toggle("Show Validation Details in UI", isOn: $levels.showValidationDetails)

                Divider()

                ForEach(LevelID.allCases) { level in
                    Button("\(level.number). \(level.title)") {
                        levels.jump(to: level, logger: logger)
                    }
                }
            }
        }
    }

    private func maximizeWindow() {
        guard let window = NSApp.windows.first(where: { $0.title == "UI Challenge" })
        else {
            return
        }

        if let screen = window.screen ?? NSScreen.main {
            window.setFrame(screen.visibleFrame, display: true, animate: true)
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
        debugPrint("[\(entry.timestamp)] \(category): \(message)")
    }

    func developerLog(_ category: String, _ message: String) {
        let timestamp = formatter.string(from: Date())
        debugPrint("[\(timestamp)] \(category): \(message)")
    }

    func clear() {
        entries.removeAll()
        fullLogText = ""
        log("Log", "Cleared")
    }
}

enum LevelID: Int, CaseIterable, Identifiable {
    case basicClick = 0
    case textEntry
    case selectionControls
    case numericControls
    case scrollTask
    case modalTask
    case contextMenu
    case textEditing
    case tableList
    case keyboardShortcut
    case pointerTask
    case stress

    var id: Int { rawValue }
    var number: Int { rawValue + 1 }

    var title: String {
        switch self {
        case .basicClick: return "Basic Click"
        case .textEntry: return "Text Entry"
        case .selectionControls: return "Selection Controls"
        case .numericControls: return "Numeric Controls"
        case .scrollTask: return "Scroll"
        case .modalTask: return "Modal"
        case .contextMenu: return "Context Menu"
        case .textEditing: return "Text Editing"
        case .tableList: return "Table and List"
        case .keyboardShortcut: return "Keyboard Shortcut"
        case .pointerTask: return "Pointer Actions"
        case .stress: return "Stress"
        }
    }

    var instruction: String {
        switch self {
        case .basicClick:
            return "Click the Verify Access button, then click Next."
        case .textEntry:
            return "Type launch code delta-42 in the Message field, click Send, then click Next."
        case .selectionControls:
            return
                "Choose Charlie from the popup menu, choose Three in the radio group, enable the checkbox, then click Next."
        case .numericControls:
            return
                "Set the slider between 70 and 80 and the stepper between 3 and 5, then click Next."
        case .scrollTask:
            return "Scroll the list, click Hidden Target 18, then click Next."
        case .modalTask:
            return
                "Open the approval sheet, type Rivera in the reviewer field, choose Approve, confirm the sheet, then click Next."
        case .contextMenu:
            return "Right-click the Context Target and choose Archive, then click Next."
        case .textEditing:
            return
                "In the notes editor, make the text exactly: Alpha beta gamma. Then double-click the Word Target and triple-click the Paragraph Target before clicking Next."
        case .tableList:
            return "Select table cell 13 and list row Gamma, then click Next."
        case .keyboardShortcut:
            return
                "Click Start Shortcut Capture, press Command+Shift+M in the shortcut test area, then click Next."
        case .pointerTask:
            return "Drag the Drag Source onto the Drop Target, then click Next."
        case .stress:
            return
                "Set the popup to Delta, type final check in the small field, select cell 24, enable Ready, click the lower Confirm button, then click Next."
        }
    }
}

final class LevelController: ObservableObject {
    @Published var currentLevel: LevelID = .basicClick
    @Published var validationMessage = ""
    @Published var showValidationDetails = false

    @Published var basicClicked = false
    @Published var messageText = ""
    @Published var messageSent = false
    @Published var selectedPopup = "Alpha"
    @Published var selectedRadio = "One"
    @Published var checkboxEnabled = false
    @Published var sliderValue = 50.0
    @Published var stepperValue = 0
    @Published var scrollTargetClicked = false
    @Published var modalReviewer = ""
    @Published var modalDecision = "Review"
    @Published var modalConfirmed = false
    @Published var contextChoice = ""
    @Published var notesText = ""
    @Published var wordDoubleClicked = false
    @Published var paragraphTripleClicked = false
    @Published var selectedCell: Int?
    @Published var selectedListRow = ""
    @Published var shortcutCaptureRequest = 0
    @Published var shortcutPressed = ""
    @Published var dropReceived = false
    @Published var dropIsTargeted = false
    @Published var stressPopup = "Alpha"
    @Published var stressText = ""
    @Published var stressCell: Int?
    @Published var stressReady = false
    @Published var stressLowerConfirmClicked = false

    var currentScore: (met: Int, total: Int) {
        let total = requirementCount(for: currentLevel)
        return (total - missingRequirements(for: currentLevel).count, total)
    }

    var completedLevelCount: Int {
        currentLevel.rawValue
    }

    var totalLevelCount: Int {
        LevelID.allCases.count
    }

    var cumulativeScore: (met: Int, total: Int) {
        let completedScore = LevelID.allCases
            .filter { $0.rawValue < currentLevel.rawValue }
            .reduce(0) { total, level in
                total + requirementCount(for: level)
            }
        let current = currentScore
        let totalScore = LevelID.allCases.reduce(0) { total, level in
            total + requirementCount(for: level)
        }
        return (completedScore + current.met, totalScore)
    }

    var scoreText: String {
        let score = currentScore
        let cumulative = cumulativeScore
        return
            "Score: \(score.met)/\(score.total) | Total Score: \(cumulative.met)/\(cumulative.total) | Completed levels: \(completedLevelCount)/\(totalLevelCount)"
    }

    func restart(logger: ActionLogger) {
        currentLevel = .basicClick
        resetStateForCurrentLevel()
        logger.log("Level", "Restarted from Level 1.")
        logger.developerLog("Level", "Restarted from level 1")
    }

    func jump(to level: LevelID, logger: ActionLogger) {
        currentLevel = level
        resetStateForCurrentLevel()
        logger.log("Level", "Loaded Level \(level.number): \(level.title).")
        logger.developerLog("Level", "Jumped to level \(level.number): \(level.title)")
    }

    func resetCurrentLevel(logger: ActionLogger) {
        resetStateForCurrentLevel()
        logger.log("Level", "Current level reset.")
        logger.developerLog("Level", "Reset level \(currentLevel.number): \(currentLevel.title)")
    }

    func completeCurrentLevel(logger: ActionLogger) {
        let missing = missingRequirements(for: currentLevel)
        if missing.isEmpty {
            logger.log("Level", "Level complete.")
            logger.developerLog("Validation", "Level \(currentLevel.number) passed")
            validationMessage = "Level complete."
            advance(logger: logger)
        } else {
            let message = "Requirements not met. Check the instruction and current state."
            validationMessage =
                showValidationDetails
                ? "\(message) Missing: \(missing.joined(separator: "; "))" : message
            logger.log("Level", "Requirements not met.")
            logger.developerLog(
                "Validation",
                "Level \(currentLevel.number) failed: \(missing.joined(separator: "; ")); state: \(stateSummary(for: currentLevel))"
            )
        }
    }

    private func advance(logger: ActionLogger) {
        guard let next = LevelID(rawValue: currentLevel.rawValue + 1) else {
            logger.log("Level", "All levels complete.")
            logger.developerLog("Level", "All levels complete")
            return
        }

        currentLevel = next
        resetStateForCurrentLevel()
        logger.log("Level", "Advanced to Level \(next.number): \(next.title).")
        logger.developerLog("Level", "Advanced to level \(next.number): \(next.title)")
    }

    private func resetStateForCurrentLevel() {
        validationMessage = ""
        switch currentLevel {
        case .basicClick:
            basicClicked = false
        case .textEntry:
            messageText = ""
            messageSent = false
        case .selectionControls:
            selectedPopup = "Alpha"
            selectedRadio = "One"
            checkboxEnabled = false
        case .numericControls:
            sliderValue = 50
            stepperValue = 0
        case .scrollTask:
            scrollTargetClicked = false
        case .modalTask:
            modalReviewer = ""
            modalDecision = "Review"
            modalConfirmed = false
        case .contextMenu:
            contextChoice = ""
        case .textEditing:
            notesText = ""
            wordDoubleClicked = false
            paragraphTripleClicked = false
        case .tableList:
            selectedCell = nil
            selectedListRow = ""
        case .keyboardShortcut:
            shortcutCaptureRequest = 0
            shortcutPressed = ""
        case .pointerTask:
            dropReceived = false
            dropIsTargeted = false
        case .stress:
            stressPopup = "Alpha"
            stressText = ""
            stressCell = nil
            stressReady = false
            stressLowerConfirmClicked = false
        }
    }

    private func requirementCount(for level: LevelID) -> Int {
        switch level {
        case .basicClick, .scrollTask, .contextMenu, .keyboardShortcut, .pointerTask:
            return 1
        case .textEntry, .numericControls, .tableList:
            return 2
        case .selectionControls, .modalTask, .textEditing:
            return 3
        case .stress:
            return 5
        }
    }

    private func missingRequirements(for level: LevelID) -> [String] {
        switch level {
        case .basicClick:
            return basicClicked ? [] : ["Verify Access button was not clicked"]
        case .textEntry:
            return [
                messageText == "launch code delta-42"
                    ? nil : "Message field must equal launch code delta-42",
                messageSent ? nil : "Send button was not clicked",
            ].compactMap { $0 }
        case .selectionControls:
            return [
                selectedPopup == "Charlie" ? nil : "Popup must be Charlie",
                selectedRadio == "Three" ? nil : "Radio must be Three",
                checkboxEnabled ? nil : "Checkbox must be enabled",
            ].compactMap { $0 }
        case .numericControls:
            return [
                (70...80).contains(Int(sliderValue)) ? nil : "Slider must be between 70 and 80",
                (3...5).contains(stepperValue) ? nil : "Stepper must be between 3 and 5",
            ].compactMap { $0 }
        case .scrollTask:
            return scrollTargetClicked ? [] : ["Hidden Target 18 was not clicked"]
        case .modalTask:
            return [
                modalReviewer == "Rivera" ? nil : "Reviewer must be Rivera",
                modalDecision == "Approve" ? nil : "Decision must be Approve",
                modalConfirmed ? nil : "Approval sheet was not confirmed",
            ].compactMap { $0 }
        case .contextMenu:
            return contextChoice == "Archive" ? [] : ["Context menu choice must be Archive"]
        case .textEditing:
            return [
                notesText == "Alpha beta gamma."
                    ? nil : "Notes text must be exactly Alpha beta gamma.",
                wordDoubleClicked ? nil : "Word Target was not double-clicked",
                paragraphTripleClicked ? nil : "Paragraph Target was not triple-clicked",
            ].compactMap { $0 }
        case .tableList:
            return [
                selectedCell == 13 ? nil : "Cell 13 must be selected",
                selectedListRow == "Gamma" ? nil : "List row Gamma must be selected",
            ].compactMap { $0 }
        case .keyboardShortcut:
            return shortcutPressed == "Pressed Command+Shift+M"
                ? [] : ["Command+Shift+M must be pressed in the shortcut test area"]
        case .pointerTask:
            return dropReceived ? [] : ["Drag Source was not dropped on Drop Target"]
        case .stress:
            return [
                stressPopup == "Delta" ? nil : "Stress popup must be Delta",
                stressText == "final check" ? nil : "Small field must equal final check",
                stressCell == 24 ? nil : "Cell 24 must be selected",
                stressReady ? nil : "Ready must be enabled",
                stressLowerConfirmClicked ? nil : "Lower Confirm button must be clicked",
            ].compactMap { $0 }
        }
    }

    private func stateSummary(for level: LevelID) -> String {
        switch level {
        case .basicClick:
            return "basicClicked=\(basicClicked)"
        case .textEntry:
            return "messageText=\(messageText), messageSent=\(messageSent)"
        case .selectionControls:
            return
                "selectedPopup=\(selectedPopup), selectedRadio=\(selectedRadio), checkboxEnabled=\(checkboxEnabled)"
        case .numericControls:
            return "sliderValue=\(Int(sliderValue)), stepperValue=\(stepperValue)"
        case .scrollTask:
            return "scrollTargetClicked=\(scrollTargetClicked)"
        case .modalTask:
            return
                "modalReviewer=\(modalReviewer), modalDecision=\(modalDecision), modalConfirmed=\(modalConfirmed)"
        case .contextMenu:
            return "contextChoice=\(contextChoice)"
        case .textEditing:
            return
                "notesText=\(notesText), wordDoubleClicked=\(wordDoubleClicked), paragraphTripleClicked=\(paragraphTripleClicked)"
        case .tableList:
            return
                "selectedCell=\(String(describing: selectedCell)), selectedListRow=\(selectedListRow)"
        case .keyboardShortcut:
            return "shortcutPressed=\(shortcutPressed)"
        case .pointerTask:
            return "dropReceived=\(dropReceived)"
        case .stress:
            return
                "stressPopup=\(stressPopup), stressText=\(stressText), stressCell=\(String(describing: stressCell)), stressReady=\(stressReady), stressLowerConfirmClicked=\(stressLowerConfirmClicked)"
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
                validationFooter
            }
            .frame(width: 560, alignment: .topLeading)

            LogPanel()
                .frame(width: 360)
        }
        .padding(20)
    }

    private var levelHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Level \(levels.currentLevel.number): \(levels.currentLevel.title)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text(levels.scoreText)
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
        case .basicClick: basicClickLevel
        case .textEntry: textEntryLevel
        case .selectionControls: selectionControlsLevel
        case .numericControls: numericControlsLevel
        case .scrollTask: scrollTaskLevel
        case .modalTask: modalTaskLevel
        case .contextMenu: contextMenuLevel
        case .textEditing: textEditingLevel
        case .tableList: tableListLevel
        case .keyboardShortcut: keyboardShortcutLevel
        case .pointerTask: pointerTaskLevel
        case .stress: stressLevel
        }
    }

    private var validationFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !levels.validationMessage.isEmpty {
                Text(levels.validationMessage)
                    .font(.headline)
                    .foregroundColor(levels.validationMessage == "Level complete." ? .green : .red)
            }

            HStack {
                Button("Next") {
                    logger.log("Button", "Next clicked.")
                    levels.completeCurrentLevel(logger: logger)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .accessibilityLabel("Next")

                Button("Reset Level") {
                    levels.resetCurrentLevel(logger: logger)
                }
                .accessibilityLabel("Reset Level")

                Spacer()
            }
        }
    }

    private var basicClickLevel: some View {
        GroupBox("Basic") {
            Button("Verify Access") {
                levels.basicClicked = true
                logger.log("Button", "Verify Access clicked.")
            }
            .controlSize(.large)
            .accessibilityLabel("Verify Access")
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
