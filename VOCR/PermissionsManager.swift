//
//  PermissionsManager.swift
//  VOCR
//
//  Created by Claude Code on 2/11/26.
//  Copyright © 2026 Chi Kim. All rights reserved.
//

import Carbon
import Cocoa
import UserNotifications

/// Singleton manager for all app permissions.
/// Centralizes permission status checking, requesting, and onboarding state.
final class PermissionsManager {
    static let shared = PermissionsManager()

    private let onboardingDefaultsKey = "VOCR.hasSeenPermissionsOnboarding"

    // Set to true within a session once the user has been sent to grant screen recording.
    // CGPreflightScreenCaptureAccess() caches its result per process and won't reflect a
    // mid-session grant until the app is restarted; this flag suppresses the false-negative.
    private var screenRecordingRequested = false

    private init() {}

    // MARK: - Permission Types

    enum Permission: String, CaseIterable {
        case accessibility
        case screenRecording
        case notifications
        case voiceOver

        var displayName: String {
            switch self {
            case .accessibility:
                return NSLocalizedString(
                    "permission.accessibility.name",
                    value: "Accessibility",
                    comment: "Name for accessibility permission")
            case .screenRecording:
                return NSLocalizedString(
                    "permission.screenrecording.name",
                    value: "Screen Recording",
                    comment: "Name for screen recording permission")
            case .notifications:
                return NSLocalizedString(
                    "permission.notifications.name",
                    value: "Notifications",
                    comment: "Name for notifications permission")
            case .voiceOver:
                return NSLocalizedString(
                    "permission.voiceover.name",
                    value: "VoiceOver",
                    comment: "Name for VoiceOver automation permission")
            }
        }

        var statusEmoji: String {
            switch self {
            case .accessibility:
                return "⚙️"
            case .screenRecording:
                return "🖥️"
            case .notifications:
                return "🔔"
            case .voiceOver:
                return "♿️"
            }
        }

        var description: String {
            switch self {
            case .accessibility:
                return NSLocalizedString(
                    "permission.accessibility.description",
                    value: "VOCR needs Accessibility access to:",
                    comment: "Description header for accessibility permission")
            case .screenRecording:
                return NSLocalizedString(
                    "permission.screenrecording.description",
                    value: "VOCR needs Screen Recording access to:",
                    comment: "Description header for screen recording permission")
            case .notifications:
                return NSLocalizedString(
                    "permission.notifications.description",
                    value: "VOCR needs Notifications to:",
                    comment: "Description header for notifications permission")
            case .voiceOver:
                return NSLocalizedString(
                    "permission.voiceover.description",
                    value: "VOCR needs VoiceOver access to:",
                    comment: "Description header for VoiceOver automation permission")
            }
        }

        var featuresList: [String] {
            switch self {
            case .accessibility:
                return [
                    NSLocalizedString(
                        "permission.accessibility.feature1",
                        value: "Read text from your screen for OCR",
                        comment: "Accessibility permission feature"),
                    NSLocalizedString(
                        "permission.accessibility.feature2",
                        value: "Control VoiceOver cursor position",
                        comment: "Accessibility permission feature"),
                    NSLocalizedString(
                        "permission.accessibility.feature3",
                        value: "Take screenshots under the VoiceOver cursor",
                        comment: "Accessibility permission feature"),
                    NSLocalizedString(
                        "permission.accessibility.feature4",
                        value: "Interact with window content",
                        comment: "Accessibility permission feature"),
                ]
            case .screenRecording:
                return [
                    NSLocalizedString(
                        "permission.screenrecording.feature1",
                        value: "Capture screen content for OCR",
                        comment: "Screen recording permission feature"),
                    NSLocalizedString(
                        "permission.screenrecording.feature2",
                        value: "Take screenshots of windows and displays",
                        comment: "Screen recording permission feature"),
                    NSLocalizedString(
                        "permission.screenrecording.feature3",
                        value: "Extract text from screen regions",
                        comment: "Screen recording permission feature"),
                ]
            case .notifications:
                return [
                    NSLocalizedString(
                        "permission.notifications.feature1",
                        value: "Alert you when updates are available",
                        comment: "Notifications permission feature"),
                    NSLocalizedString(
                        "permission.notifications.feature2",
                        value: "Show OCR completion notifications",
                        comment: "Notifications permission feature"),
                    NSLocalizedString(
                        "permission.notifications.feature3",
                        value: "Provide background task updates",
                        comment: "Notifications permission feature"),
                ]
            case .voiceOver:
                return [
                    NSLocalizedString(
                        "permission.voiceover.feature1",
                        value: "Speak announcements through VoiceOver",
                        comment: "VoiceOver automation permission feature"),
                    NSLocalizedString(
                        "permission.voiceover.feature2",
                        value: "Control VoiceOver cursor and navigation",
                        comment: "VoiceOver automation permission feature"),
                    NSLocalizedString(
                        "permission.voiceover.feature3",
                        value: "Read the currently focused element via VoiceOver",
                        comment: "VoiceOver automation permission feature"),
                ]
            }
        }

        var isRequired: Bool {
            switch self {
            case .accessibility:
                return true
            case .screenRecording:
                return true
            case .notifications:
                return false
            case .voiceOver:
                return true
            }
        }

        var requirementText: String {
            if isRequired {
                return NSLocalizedString(
                    "permission.required",
                    value: "This permission is required for core OCR functionality.",
                    comment: "Text indicating permission is required")
            } else {
                return NSLocalizedString(
                    "permission.optional",
                    value: "This permission is optional but enhances functionality.",
                    comment: "Text indicating permission is optional")
            }
        }
    }

