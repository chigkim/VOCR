//
//  Navigation.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa
import Foundation
import Vision

enum Navigation {

    enum Mode: Int, CaseIterable {
        case WINDOW = 0
        case VOCURSOR = 1
        case CAMERA = 2
        func next() -> Mode {
            let allCases = Mode.allCases
            let nextIndex = (self.rawValue + 1) % allCases.count
            return allCases[nextIndex]
        }

        func name() -> String {
            switch self {
            case .WINDOW:
                return NSLocalizedString(
                    "mode.window", value: "Window", comment: "Window mode name")
            case .VOCURSOR:
                return NSLocalizedString(
                    "mode.vocursor", value: "VOCursor", comment: "VOCursor mode name")
            case .CAMERA:
                return NSLocalizedString(
                    "mode.camera", value: "Camera", comment: "Camera mode name")
            }
        }
    }

    static var mode = Mode.WINDOW

    static var displayResults: [[Observation]] = []
    static var detectedBarcodes: [DetectedBarcode] = []
    static var cgPosition = CGPoint()
    static var cgSize = CGSize()
    static var cgImage: CGImage?
    static var windowName = NSLocalizedString(
        "navigation.unknown_window", value: "Unknown Window",
        comment: "Default window name when unknown")
    static var appName = NSLocalizedString(
        "navigation.unknown_app", value: "Unknown App", comment: "Default app name when unknown")
    static var l = -1
    static var w = -1
    static var c = -1
    /// True when the last `getWindow()` call ended because the user closed the Target Window alert.
    private(set) static var windowSelectionCancelled = false

    /// Bounding-box midY tolerance used when grouping observations into lines and sorting them.
    private static let lineBreakTolerance = 0.01

    static func getWindow() -> CGRect? {
        windowSelectionCancelled = false
        guard let currentApp = NSWorkspace.shared.frontmostApplication else {
            log("Failed to get frontmost application")
            return nil
        }
        appName =
            currentApp.localizedName
            ?? NSLocalizedString(
                "navigation.unknown_app", value: "Unknown App",
                comment: "Default app name when unknown")
        let windows = currentApp.windows()

        if windows.isEmpty {
            return nil
        }
        var window = currentApp.focusedWindow() ?? windows[0]
        if Settings.targetWindow && windows.count > 1 {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString(
                "navigation.target_window", value: "Target Window",
                comment: "Alert title for choosing target window")
            alert.informativeText = NSLocalizedString(
                "navigation.choose_window", value: "Choose an window to scan.",
                comment: "Alert message for choosing target window")
            for window in windows {
                var title = window.value(of: "AXTitle")
                if title == "" {
                    title = NSLocalizedString(
                        "navigation.untitled", value: "Untitled",
                        comment: "Default title for untitled window")
                }
                title += String(window.hashValue)
                alert.addButton(withTitle: title)
            }
            alert.addButton(
                withTitle: NSLocalizedString(
                    "navigation.close", value: "Close", comment: "Close button"))
            alert.buttons.last?.keyEquivalent = "\u{1b}"
            let modalResult = alert.runModal()
            hide()
            let r = modalResult.rawValue - 1000
            guard windows.indices.contains(r) else {
                windowSelectionCancelled = true
                return nil
            }
            window = windows[r]
        }

        windowName = window.value(of: "AXTitle")
        log("Window information: \(appName) - \(windowName)")
        var position: CFTypeRef?
        var size: CFTypeRef?
        AXUIElementCopyAttributeValue(window, "AXPosition" as CFString, &position)
        AXUIElementCopyAttributeValue(window, "AXSize" as CFString, &size)

        if let position,
            let size,
            CFGetTypeID(position) == AXValueGetTypeID(),
            CFGetTypeID(size) == AXValueGetTypeID()
        {
            let positionValue = position as! AXValue
            let sizeValue = size as! AXValue
            var windowPosition = CGPoint()
            var windowSize = CGSize()
            if AXValueGetValue(positionValue, AXValueType.cgPoint, &windowPosition),
                AXValueGetValue(sizeValue, AXValueType.cgSize, &windowSize)
            {
                let rect = CGRect(origin: windowPosition, size: windowSize)
                log(rect)
                return rect
            }
        }
        log("Failed to get position or size")
        return nil
    }

