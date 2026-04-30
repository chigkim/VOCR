//
//  Utils.swift
//  VOCR
//
//  Created by Chi Kim on 10/2/22.
//  Copyright © 2022 Chi Kim. All rights reserved.
//

import Cocoa
import Vision
import os

let logger = FileLogger.shared
func log<T>(_ object: T, _ level: OSLogType = .info) {
    logger.log("\(String(describing: object))")
}

func hide() {
    let windows = NSApplication.shared.windows
    NSApplication.shared.hide(nil)
    if windows.indices.contains(1) {
        windows[1].close()
    }
}

func alert(_ title: String, _ message: String) {
    DispatchQueue.main.async {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
        return
    }
}

func askPrompt(value: String) -> (prompt: String, followUp: Bool)? {
    let alert = NSAlert()
    alert.messageText = NSLocalizedString(
        "dialog.prompt.title", value: "Prompt", comment: "Title for prompt dialog")
    alert.addButton(
        withTitle: NSLocalizedString(
            "button.ask", value: "Ask", comment: "Button title to submit a prompt"))
    alert.addButton(
        withTitle: NSLocalizedString(
            "button.cancel", value: "Cancel", comment: "Button title to cancel an action"))

    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false

    let promptSize = NSSize(width: 760, height: 320)
    let scrollView = NSScrollView(frame: NSRect(origin: .zero, size: promptSize))
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.borderType = .bezelBorder

    let inputTextView = NSTextView(frame: scrollView.bounds)
    inputTextView.isRichText = false
    inputTextView.isEditable = true
    inputTextView.isSelectable = true
    inputTextView.isHorizontallyResizable = false
    inputTextView.isVerticallyResizable = true
    inputTextView.autoresizingMask = [.width]
    inputTextView.minSize = NSSize(width: 0, height: promptSize.height)
    inputTextView.maxSize = NSSize(
        width: CGFloat.greatestFiniteMagnitude,
        height: CGFloat.greatestFiniteMagnitude)
    inputTextView.string = value
    inputTextView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    inputTextView.textContainer?.containerSize = NSSize(
        width: promptSize.width,
        height: CGFloat.greatestFiniteMagnitude)
    inputTextView.textContainer?.widthTracksTextView = true

    scrollView.documentView = inputTextView
    stackView.addArrangedSubview(scrollView)

    // Checkbox
    let followUpButton = NSButton(
        checkboxWithTitle: NSLocalizedString(
            "dialog.followup.checkbox", value: "Follow up",
            comment: "Checkbox label for enabling follow-up mode"), target: nil, action: nil)
    stackView.addArrangedSubview(followUpButton)

    let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: promptSize.width, height: promptSize.height + 28))
    accessoryView.addSubview(stackView)
    NSLayoutConstraint.activate([
        accessoryView.widthAnchor.constraint(equalToConstant: promptSize.width),
        accessoryView.heightAnchor.constraint(equalToConstant: promptSize.height + 28),
        stackView.leadingAnchor.constraint(equalTo: accessoryView.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor),
        stackView.topAnchor.constraint(equalTo: accessoryView.topAnchor),
        stackView.bottomAnchor.constraint(equalTo: accessoryView.bottomAnchor),
        scrollView.widthAnchor.constraint(equalToConstant: promptSize.width),
        scrollView.heightAnchor.constraint(equalToConstant: promptSize.height),
    ])

    alert.accessoryView = accessoryView

    DispatchQueue.main.async {
        alert.window.makeFirstResponder(inputTextView)
    }

    let response = alert.runModal()
    hide()
    if response == .alertFirstButtonReturn {
        let prompt = inputTextView.string
        return (prompt, followUpButton.state == .on)
    }
    return nil
}

func grabImage() -> CGImage? {
    var rect: CGRect?
    if Navigation.mode == .WINDOW {
        rect = Navigation.getWindow()
    } else if Navigation.mode == .VOCURSOR {
        rect = Navigation.getVOCursor()
    }
    if let rect = rect,
        let screenshot = ScreenCapture.capture(rect: rect)
    {
        return screenshot
    } else if Navigation.mode == .CAMERA {
        return Navigation.cgImage
    } else {
        Accessibility.speakWithSynthesizer(
            String(
                format: NSLocalizedString(
                    "error.access.message", value: "Failed to access %@, %@",
                    comment: "Speech message when failing to access application or window"),
                Navigation.appName, Navigation.windowName))
    }
    return nil
}

func ask(image: CGImage? = nil) {
    let cgImage = image ?? grabImage()
    guard let cgImage = cgImage else { return }
    guard let preset = PresetManager.shared.activePreset() else {
        return
    }
    let presetPrompt = preset.prompt
    let system = preset.systemPrompt
    var prompt = ""
    var followUp = false
    if Settings.usePresetPrompt {
        prompt = presetPrompt
    } else {
        if let customPrompt = askPrompt(value: Settings.prompt) {
            prompt = customPrompt.prompt
            followUp = customPrompt.followUp
            Settings.prompt = prompt
        } else {
            return
        }
    }

    OpenAIAPI.describe(image: cgImage, system: system, prompt: prompt, followUp: followUp) {
        description in
        NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
        sleep(1)
        Accessibility.speak(description)
    }
}

func copyToClipboard(_ string: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(string, forType: .string)
}

