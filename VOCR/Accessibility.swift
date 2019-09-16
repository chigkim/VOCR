//
//  Accessibility.swift
//  Inspector
//
//  Created by Chi Kim on 10/29/18.
//  Copyright © 2018 Chi Kim. All rights reserved.
//

import Foundation
import Cocoa

class Accessibility {

	static let speech:NSSpeechSynthesizer = NSSpeechSynthesizer()

	static func isTrusted(ask:Bool) -> Bool {
	let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
	let options = [prompt: ask]
	return AXIsProcessTrustedWithOptions(options as CFDictionary?)
}

	static func notify(_ message:String) {
		let announcement = [NSAccessibility.NotificationUserInfoKey.announcement:message, NSAccessibility.NotificationUserInfoKey.priority:"High"]
		var element = NSApplication.shared as Any
		NSAccessibility.post(element:element, notification: NSAccessibility.Notification.announcementRequested, userInfo: announcement)
	}

	static func speak(_ message:String) {
		speech.startSpeaking(message)
	}

}