    static func getVOCursor() -> CGRect? {
        if let output = runAppleScript(file: "VOCursor") {
            let strings = output.split(separator: ",")
            let cgFloats = strings.compactMap {
                Double($0.trimmingCharacters(in: .whitespacesAndNewlines)).map(CGFloat.init)
            }
            guard cgFloats.count >= 4 else {
                log("Invalid VOCursor coordinates: \(output)")
                return nil
            }
            let position = CGPoint(x: cgFloats[0], y: cgFloats[1])
            let size = CGSize(
                width: (cgFloats[2] - cgFloats[0]), height: (cgFloats[3] - cgFloats[1]))
            appName = "VOCursor"
            windowName = ""
            return CGRect(origin: position, size: size)
        }
        return nil
    }

    static func prepare() {
        if !Accessibility.isTrusted(ask: true) {
            log("Accessibility not enabled.")
            return
        }
        windowName = NSLocalizedString(
            "navigation.unknown_window", value: "Unknown Window",
            comment: "Default window name when unknown")
        appName = NSLocalizedString(
            "navigation.unknown_app", value: "Unknown App", comment: "Default app name when unknown"
        )
        cgPosition = CGPoint()
        cgSize = CGSize()
        cgImage = nil
        if Settings.positionReset {
            l = -1
            w = -1
            c = -1
        }
        displayResults = []
        detectedBarcodes = []
        Shortcuts.deactivateNavigationShortcuts()
        NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
        let rect = (mode == .WINDOW) ? getWindow() : getVOCursor()
        if let rect = rect {
            cgPosition = rect.origin
            cgSize = rect.size
        }
        if mode == .WINDOW && windowSelectionCancelled {
            return
        }
        if cgSize != CGSize() {
            if let image = ScreenCapture.capture(rect: CGRect(origin: cgPosition, size: cgSize)) {
                cgImage = image
            } else {
                Accessibility.speak(
                    String(
                        format: NSLocalizedString(
                            "error.screenshot_failed",
                            value: "Faild to take a screenshot of %@, %@",
                            comment: "Error message when screenshot fails"), appName, windowName))
            }
        } else {
            Accessibility.speak(
                String(
                    format: NSLocalizedString(
                        "error.access_failed", value: "Faild to access %@, %@",
                        comment: "Error message when cannot access app or window"), appName,
                    windowName))
        }
    }

    private(set) static var isScanning = false

    /// Captures on the main thread, recognizes on a background queue so VOCR stays responsive,
    /// and announces the results on the main thread before calling `completion`.
    static func startOCR(completion: (() -> Void)? = nil) {
        guard !isScanning else { return }
        if mode != .CAMERA {
            prepare()
        }
        guard let image = cgImage else { return }
        isScanning = true
        // Tell the user why the scan is slow if Vision has to compile its models first.
        // With Write Log on, also record Vision's own messages so a failed scan can be diagnosed.
        let writeLog = Settings.writeLog
        VisionModelMonitor.start(captureLog: writeLog) {
            guard isScanning else { return }
            Accessibility.speak(
                NSLocalizedString(
                    "navigation.compiling_models",
                    value:
                        "Compiling text recognition models. Please wait. It might take up to a minute.",
                    comment: "Message when a scan has to compile text recognition models first"))
        }
        let detectObjects = Settings.detectObject
        DispatchQueue.global(qos: .userInitiated).async {
            let start = Date()
            let result = Result {
                try VisionOCR.observations(in: image, detectObjects: detectObjects)
            }
            let duration = Date().timeIntervalSince(start)
            let details =
                writeLog
                ? "\(VisionDiagnostics.environment)\n\(VisionDiagnostics.modelCache())" : ""
            DispatchQueue.main.async {
                let messages = VisionModelMonitor.stop()
                if writeLog {
                    log(
                        String(format: "Scan took %.2f s\n", duration) + details
                            + "\nVision log (\(messages.count) messages):\n"
                            + messages.joined(separator: "\n"))
                }
                isScanning = false
                finishOCR(result)
                completion?()
            }
        }
    }