    // MARK: - Permission Status

    enum PermissionStatus {
        case granted
        case denied
        case notDetermined
        case restricted

        var displayText: String {
            switch self {
            case .granted:
                return NSLocalizedString(
                    "permission.status.granted",
                    value: "✓ Granted",
                    comment: "Status text for granted permission")
            case .denied:
                return NSLocalizedString(
                    "permission.status.denied",
                    value: "✗ Unset",
                    comment: "Status text for denied permission")
            case .notDetermined:
                return NSLocalizedString(
                    "permission.status.notset",
                    value: "⚠️ Not Set",
                    comment: "Status text for not determined permission")
            case .restricted:
                return NSLocalizedString(
                    "permission.status.restricted",
                    value: "🚫 Restricted",
                    comment: "Status text for restricted permission")
            }
        }
    }

    // MARK: - Status Checking

    func status(for permission: Permission) -> PermissionStatus {
        switch permission {
        case .accessibility:
            return accessibilityStatus()
        case .screenRecording:
            return screenRecordingStatus()
        case .notifications:
            return notificationsStatus()
        case .voiceOver:
            return voiceOverStatus()
        }
    }

    func checkAllStatuses() -> [Permission: PermissionStatus] {
        var statuses: [Permission: PermissionStatus] = [:]
        for permission in Permission.allCases {
            statuses[permission] = status(for: permission)
        }
        return statuses
    }

    private func accessibilityStatus() -> PermissionStatus {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        return isTrusted ? .granted : .denied
    }

    private func screenRecordingStatus() -> PermissionStatus {
        if CGPreflightScreenCaptureAccess() {
            return .granted
        }
        // CGPreflightScreenCaptureAccess() caches its result for the lifetime of the process.
        // If the user was sent to grant this permission in the current session, treat it as
        // granted so the warning is suppressed until restart (when the API reflects correctly).
        return screenRecordingRequested ? .granted : .denied
    }

    private func notificationsStatus() -> PermissionStatus {
        // Notifications status must be checked asynchronously, but we'll do a synchronous
        // approximation here. For proper async status, call getNotificationSettings directly.
        // This is a simplified version that returns notDetermined initially.
        // The actual status will be updated when the async method completes.
        return .notDetermined
    }

    private func voiceOverStatus() -> PermissionStatus {
        if #available(macOS 10.14, *) {
            let descriptor = NSAppleEventDescriptor(bundleIdentifier: "com.apple.VoiceOver")
            let result = AEDeterminePermissionToAutomateTarget(
                descriptor.aeDesc, typeWildCard, typeWildCard, false)
            switch result {
            case noErr: return .granted
            case OSStatus(errAEEventNotPermitted): return .denied
            default: return .notDetermined
            }
        }
        return .notDetermined
    }

    // Async method for checking notification status properly
    func checkNotificationStatus(completion: @escaping (PermissionStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status: PermissionStatus
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                status = .granted
            case .denied:
                status = .denied
            case .notDetermined:
                status = .notDetermined
            case .ephemeral:
                status = .granted
            @unknown default:
                status = .notDetermined
            }

            DispatchQueue.main.async {
                completion(status)
            }
        }
    }

    // MARK: - Permission Requesting

    func requestAccessibility() {
        // Accessibility permission can only be granted in System Preferences
        openSystemPreferences(for: .accessibility)
    }

    func requestScreenRecording() {
        screenRecordingRequested = true
        // CGRequestScreenCaptureAccess() registers VOCR in System Settings > Screen Recording
        // and presents the system permission dialog, which includes an "Open System Preferences"
        // button. We don't also call openSystemPreferences() to avoid both appearing at once.
        CGRequestScreenCaptureAccess()
    }

    func requestVoiceOver() {
        // Trigger TCC prompts for both System Events (used internally to detect if VoiceOver
        // is running) and VoiceOver itself by sending harmless real Apple Events.
        let systemEventsScript = NSAppleScript(
            source: "tell application \"System Events\" to get name")
        var error: NSDictionary?
        systemEventsScript?.executeAndReturnError(&error)

        let voiceOverScript = NSAppleScript(source: "tell application \"VoiceOver\" to get name")
        voiceOverScript?.executeAndReturnError(&error)

        openSystemPreferences(for: .voiceOver)
    }

    func requestNotifications(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // MARK: - System Preferences

    func openSystemPreferences(for permission: Permission) {
        let prefPane: String

        switch permission {
        case .accessibility:
            // macOS 13+ uses new Settings app
            if #available(macOS 13, *) {
                prefPane =
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            } else {
                prefPane =
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            }

        case .screenRecording:
            if #available(macOS 13, *) {
                prefPane =
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            } else {
                prefPane =
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            }

        case .notifications:
            if #available(macOS 13, *) {
                prefPane = "x-apple.systempreferences:com.apple.preference.notifications"
            } else {
                prefPane = "x-apple.systempreferences:com.apple.preference.notifications"
            }

        case .voiceOver:
            prefPane = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        }

        if let url = URL(string: prefPane) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Onboarding State

    var hasSeenPermissionsOnboarding: Bool {
        get {
            return UserDefaults.standard.bool(forKey: onboardingDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: onboardingDefaultsKey)
        }
    }

    func markOnboardingComplete() {
        hasSeenPermissionsOnboarding = true
    }
}