func saveImage(_ cgImage: CGImage) throws {
    let savePanel = NSSavePanel()
    savePanel.title = NSLocalizedString(
        "dialog.save.title", value: "Save Your File", comment: "Title for save file dialog")
    savePanel.message = NSLocalizedString(
        "dialog.save.message", value: "Choose a destination and save your file.",
        comment: "Message for save file dialog")
    savePanel.allowedContentTypes = [.png]
    savePanel.nameFieldStringValue = Navigation.appName + ".png"
    savePanel.begin { response in
        hide()
        if response == .OK {
            if let selectedURL = savePanel.url {
                let cicontext = CIContext()
                let ciimage = CIImage(cgImage: cgImage)
                let colorSpace = ciimage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
                try? cicontext.writePNGRepresentation(
                    of: ciimage, to: selectedURL, format: .RGBA8, colorSpace: colorSpace)
            }
        }
        let windows = NSApplication.shared.windows
        NSApplication.shared.hide(nil)
        if windows.indices.contains(1) {
            windows[1].close()
        }
    }
}

enum ScreenCapture {
    static func capture(rect: CGRect) -> CGImage? {
        var displayCount: UInt32 = 0
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        guard result == .success else {
            log("error: \(result)")
            return nil
        }

        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(
            capacity: Int(displayCount))
        defer { activeDisplays.deallocate() }

        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
        guard result == .success else {
            log("error: \(result)")
            return nil
        }

        guard let cgImage = CGDisplayCreateImage(activeDisplays[0], rect: rect) else {
            return nil
        }
        log("Original: \(cgImage.width), \(cgImage.height)")
        Navigation.cgImage = cgImage
        return cgImage
    }

    static func resized(_ cgImage: CGImage, width: Int, height: Int) -> CGImage? {
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

    static func base64(_ image: CGImage, type: NSBitmapImageRep.FileType) -> String? {
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        return bitmapRep.representation(using: type, properties: [:])?
            .base64EncodedString(options: [])
    }
}

enum VisionOCR {
    static func recognizedText(in cgImage: CGImage) -> [VNRecognizedTextObservation] {
        let request = textRecognitionRequest()
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            log("OCR failed: \(error)")
        }
        return request.results ?? []
    }

    static func observations(in cgImage: CGImage, detectObjects: Bool) -> [Observation] {
        let textRecognitionRequest = textRecognitionRequest()
        let rectDetectRequest = rectangleDetectionRequest()
        let requests: [VNRequest] = detectObjects
            ? [textRecognitionRequest, rectDetectRequest]
            : [textRecognitionRequest]

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform(requests)
        } catch {
            log("OCR failed: \(error)")
        }

        guard let texts = textRecognitionRequest.results else {
            return []
        }

        var result = texts.map { Observation($0) }
        guard detectObjects, let boxes = rectDetectRequest.results else {
            return result
        }

        var boxesNoText: [Observation] = []
        var boxesText: [Observation] = []
        for box in boxes {
            var intersectsText = false
            for text in texts {
                if box.boundingBox.intersects(text.boundingBox) {
                    boxesText.append(
                        Observation(box, value: "Text: " + text.topCandidates(1)[0].string))
                    intersectsText = true
                    break
                }
            }
            if !intersectsText {
                let obs = Observation(box, value: "OBJECT")
                boxesNoText.append(obs)
                result.append(obs)
            }
        }

        log("Box Count: \(boxes.count)")
        log("Text Count: \(texts.count)")
        log("boxesNoText Count: \(boxesNoText.count)")
        log("boxesText count: \(boxesText.count)")
        return result
    }

    private static func textRecognitionRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.minimumTextHeight = 0
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        request.customWords = []
        request.usesCPUOnly = false
        return request
    }

    private static func rectangleDetectionRequest() -> VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1000
        request.minimumConfidence = 0.0
        request.minimumAspectRatio = 0.0
        request.minimumSize = 0.0
        return request
    }
}

func classify(cgImage: CGImage) -> String {
    var message = ""
    var categories: [String: VNConfidence] = [:]
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    let request = VNClassifyImageRequest()
    try? handler.perform([request])
    guard let observations = request.results else {
        return message
    }
    categories =
        observations
        .filter { $0.hasMinimumRecall(0.1, forPrecision: 0.9) }
        .reduce(into: [String: VNConfidence]()) { dict, observation in
            dict[observation.identifier] = observation.confidence
        }
    let classes = categories.sorted(by: { ($0.value > $1.value) })
    log("Classes: \(classes)")
    var count = classes.count
    if count > 0 {
        if count > 5 {
            count = 5
        }

        for c in 0..<count {
            message += "\(classes[c].key), "
        }
        Accessibility.speak(message)
    } else {
        Accessibility.speak(
            NSLocalizedString(
                "dialog.classification.unknown", value: "Unknown",
                comment: "Speech message when image classification returns no results"))
    }
    return message
}

func runAppleScript(file: String) -> String? {
    let bundle = Bundle.main
    let script = bundle.url(forResource: file, withExtension: "scpt")
    log("\(script!)")
    var error: NSDictionary?
    if let scriptObject = NSAppleScript(contentsOf: script!, error: &error) {
        var outputError: NSDictionary?
        if let output = scriptObject.executeAndReturnError(&outputError).stringValue {
            log("\(output)")
            return output
        } else {
            log("Output Error: \(String(describing: outputError))")
        }
    }
    return nil
}