    private static func finishOCR(
        _ scan: Result<(observations: [Observation], barcodes: [DetectedBarcode]), Error>
    ) {
        let result: (observations: [Observation], barcodes: [DetectedBarcode])
        switch scan {
        case .success(let value):
            result = value
        case .failure(let error):
            detectedBarcodes = []
            log("OCR failed: \(VisionDiagnostics.describe(error))")
            Accessibility.speak(
                String(
                    format: NSLocalizedString(
                        "navigation.recognition_failed", value: "Text recognition failed. %@",
                        comment: "Message when text recognition fails; the argument is the error"),
                    error.localizedDescription))
            return
        }
        detectedBarcodes = result.barcodes
        let barcodeDetected = !detectedBarcodes.isEmpty
        if result.observations.count == 0 {
            if barcodeDetected {
                var announcement = NSLocalizedString(
                    "navigation.finished_scanning_barcode_detected", value: "Finished scanning",
                    comment: "Message when scanning is complete and a barcode was found")
                announcement += ".\n" + barcodeAnnouncement()
                Accessibility.speak(announcement)
                Shortcuts.activateNavigationShortcuts()
            } else {
                Accessibility.speak(
                    NSLocalizedString(
                        "navigation.nothing_found", value: "Nothing found",
                        comment: "Message when no text is found during OCR"))
            }
            return
        }
        process(result.observations)
        var announcement = String(
            format: NSLocalizedString(
                "navigation.finished_scanning", value: "Finished scanning %@, %@",
                comment: "Message when scanning is complete"), appName, windowName)
        if barcodeDetected {
            announcement += ".\n" + barcodeAnnouncement()
        }
        Accessibility.speak(announcement)
        Shortcuts.activateNavigationShortcuts()
    }

    private static func barcodeAnnouncement() -> String {
        let shortcutKeyName =
            Shortcuts.spokenKeyName(for: "shortcut.view_qrcodes")
            ?? "Control Shift Command Q"
        let barcodeCount = detectedBarcodes.count
        let barcodeCountPhrase =
            barcodeCount == 1
            ? NSLocalizedString(
                "navigation.barcode_count_singular", value: "1 code",
                comment: "Singular barcode count phrase")
            : String(
                format: NSLocalizedString(
                    "navigation.barcode_count_plural", value: "%d codes",
                    comment: "Plural barcode count phrase"), barcodeCount)
        return String(
            format: NSLocalizedString(
                "navigation.barcodes_detected", value: "%1$@ detected. Press %2$@ to view.",
                comment: "Message when barcodes are detected"), barcodeCountPhrase, shortcutKeyName)
    }

    static func explore() {
        prepare()
        guard let image = cgImage else { return }
        let prompt = Settings.exploreUserPrompt.replacingOccurrences(
            of: "{image.width}", with: String(image.width)
        ).replacingOccurrences(of: "{image.height}", with: String(image.height))
        OpenAIAPI.describe(
            image: image, system: Settings.exploreSystemPrompt, prompt: prompt,
            followUp: false, completion: exploreHandler)
    }

