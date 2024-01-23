//
//  AutoUpdateManager.swift
//  VOCR
//
//  Created by Chi Kim on 1/18/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Foundation
import Cocoa
import Sparkle
import UserNotifications

class AutoUpdateManager: NSObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate, UNUserNotificationCenterDelegate {

	static let shared = AutoUpdateManager()
	var updaterController: SPUStandardUpdaterController?
	private let UPDATE_NOTIFICATION_IDENTIFIER = "VOCRUpdateCheck"
		var supportsGentleScheduledUpdateReminders: Bool {
		return true
	}

	private override init() {
		super.init()
		UNUserNotificationCenter.current().delegate = self
		self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
		if let automaticallyChecksForUpdates = self.updaterController?.updater.automaticallyChecksForUpdates, automaticallyChecksForUpdates {
			self.updaterController?.updater.checkForUpdatesInBackground()
		}
	}

	func checkForUpdates() {
		updaterController?.checkForUpdates(nil)
	}

	func allowedChannels(for updater: SPUUpdater) -> Set<String> {
		if Settings.preRelease {
			log("Download pre-release.")
			updater.updateCheckInterval = 3600
			return Set(["pre"])
		} else {
			log("No pre-release.")
			updater.updateCheckInterval = 3600*24
			return Set()
		}
	}

	func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval) {
		UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { granted, error in
			// Examine granted outcome and error if desired...
		}
	}
	
	func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
		NSApp.setActivationPolicy(.regular)
		if !state.userInitiated {
			NSApp.dockTile.badgeLabel = "1"
			do {
				let content = UNMutableNotificationContent()
				content.title = "A new update is available"
				content.body = "Version \(update.displayVersionString) is now available"
				content.sound = UNNotificationSound.default
				let request = UNNotificationRequest(identifier: UPDATE_NOTIFICATION_IDENTIFIER, content: content, trigger: nil)
				UNUserNotificationCenter.current().add(request)
			}
		}
	}

	func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
		NSApp.dockTile.badgeLabel = ""
		UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [UPDATE_NOTIFICATION_IDENTIFIER])
	}
	
	func standardUserDriverWillFinishUpdateSession() {
		NSApp.setActivationPolicy(.accessory)
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		if response.notification.request.identifier == UPDATE_NOTIFICATION_IDENTIFIER && response.actionIdentifier == UNNotificationDefaultActionIdentifier {
			updaterController?.checkForUpdates(nil)
		}
		completionHandler()
	}

}

