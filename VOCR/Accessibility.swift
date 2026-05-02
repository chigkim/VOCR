//
//  Accessibility.swift
//  Inspector
//
//  Created by Chi Kim on 10/29/18.
//  Copyright © 2018 Chi Kim. All rights reserved.
//

import Carbon
import Cocoa

enum Accessibility {

    class SpeechDelegate: NSObject, NSSpeechSynthesizerDelegate {
        var onFinish: (() -> Void)?
        func speechSynthesizer(
            _ sender: NSSpeechSynthesizer, didFinishSpeaking finishedCharacterCount: Bool
        ) {
            onFinish?()
        }
    }

    static let speechDelegate = SpeechDelegate()
    static let speech: NSSpeechSynthesizer = {
        let synthesizer = NSSpeechSynthesizer()
        synthesizer.rate = 230
        synthesizer.delegate = speechDelegate
        return synthesizer
    }()

    static func isTrusted(ask: Bool) -> Bool {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [prompt: ask]
        return AXIsProcessTrustedWithOptions(options as CFDictionary?)
    }

    static func notify(_ message: String) {
        let announcement = [
            NSAccessibility.NotificationUserInfoKey.announcement: message,
            NSAccessibility.NotificationUserInfoKey.priority: "High",
        ]
        let element = NSApplication.shared as Any
        NSAccessibility.post(
            element: element, notification: NSAccessibility.Notification.announcementRequested,
            userInfo: announcement)
    }

    static func speakWithSynthesizer(_ message: String, completion: (() -> Void)? = nil) {
        log("Speak with synthesizer: \(message)")
        DispatchQueue.main.async {
            guard let completion = completion else {
                speech.startSpeaking(message)
                return
            }

            speechDelegate.onFinish = {
                speechDelegate.onFinish = nil
                completion()
            }
            if !speech.startSpeaking(message) {
                speechDelegate.onFinish = nil
                completion()
            }
        }
    }

    static func speakWithSynthesizerSynchronous(_ message: String) {
        log("Speak with synthesizer synchronous: \(message)")
        if Thread.isMainThread {
            var finished = false
            speechDelegate.onFinish = {
                finished = true
            }
            guard speech.startSpeaking(message) else {
                speechDelegate.onFinish = nil
                return
            }
            while !finished && speech.isSpeaking {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
            }
            speechDelegate.onFinish = nil
            return
        }

        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            speechDelegate.onFinish = {
                semaphore.signal()
            }
            if !speech.startSpeaking(message) {
                speechDelegate.onFinish = nil
                semaphore.signal()
            }
        }
        semaphore.wait()
        DispatchQueue.main.sync {
            speechDelegate.onFinish = nil
        }
    }

    static func stopSpeaking() {
        DispatchQueue.main.async {
            speech.stopSpeaking()
            speechDelegate.onFinish?()
            speechDelegate.onFinish = nil
        }
    }

    static func isVoiceOverRunning() -> Bool {
        let runningApplications = NSWorkspace.shared.runningApplications
        for app in runningApplications {
            if app.localizedName == "VoiceOver" {
                return true
            }
        }
        return false
    }

    static func speak(_ message: String) {
        if !isVoiceOverRunning() {
            speakWithSynthesizer(message)
            return
        }

        let bundle = Bundle.main
        let url = bundle.url(forResource: "say", withExtension: "scpt")
        let parameters = NSAppleEventDescriptor.list()
        parameters.insert(NSAppleEventDescriptor(string: message), at: 0)
        let event = NSAppleEventDescriptor.appleEvent(
            withEventClass: AEEventClass(kASAppleScriptSuite),
            eventID: AEEventID(kASSubroutineEvent),
            targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID))
        event.setDescriptor(
            NSAppleEventDescriptor(string: "speak"), forKeyword: AEKeyword(keyASSubroutineName))
        event.setDescriptor(parameters, forKeyword: AEKeyword(keyDirectObject))
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(contentsOf: url!, error: &error) {
            var outputError: NSDictionary?
            if let output = scriptObject.executeAppleEvent(event, error: &outputError).stringValue {
                if let outputError {
                    log("Speak output error: \(outputError)")
                }
                log("Speak: \(output)")
            } else {
                log("Output Error: \(String(describing: outputError))")
            }
        } else {
            log("\(error!)")
        }
    }

}
