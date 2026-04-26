import AppKit
import Carbon
import Foundation

final class ComputerUseRunner: ObservableObject {
    @Published private(set) var isRunning = false

    private var cancelled = false
    private var currentTask: URLSessionDataTask?
    private var currentWindowRect = CGRect.zero
    private var screenScale: CGFloat = 1.0
    private var lastPrompt = ""
    private let maxTurns = 30

    // Cumulative token tracking
    private var totalInputTokens = 0
    private var totalOutputTokens = 0
    private var totalCachedTokens = 0

    // VOCR-style permission flags to suppress false-negatives from cached API results
    private var screenRecordingRequested = false
    private var accessibilityRequested = false

    func startAfterWindowAppears(prompt: String, logger: ActionLogger) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.lastPrompt = prompt
            self.start(prompt: prompt, logger: logger)
        }
    }

    func showPrompt(logger: ActionLogger) {
        if isRunning {
            logger.log("Computer Use", "Already running")
            return
        }

        guard let prompt = promptDialog(defaultValue: lastPrompt) else {
            logger.log("Computer Use", "Prompt cancelled")
            return
        }

        lastPrompt = prompt
        start(prompt: prompt, logger: logger)
    }

    func requestPermissions(logger: ActionLogger) {
        let srStatus = isScreenRecordingGranted()
        let axStatus = isAccessibilityGranted()

        logger.log(
            "Permission", "Status - Screen Recording: \(srStatus), Accessibility: \(axStatus)")

        if !srStatus {
            requestScreenRecording(logger: logger)

            // If we also need Accessibility, wait a bit before opening Settings
            // to allow the Screen Recording system dialog to appear first.
            if !axStatus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.requestAccessibility(logger: logger)
                }
            }
        } else if !axStatus {
            requestAccessibility(logger: logger)
        } else {
            logger.log("Permission", "All permissions already granted")
        }
    }

    func requestAccessibility(logger: ActionLogger) {
        requestAccessibilityPermission(logger: logger)
    }

    func requestScreenRecording(logger: ActionLogger) {
        // Attempt a dummy capture to force system registration if it's missing from the list
        _ = CGWindowListCreateImage(.zero, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)
        requestScreenRecordingPermission(logger: logger)
    }

    func abort() {
        cancelled = true
        currentTask?.cancel()
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }

    func start(prompt: String, logger: ActionLogger) {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !apiKey.isEmpty
        else {
            logger.log("Computer Use", "Missing OPENAI_API_KEY environment variable")
            showError("Missing OPENAI_API_KEY environment variable.")
            return
        }

        guard ensureAccessibilityPermission(logger: logger) else {
            return
        }

        guard ensureScreenRecordingPermission(logger: logger) else {
            return
        }

        guard let rect = captureTargetWindowRect() else {
            logger.log("Computer Use", "Could not find the test app window")
            showError("Could not find the test app window.")
            return
        }

        currentWindowRect = rect
        cancelled = false
        isRunning = true

        // Reset token counters for new session
        totalInputTokens = 0
        totalOutputTokens = 0
        totalCachedTokens = 0

        logger.log("Computer Use", "Started prompt: \(prompt)")

        let model = ProcessInfo.processInfo.environment["OPENAI_MODEL"] ?? "gpt-5.5"
        let baseURL =
            ProcessInfo.processInfo.environment["OPENAI_BASE_URL"] ?? "https://api.openai.com/v1"
        let config = APIConfig(apiKey: apiKey, model: model, baseURL: baseURL)

        let input = """
            You are testing this macOS app window. Use the computer tool to operate only controls visible in this app.
            Log-producing controls include buttons, drag and drop, text entry, popup menu, radio buttons, checkbox, slider, table cells, menu commands, and shortcut capture.
            User task: \(prompt)
            """

        let body: [String: Any] = [
            "model": config.model,
            "tools": [["type": "computer"]],
            "input": input,
        ]

        send(body: body, config: config, logger: logger) { [weak self] result in
            self?.handle(result: result, config: config, logger: logger, turn: 1)
        }
    }

    private func finish(logger: ActionLogger, message: String?) {
        DispatchQueue.main.async {
            self.isRunning = false
        }
        currentTask = nil

        if cancelled {
            logger.log("Computer Use", "Cancelled")
            cancelled = false
            return
        }

        if let message, !message.isEmpty {
            logger.log("Computer Use Final", message)
        }

        let total = totalInputTokens + totalOutputTokens
        logger.log(
            "Computer Use API",
            "Final Usage - Total: \(total) [input: \(totalInputTokens) (cached: \(totalCachedTokens)), output: \(totalOutputTokens)]"
        )

        logger.log("Computer Use", "Finished")

        copyLogToClipboard(logger: logger, status: message ?? "Completed")
    }

    private func fail(_ error: Error, logger: ActionLogger) {
        DispatchQueue.main.async {
            self.isRunning = false
        }
        currentTask = nil

        if cancelled || (error as NSError).code == NSURLErrorCancelled {
            logger.log("Computer Use", "Cancelled")
            cancelled = false
            return
        }

        logger.log("Computer Use Error", "\(error)")

        let total = totalInputTokens + totalOutputTokens
        logger.log(
            "Computer Use API",
            "Final Usage - Total: \(total) [input: \(totalInputTokens) (cached: \(totalCachedTokens)), output: \(totalOutputTokens)]"
        )

        copyLogToClipboard(logger: logger, status: "Error: \(error)")

        showError("\(error)")
    }

    private func copyLogToClipboard(logger: ActionLogger, status: String) {
        // We use a slight delay to ensure the main-thread async logs from 'finish/fail'
        // have been appended to logger.fullLogText before we grab it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let report = """
                --- Computer Use Session Report ---
                Prompt: \(self.lastPrompt)
                Status: \(status)

                Action Log:
                \(logger.fullLogText)
                ----------------------------------
                """

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(report, forType: .string)

            logger.log("App", "Session report copied to clipboard")
        }
    }

}

extension ComputerUseRunner {
    fileprivate struct APIConfig {
        let apiKey: String
        let model: String
        let baseURL: String
    }

    fileprivate struct ResponsesResponse: Decodable {
        let id: String
        let output: [OutputItem]
        let usage: Usage?
    }

    fileprivate struct Usage: Decodable {
        let input_tokens: Int
        let output_tokens: Int
        let total_tokens: Int
        let input_tokens_details: TokenDetails?
    }

    fileprivate struct TokenDetails: Decodable {
        let cached_tokens: Int
    }

    fileprivate struct OutputItem: Decodable {
        let type: String
        let callId: String?
        let actions: [ComputerAction]?
        let content: [MessageContent]?

        enum CodingKeys: String, CodingKey {
            case type
            case callId = "call_id"
            case actions
            case content
        }
    }

    fileprivate struct MessageContent: Decodable {
        let type: String
        let text: String?
    }

    fileprivate struct ComputerAction: Decodable {
        let type: String
        let x: Double?
        let y: Double?
        let scrollX: Double?
        let scrollY: Double?
        let button: String?
        let text: String?
        let keys: [String]?
        let path: [DragPoint]?
    }

    fileprivate struct DragPoint: Decodable {
        let x: Double
        let y: Double

        init(from decoder: Decoder) throws {
            if var container = try? decoder.unkeyedContainer() {
                x = try container.decode(Double.self)
                y = try container.decode(Double.self)
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            x = try container.decode(Double.self, forKey: .x)
            y = try container.decode(Double.self, forKey: .y)
        }

        enum CodingKeys: CodingKey {
            case x
            case y
        }
    }

    fileprivate enum RunnerError: Error {
        case invalidURL
        case invalidResponse(String)
        case screenshotFailed
        case unsupportedAction(String)
    }
}

extension ComputerUseRunner {
    fileprivate func send(
        body: [String: Any],
        config: APIConfig,
        logger: ActionLogger,
        completion: @escaping (Result<ResponsesResponse, Error>) -> Void
    ) {
        guard let base = URL(string: config.baseURL) else {
            completion(.failure(RunnerError.invalidURL))
            return
        }

        let url = base.appendingPathComponent("responses")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 600
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        logger.log("Computer Use API", "Sending request to \(config.model)")

        currentTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(RunnerError.invalidResponse("No HTTP response")))
                return
            }

            guard let data else {
                completion(.failure(RunnerError.invalidResponse("No response data")))
                return
            }

            let raw = String(data: data, encoding: .utf8) ?? ""
            debugPrint(raw)

            guard httpResponse.statusCode == 200 else {
                completion(
                    .failure(RunnerError.invalidResponse("HTTP \(httpResponse.statusCode): \(raw)"))
                )
                return
            }

            do {
                completion(.success(try JSONDecoder().decode(ResponsesResponse.self, from: data)))
            } catch {
                completion(.failure(error))
            }
        }
        currentTask?.resume()
    }

    fileprivate func handle(
        result: Result<ResponsesResponse, Error>,
        config: APIConfig,
        logger: ActionLogger,
        turn: Int
    ) {
        if cancelled {
            finish(logger: logger, message: nil)
            return
        }

        switch result {
        case .failure(let error):
            fail(error, logger: logger)
        case .success(let response):
            handle(response: response, config: config, logger: logger, turn: turn)
        }
    }

    fileprivate func handle(
        response: ResponsesResponse, config: APIConfig, logger: ActionLogger, turn: Int
    ) {
        logger.log("Computer Use", "--- Turn \(turn) ---")

        if let usage = response.usage {
            totalInputTokens += usage.input_tokens
            totalOutputTokens += usage.output_tokens
            totalCachedTokens += usage.input_tokens_details?.cached_tokens ?? 0

            let details = usage.input_tokens_details.map { " (cached: \($0.cached_tokens))" } ?? ""
            logger.log(
                "Computer Use API",
                "Tokens: \(usage.total_tokens) [input: \(usage.input_tokens)\(details), output: \(usage.output_tokens)]"
            )
        }

        let messages = responseMessages(response)
        for message in messages {
            logger.log("Computer Use Message", message)
        }

        guard turn <= maxTurns else {
            finish(logger: logger, message: "Stopped after \(maxTurns) turns.")
            return
        }

        guard let computerCall = response.output.first(where: { $0.type == "computer_call" }),
            let callId = computerCall.callId
        else {
            finish(logger: logger, message: messages.last)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.execute(actions: computerCall.actions ?? [], logger: logger)
                guard !self.cancelled else {
                    self.finish(logger: logger, message: nil)
                    return
                }
                try self.sendScreenshot(
                    previousResponse: response,
                    callId: callId,
                    config: config,
                    logger: logger,
                    turn: turn + 1
                )
            } catch {
                self.fail(error, logger: logger)
            }
        }
    }

    fileprivate func sendScreenshot(
        previousResponse: ResponsesResponse,
        callId: String,
        config: APIConfig,
        logger: ActionLogger,
        turn: Int
    ) throws {
        guard let originalImage = captureScreenshot() else {
            throw RunnerError.screenshotFailed
        }

        // Downscale to point dimensions to save tokens and simplify math
        let targetWidth = Int(currentWindowRect.width)
        let targetHeight = Int(currentWindowRect.height)

        guard
            let resizedImage = resizeCGImage(
                originalImage, toWidth: targetWidth, toHeight: targetHeight),
            let base64 = pngBase64(image: resizedImage)
        else {
            throw RunnerError.screenshotFailed
        }

        debugPrint("Original Image: \(originalImage.width)x\(originalImage.height)")
        debugPrint("Resized Image: \(resizedImage.width)x\(resizedImage.height)")
        debugPrint("Target Points: \(targetWidth)x\(targetHeight)")

        // Since we resized to points, the coordinate mapping is now 1:1
        self.screenScale = 1.0
        debugPrint("Image resized to \(targetWidth)x\(targetHeight). screenScale set to 1.0")

        let body: [String: Any] = [

            "model": config.model,
            "tools": [["type": "computer"]],
            "previous_response_id": previousResponse.id,
            "input": [
                [
                    "type": "computer_call_output",
                    "call_id": callId,
                    "output": [
                        "type": "computer_screenshot",
                        "image_url": "data:image/png;base64,\(base64)",
                        "detail": "original",
                    ],
                ]
            ],
        ]

        send(body: body, config: config, logger: logger) { [weak self] result in
            self?.handle(result: result, config: config, logger: logger, turn: turn)
        }
    }

    fileprivate func responseMessages(_ response: ResponsesResponse) -> [String] {
        response.output.flatMap { item in
            (item.content ?? []).compactMap { content in
                guard content.type == "output_text" || content.type == "text" else {
                    return nil
                }
                return content.text
            }
        }
    }
}

extension ComputerUseRunner {
    fileprivate func ensureAccessibilityPermission(logger: ActionLogger) -> Bool {
        if isAccessibilityGranted() {
            return true
        }

        logger.log("Permission", "Accessibility permission missing")
        requestAccessibilityPermission(logger: logger)
        return false
    }

    fileprivate func isAccessibilityGranted() -> Bool {
        if accessibilityRequested {
            return true
        }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary?)
    }

    fileprivate func requestAccessibilityPermission(logger: ActionLogger) {
        logger.log("Permission", "Requesting Accessibility permission")
        accessibilityRequested = true

        // This triggers the system prompt if not already granted
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary?)

        openAccessibilitySettings(logger: logger)
    }

    fileprivate func openAccessibilitySettings(logger: ActionLogger) {
        logger.log("Permission", "Opening Accessibility settings")
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) {
            NSWorkspace.shared.open(url)
        }
    }

    fileprivate func ensureScreenRecordingPermission(logger: ActionLogger) -> Bool {
        if isScreenRecordingGranted() {
            return true
        }

        logger.log("Permission", "Screen Recording permission missing")

        // Attempt a dummy capture to force system registration if it's missing from the list
        _ = CGWindowListCreateImage(.zero, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)

        requestScreenRecordingPermission(logger: logger)
        return false
    }

    fileprivate func isScreenRecordingGranted() -> Bool {
        // Log bundle ID for TCC debugging
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        debugPrint("Checking Screen Recording for: \(bundleID)")

        if CGPreflightScreenCaptureAccess() {
            return true
        }

        // If preflight fails, try a real capture of a 1x1 pixel.
        // Sometimes preflight is stale but the API works.
        let testRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        if CGWindowListCreateImage(testRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)
            != nil
        {
            debugPrint("Screen Recording: Preflight failed but test capture succeeded!")
            return true
        }

        // CGPreflightScreenCaptureAccess() caches its result for the lifetime of the process.
        // If we've already requested it in this session, assume it's granted or pending
        // to suppress the error until the next launch.
        return screenRecordingRequested
    }

    fileprivate func requestScreenRecordingPermission(logger: ActionLogger) {
        logger.log("Permission", "Requesting Screen Recording permission")
        screenRecordingRequested = true

        let requestBlock = {
            NSApplication.shared.activate(ignoringOtherApps: true)
            // CGRequestScreenCaptureAccess() registers the app in System Settings and
            // should present the system permission dialog.
            // VOCR does not call openScreenRecordingSettings here to avoid clobbering
            // other prompts or the system's own "Open System Settings" button.
            let granted = CGRequestScreenCaptureAccess()
            logger.log(
                "Permission",
                granted ? "Screen Recording granted" : "Screen Recording denied or pending")
        }

        if Thread.isMainThread {
            requestBlock()
        } else {
            DispatchQueue.main.sync(execute: requestBlock)
        }
    }

    fileprivate func openScreenRecordingSettings(logger: ActionLogger) {
        logger.log("Permission", "Opening Screen Recording settings")
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ) {
            NSWorkspace.shared.open(url)
        }
    }

    fileprivate func captureTargetWindowRect() -> CGRect? {
        let pid = NSRunningApplication.current.processIdentifier
        guard
            let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
                as? [[String: Any]]
        else {
            return nil
        }

        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                ownerPID == pid,
                let layer = window[kCGWindowLayer as String] as? Int,
                layer == 0,
                let bounds = window[kCGWindowBounds as String] as? [String: Any],
                let x = bounds["X"] as? CGFloat,
                let y = bounds["Y"] as? CGFloat,
                let width = bounds["Width"] as? CGFloat,
                let height = bounds["Height"] as? CGFloat,
                width > 100,
                height > 100
            else {
                continue
            }
            return CGRect(x: x, y: y, width: width, height: height)
        }
        return nil
    }

    fileprivate func captureScreenshot() -> CGImage? {
        if let rect = captureTargetWindowRect() {
            currentWindowRect = rect
        }

        guard
            let image = CGWindowListCreateImage(
                currentWindowRect,
                [.optionOnScreenOnly],
                kCGNullWindowID,
                [.bestResolution]
            )
        else {
            return nil
        }

        // Calculate scale factor between points (currentWindowRect) and pixels (image)
        screenScale = CGFloat(image.width) / currentWindowRect.width
        return image
    }

    fileprivate func pngBase64(image: CGImage) -> String? {
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        guard let data = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        return data.base64EncodedString()
    }

    fileprivate func resizeCGImage(_ cgImage: CGImage, toWidth width: Int, toHeight height: Int)
        -> CGImage?
    {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: cgImage.bitmapInfo.rawValue)

        context?.interpolationQuality = .high
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context?.makeImage()
    }
}

extension ComputerUseRunner {
    fileprivate func execute(actions: [ComputerAction], logger: ActionLogger) throws {
        for action in actions {
            if cancelled { return }

            logger.log("Computer Use Action", describe(action))
            try execute(action: action)
            Thread.sleep(forTimeInterval: 0.2)
        }
    }

    fileprivate func execute(action: ComputerAction) throws {
        switch action.type {
        case "click":
            guard let point = point(for: action) else { return }
            withModifiers(action.keys) {
                click(point: point, button: action.button, clickCount: 1)
            }
        case "double_click":
            guard let point = point(for: action) else { return }
            withModifiers(action.keys) {
                click(point: point, button: action.button, clickCount: 2)
            }
        case "move":
            guard let point = point(for: action) else { return }
            moveMouse(to: point)
        case "scroll":
            guard let point = point(for: action) else { return }
            withModifiers(action.keys) {
                moveMouse(to: point)
                scroll(deltaX: action.scrollX ?? 0, deltaY: action.scrollY ?? 0)
            }
        case "drag":
            let points = (action.path ?? []).map { globalPoint(x: $0.x, y: $0.y) }
            guard points.count >= 2 else { return }
            withModifiers(action.keys) {
                drag(points: points)
            }
        case "type":
            typeText(action.text ?? "")
        case "keypress":
            for key in action.keys ?? [] {
                pressKey(named: key)
            }
        case "wait":
            Thread.sleep(forTimeInterval: 1.0)
        case "screenshot":
            // Logged automatically via the describe() call in execute(actions:)
            break
        default:
            throw RunnerError.unsupportedAction(action.type)
        }
    }

    fileprivate func describe(_ action: ComputerAction) -> String {
        let x = action.x != nil ? " at \(Int(action.x!))" : ""
        let y = action.y != nil ? ", \(Int(action.y!))" : ""
        let coords = "\(x)\(y)"

        switch action.type {
        case "click":
            return "Click\(coords)."
        case "double_click":
            return "Double click\(coords)."
        case "move":
            return "Move to\(coords)."
        case "scroll":
            let sx = action.scrollX != nil ? " x:\(Int(action.scrollX!))" : ""
            let sy = action.scrollY != nil ? " y:\(Int(action.scrollY!))" : ""
            return "Scroll\(coords)\(sx)\(sy)."
        case "drag":
            let count = action.path?.count ?? 0
            return "Drag through \(count) points."
        case "type":
            return "Type \"\(action.text ?? "")\"."
        case "keypress":
            return "Press \((action.keys ?? []).joined(separator: "+"))."
        case "wait":
            return "Wait."
        case "screenshot":
            return "Take screenshot."
        default:
            return "Perform \(action.type)\(coords)."
        }
    }

    fileprivate func point(for action: ComputerAction) -> CGPoint? {
        guard let x = action.x, let y = action.y else { return nil }
        return globalPoint(x: x, y: y)
    }

    fileprivate func globalPoint(x: Double, y: Double) -> CGPoint {
        // Model provides x, y in pixels (relative to the image we sent)
        // For this downscaled test, we force a 1:1 mapping (1 pixel = 1 point)
        let pointX = CGFloat(x)
        let pointY = CGFloat(y)

        debugPrint(
            "Scaling (FORCED 1:1): x=\(x), y=\(y) -> pointX=\(pointX), pointY=\(pointY)")
        debugPrint("Window: origin=(\(currentWindowRect.minX), \(currentWindowRect.minY))")

        return CGPoint(x: currentWindowRect.minX + pointX, y: currentWindowRect.minY + pointY)
    }

    fileprivate func moveMouse(to point: CGPoint) {
        CGEvent(
            mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point,
            mouseButton: .left)?
            .post(tap: .cghidEventTap)
    }

    fileprivate func click(point: CGPoint, button: String?, clickCount: Int) {
        let mouseButton = cgMouseButton(button)
        let downType = mouseButton == .right ? CGEventType.rightMouseDown : .leftMouseDown
        let upType = mouseButton == .right ? CGEventType.rightMouseUp : .leftMouseUp

        for _ in 0..<clickCount {
            let down = CGEvent(
                mouseEventSource: nil, mouseType: downType, mouseCursorPosition: point,
                mouseButton: mouseButton)
            down?.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
            down?.post(tap: .cghidEventTap)

            let up = CGEvent(
                mouseEventSource: nil, mouseType: upType, mouseCursorPosition: point,
                mouseButton: mouseButton)
            up?.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
            up?.post(tap: .cghidEventTap)
        }
    }

    fileprivate func drag(points: [CGPoint]) {
        guard let first = points.first else { return }
        moveMouse(to: first)
        CGEvent(
            mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: first,
            mouseButton: .left)?
            .post(tap: .cghidEventTap)

        for point in points.dropFirst() {
            CGEvent(
                mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: point,
                mouseButton: .left)?
                .post(tap: .cghidEventTap)
            Thread.sleep(forTimeInterval: 0.04)
        }

        if let last = points.last {
            CGEvent(
                mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: last,
                mouseButton: .left)?
                .post(tap: .cghidEventTap)
        }
    }

    fileprivate func scroll(deltaX: Double, deltaY: Double) {
        CGEvent(
            scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: Int32(-deltaY),
            wheel2: Int32(deltaX), wheel3: 0)?
            .post(tap: .cghidEventTap)
    }

    fileprivate func typeText(_ text: String) {
        for scalar in text.unicodeScalars {
            var value = UniChar(scalar.value)
            let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &value)
            down?.post(tap: .cghidEventTap)

            let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &value)
            up?.post(tap: .cghidEventTap)
        }
    }

    fileprivate func pressKey(named key: String) {
        let normalized = key.lowercased()

        if let modifier = modifierFlag(for: normalized),
            let keyCode = modifierKeyCode(for: normalized)
        {
            postKey(keyCode, keyDown: true, flags: modifier)
            postKey(keyCode, keyDown: false, flags: [])
            return
        }

        guard let keyCode = keyCode(for: normalized) else {
            typeText(key)
            return
        }

        postKey(keyCode, keyDown: true, flags: [])
        postKey(keyCode, keyDown: false, flags: [])
    }

    fileprivate func withModifiers(_ keys: [String]?, action: () -> Void) {
        let flags = (keys ?? [])
            .compactMap { modifierFlag(for: $0.lowercased()) }
            .reduce(CGEventFlags()) { $0.union($1) }
        let keyCodes = (keys ?? []).compactMap { modifierKeyCode(for: $0.lowercased()) }

        for keyCode in keyCodes {
            postKey(keyCode, keyDown: true, flags: flags)
        }

        action()

        for keyCode in keyCodes.reversed() {
            postKey(keyCode, keyDown: false, flags: flags)
        }
    }

    fileprivate func postKey(_ keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags) {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
        event?.flags = flags
        event?.post(tap: .cghidEventTap)
    }

    fileprivate func cgMouseButton(_ button: String?) -> CGMouseButton {
        switch button?.lowercased() {
        case "right":
            return .right
        case "middle":
            return .center
        default:
            return .left
        }
    }

    fileprivate func modifierFlag(for key: String) -> CGEventFlags? {
        switch key {
        case "cmd", "command", "meta":
            return .maskCommand
        case "ctrl", "control":
            return .maskControl
        case "shift":
            return .maskShift
        case "alt", "option":
            return .maskAlternate
        default:
            return nil
        }
    }

    fileprivate func modifierKeyCode(for key: String) -> CGKeyCode? {
        switch key {
        case "cmd", "command", "meta":
            return CGKeyCode(kVK_Command)
        case "ctrl", "control":
            return CGKeyCode(kVK_Control)
        case "shift":
            return CGKeyCode(kVK_Shift)
        case "alt", "option":
            return CGKeyCode(kVK_Option)
        default:
            return nil
        }
    }

    fileprivate func keyCode(for key: String) -> CGKeyCode? {
        let map: [String: Int] = [
            "return": kVK_Return, "enter": kVK_Return, "tab": kVK_Tab, "space": kVK_Space,
            "escape": kVK_Escape, "esc": kVK_Escape, "backspace": kVK_Delete,
            "delete": kVK_ForwardDelete, "arrowleft": kVK_LeftArrow, "left": kVK_LeftArrow,
            "arrowright": kVK_RightArrow, "right": kVK_RightArrow, "arrowup": kVK_UpArrow,
            "up": kVK_UpArrow, "arrowdown": kVK_DownArrow, "down": kVK_DownArrow,
            "home": kVK_Home, "end": kVK_End, "pageup": kVK_PageUp, "pagedown": kVK_PageDown,
            "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
            "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
            "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
            "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
            "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
            "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
            "y": kVK_ANSI_Y, "z": kVK_ANSI_Z, "0": kVK_ANSI_0, "1": kVK_ANSI_1,
            "2": kVK_ANSI_2, "3": kVK_ANSI_3, "4": kVK_ANSI_4, "5": kVK_ANSI_5,
            "6": kVK_ANSI_6, "7": kVK_ANSI_7, "8": kVK_ANSI_8, "9": kVK_ANSI_9,
        ]
        return map[key].map { CGKeyCode($0) }
    }
}

extension ComputerUseRunner {
    fileprivate func promptDialog(defaultValue: String) -> String? {
        let alert = NSAlert()
        alert.messageText = "Ask Computer Use"
        alert.informativeText = "Enter a task for the built-in computer-use loop."
        alert.addButton(withTitle: "Perform")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 420, height: 24))
        textField.stringValue = defaultValue
        textField.placeholderString = "Example: click cell 13, type hello, then press Send"
        alert.accessoryView = textField

        DispatchQueue.main.async {
            alert.window.makeFirstResponder(textField)
        }

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        return textField.stringValue
    }

    fileprivate func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Computer Use Error"
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
