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

    static let speech: NSSpeechSynthesizer = NSSpeechSynthesizer()

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

    static func speakWithSynthesizer(_ message: String) {
        log("Speak with synthesizer: \(message)")
        DispatchQueue.global().async {
            speech.startSpeaking(message)
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
                debugPrint(outputError)
                log("Speak: \(output)")
            } else {
                log("Output Error: \(String(describing: outputError))")
            }
        } else {
            log("\(error!)")
        }
    }

}