    static func exploreHandler(description: String) {
        if let elements = self.decode(message: description) {
            let result = elements.map { Observation($0) }
            self.process(result)
            Shortcuts.activateNavigationShortcuts()
            NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Accessibility.speak(
                    String(
                        format: NSLocalizedString(
                            "navigation.finished_scanning", value: "Finished scanning %@, %@",
                            comment: "Message when scanning is complete"), self.appName,
                        self.windowName))
            }
        } else {
            Accessibility.speakWithSynthesizer(
                NSLocalizedString(
                    "error.json_parse_failed", value: "Cannot parse the JSON string. Try again.",
                    comment: "Error message when JSON parsing fails"))
        }
    }

    static func decode(message: String) -> [GPTObservation]? {
        guard let jsonData = message.data(using: .utf8) else {
            return nil
        }
        do {
            let elements = try JSONDecoder().decode(GPTObservations.self, from: jsonData).elements
            for element in elements {
                log(
                    "Label: \(element.label), UID: \(element.uid), Bounding Box: \(element.boundingBox)"
                )
            }
            return elements
        } catch {
            log("Error decoding JSON: \(error), ```json\(message)```")
        }
        return nil
    }

    static func process(_ results: [Observation]) {
        guard !results.isEmpty else { return }
        let sorted = results.sorted(by: sort)
        var line: [Observation] = []
        var y = sorted[0].boundingBox.midY
        for r in sorted {
            if abs(r.boundingBox.midY - y) > lineBreakTolerance {
                displayResults.append(line)
                line = []
                y = r.boundingBox.midY
            }
            line.append(r)
        }
        displayResults.append(line)
    }

    static func convert2coordinates(_ rect: CGRect) -> CGPoint {
        if let image = cgImage {
            log(
                "Box: \(VNImageRectForNormalizedRect(rect, image.width, image.height).debugDescription)"
            )
        }
        let box = CGRect(x: rect.minX, y: 1 - rect.maxY, width: rect.width, height: rect.height)
        var center = CGPoint(x: box.midX, y: box.midY)
        log("\(center.debugDescription)")
        if Settings.positionalAudio {
            let frequency = 100 + 1000 * (1 - Float(center.y))
            let pan = Float(Double(center.x).normalize(from: 0...1, into: -1...1))
            Player.shared.play(frequency, pan)
        }
        center = VNImagePointForNormalizedPoint(center, Int(cgSize.width), Int(cgSize.height))
        log("\(center.debugDescription)")
        center.x += cgPosition.x
        center.y += cgPosition.y
        return center
    }

    static func sort(_ a: Observation, _ b: Observation) -> Bool {
        if a.boundingBox.midY - b.boundingBox.midY > lineBreakTolerance {
            return true
        } else if b.boundingBox.midY - a.boundingBox.midY > lineBreakTolerance {
            return false
        }
        return a.boundingBox.midX < b.boundingBox.midX
    }

    /// True when `l` and `w` point at an observation. Unlike `correctLimit()`, it does not move the selection.
    private static func hasSelection() -> Bool {
        displayResults.indices.contains(l) && displayResults[l].indices.contains(w)
    }

    static func location() {
        guard hasSelection() else { return }
        var center = convert2coordinates(displayResults[l][w].boundingBox)
        center.x -= cgPosition.x
        center.y -= cgPosition.y
        Accessibility.speak(String(format: "%d, %d", Int(center.x), Int(center.y)))
    }

    static func correctLimit() {
        guard !displayResults.isEmpty else { return }
        if l < 0 {
            l = 0
        } else if l >= displayResults.count {
            l = displayResults.count - 1
        }
        if displayResults[l].isEmpty {
            w = 0
            return
        }
        if w < 0 {
            w = 0
        } else if w >= displayResults[l].count {
            w = displayResults[l].count - 1
        }
    }

    static func identifyObject() {
        guard hasSelection() else { return }
        if displayResults[l][w].value == "OBJECT" {
            if let image = cgImage {
                var rect = displayResults[l][w].boundingBox
                rect = CGRect(
                    x: rect.minX, y: 1 - rect.maxY, width: rect.width, height: rect.height)
                rect = VNImageRectForNormalizedRect(rect, image.width, image.height)

                log("\(rect.debugDescription)")
                if let croppedImage = image.cropping(to: rect) {
                    ask(image: croppedImage)
                }
            }
        }
    }

    static func right() {
        if displayResults.count == 0 {
            return
        }
        w += 1
        c = -1
        correctLimit()
        log("\(l), \(w)")
        if Settings.moveMouse {
            CGWarpMouseCursorPosition(convert2coordinates(displayResults[l][w].boundingBox))
        }
        Accessibility.speak(displayResults[l][w].value)
    }

    static func left() {
        if displayResults.count == 0 {
            return
        }
        w -= 1
        c = -1
        correctLimit()
        log("\(l), \(w)")
        if Settings.moveMouse {
            CGWarpMouseCursorPosition(convert2coordinates(displayResults[l][w].boundingBox))
        }
        Accessibility.speak(displayResults[l][w].value)
    }

    static func down() {
        if displayResults.count == 0 {
            return
        }
        l += 1
        w = 0
        c = -1
        correctLimit()
        log("\(l), \(w)")
        if Settings.moveMouse {
            CGWarpMouseCursorPosition(convert2coordinates(displayResults[l][w].boundingBox))
        }
        var line = ""
        for r in displayResults[l] {
            line += " \(r.value)"
        }
        Accessibility.speak(line)
    }

    static func up() {
        if displayResults.count == 0 {
            return
        }
        l -= 1
        w = 0
        c = -1
        correctLimit()
        log("\(l), \(w)")
        if Settings.moveMouse {
            CGWarpMouseCursorPosition(convert2coordinates(displayResults[l][w].boundingBox))
        }
        var line = ""
        for r in displayResults[l] {
            line += " \(r.value)"
        }
        Accessibility.speak(line)
    }

    static func top() {
        if displayResults.count == 0 {
            return
        }
        l = 1
        w = 0
        up()
    }

    static func bottom() {
        if displayResults.count == 0 {
            return
        }
        l = displayResults.count - 2
        w = 0
        down()
    }

    static func beginning() {
        if displayResults.count == 0 {
            return
        }
        w = 1
        left()
    }

    static func end() {
        if displayResults.count == 0 {
            return
        }
        correctLimit()
        w = displayResults[l].count - 2
        right()
    }

    static func nextCharacter() {
        if displayResults.count == 0 {
            return
        }
        correctLimit()
        guard displayResults[l].indices.contains(w) else { return }
        if let obs = displayResults[l][w].vnObservation,
            let candidate = obs.topCandidates(1).first
        {
            var str = candidate.string
            guard !str.isEmpty else { return }
            c = min(max(c + 1, 0), str.count - 1)
            do {
                let start = str.index(str.startIndex, offsetBy: c)
                let end = str.index(str.startIndex, offsetBy: c + 1)
                let range = start..<end
                let character = str[range]
                str = String(character)
                guard let rectObservation = try candidate.boundingBox(for: range) else { return }
                let box = rectObservation.boundingBox
                CGWarpMouseCursorPosition(convert2coordinates(box))
                Accessibility.speak(str)
            } catch {
            }
        }
    }

    static func previousCharacter() {
        if displayResults.count == 0 {
            return
        }
        correctLimit()
        guard displayResults[l].indices.contains(w) else { return }
        if let obs = displayResults[l][w].vnObservation,
            let candidate = obs.topCandidates(1).first
        {
            var str = candidate.string
            guard !str.isEmpty else { return }
            c = min(max(c - 1, 0), str.count - 1)

            do {
                let start = str.index(str.startIndex, offsetBy: c)
                let end = str.index(str.startIndex, offsetBy: c + 1)
                let range = start..<end
                let character = str[range]
                str = String(character)
                guard let rectObservation = try candidate.boundingBox(for: range) else { return }
                let box = rectObservation.boundingBox

                CGWarpMouseCursorPosition(convert2coordinates(box))
                Accessibility.speak(str)
            } catch {
            }
        }
    }

    static func text() -> String {
        var text = ""
        for line in displayResults {
            for word in line {
                text += word.value + " "
            }
            text = text.dropLast() + "\n"
        }
        return text
    }

}

class BarcodeDialogController: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    static let shared = BarcodeDialogController()

    private var barcodes: [DetectedBarcode] = []

    private override init() {
        super.init()
    }

    func show() {
        self.barcodes = Navigation.detectedBarcodes
        if barcodes.isEmpty {
            Accessibility.speak(
                NSLocalizedString(
                    "navigation.no_barcodes", value: "No barcodes found in the last scan.",
                    comment: "Message when no barcodes are found"))
            return
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString(
            "barcodes.dialog.title", value: "Detected Barcodes",
            comment: "Title for barcodes dialog")
        alert.informativeText = NSLocalizedString(
            "barcodes.dialog.message", value: "Select a barcode to interact with it.",
            comment: "Message for barcodes dialog")

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))
        scrollView.hasVerticalScroller = true

        let tableView = NSTableView(frame: scrollView.bounds)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("BarcodeColumn"))
        column.title = NSLocalizedString(
            "barcodes.dialog.column", value: "Barcode",
            comment: "Column title for detected barcodes")
        column.width = 380
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        tableView.target = self
        tableView.doubleAction = #selector(handleDoubleClick(_:))

        scrollView.documentView = tableView
        alert.accessoryView = scrollView

        alert.addButton(
            withTitle: NSLocalizedString(
                "button.search_in_browser", value: "Search in Browser",
                comment: "Button to search for a barcode in the default browser")
        )
        alert.addButton(
            withTitle: NSLocalizedString(
                "button.open_in_browser", value: "Open in Browser",
                comment: "Button to open a barcode in the default browser")
        )
        alert.addButton(
            withTitle: NSLocalizedString(
                "button.copy_to_clipboard", value: "Copy to Clipboard",
                comment: "Button to copy text to the clipboard")
        )
        alert.addButton(
            withTitle: NSLocalizedString("button.cancel", value: "Cancel", comment: "Cancel button")
        )

        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        let response = showDialog(alert, focusing: tableView)
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 && selectedRow < barcodes.count else {
            return
        }

        let barcode = barcodes[selectedRow]
        if response == .alertFirstButtonReturn {
            searchInBrowser(barcode)
        } else if response == .alertSecondButtonReturn {
            openInBrowser(barcode)
        } else if response == .alertThirdButtonReturn {
            copyToClipboard(barcode.displayValue)
            speakCopied(barcode)
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return barcodes.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int)
        -> Any?
    {
        return barcodes[row].displayValue
    }

    @objc private func handleDoubleClick(_ sender: AnyObject) {
        if let tableView = sender as? NSTableView {
            let row = tableView.clickedRow
            if row >= 0 && row < barcodes.count {
                NSApplication.shared.stopModal(withCode: .alertFirstButtonReturn)
            }
        }
    }

    private func searchInBrowser(_ barcode: DetectedBarcode) {
        openInDefaultBrowser(searchURL(for: barcode))
    }

    /// Opens web links. Payloads with another URI scheme (mailto:, otpauth:, WIFI: ...) may hold
    /// private data, so they are neither opened nor sent to a search engine. Plain text is searched.
    private func openInBrowser(_ barcode: DetectedBarcode) {
        if let url = webURL(from: barcode.payload) {
            openInDefaultBrowser(url)
        } else if hasURIScheme(barcode.payload) {
            Accessibility.speak(
                NSLocalizedString(
                    "barcodes.not_web_link", value: "This barcode is not a web link.",
                    comment:
                        "Message when Open in Browser is used on a barcode that is not a web link"
                ))
        } else {
            openInDefaultBrowser(searchURL(for: barcode))
        }
    }

    private func hasURIScheme(_ payload: String) -> Bool {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let schemeSeparator = trimmed.firstIndex(of: ":") else { return false }
        return trimmed[..<schemeSeparator].range(
            of: #"^[A-Za-z][A-Za-z0-9+.-]*$"#, options: .regularExpression) != nil
    }

    private func webURL(from payload: String) -> URL? {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let url = URL(string: trimmed),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            let host = url.host,
            !host.isEmpty
        else {
            return nil
        }

        return url
    }

    private func searchURL(for barcode: DetectedBarcode) -> URL {
        var components = URLComponents(string: "https://www.google.com/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: "\(barcode.symbologyName) \(barcode.payload)")
        ]
        return components.url!
    }

    private func openInDefaultBrowser(_ url: URL) {
        guard let browserURL = defaultBrowserApplicationURL() else {
            NSWorkspace.shared.open(url)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([url], withApplicationAt: browserURL, configuration: configuration)
    }

    private func defaultBrowserApplicationURL() -> URL? {
        guard let webURL = URL(string: "https://example.com") else {
            return nil
        }

        return LSCopyDefaultApplicationURLForURL(webURL as CFURL, .viewer, nil)?.takeRetainedValue()
            as URL?
    }

    private func speakCopied(_ barcode: DetectedBarcode) {
        Accessibility.speak(
            String(
                format: NSLocalizedString(
                    "barcodes.copied_with_type", value: "%@ copied to clipboard.",
                    comment: "Message when a barcode payload is copied"), barcode.symbologyName))
    }
}
