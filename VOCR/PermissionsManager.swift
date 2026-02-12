//
//  PermissionsManager.swift
//  VOCR
//
//  Created by Claude Code on 2/11/26.
//  Copyright © 2026 Chi Kim. All rights reserved.
//

import AVFoundation
import Cocoa
import UserNotifications

/// Singleton manager for all app permissions.
/// Centralizes permission status checking, requesting, and onboarding state.
final class PermissionsManager {
    static let shared = PermissionsManager()

    private let onboardingDefaultsKey = "VOCR.hasSeenPermissionsOnboarding"

    private init() {}

    // MARK: - Permission Types

    enum Permission: String, CaseIterable {
        case accessibility
        case camera
        case notifications

        var displayName: String {
            switch self {
            case .accessibility:
                return NSLocalizedString(
                    "permission.accessibility.name",
                    value: "Accessibility",
                    comment: "Name for accessibility permission")
            case .camera:
                return NSLocalizedString(
                    "permission.camera.name",
                    value: "Camera",
                    comment: "Name for camera permission")
            case .notifications:
                return NSLocalizedString(
                    "permission.notifications.name",
                    value: "Notifications",
                    comment: "Name for notifications permission")
            }
        }

        var statusEmoji: String {
            switch self {
            case .accessibility:
                return "⚙️"
            case .camera:
                return "📷"
            case .notifications:
                return "🔔"
            }
        }

        var description: String {
            switch self {
            case .accessibility:
                return NSLocalizedString(
                    "permission.accessibility.description",
                    value: "VOCR needs Accessibility access to:",
                    comment: "Description header for accessibility permission")
            case .camera:
                return NSLocalizedString(
                    "permission.camera.description",
                    value: "VOCR needs Camera access to:",
                    comment: "Description header for camera permission")
            case .notifications:
                return NSLocalizedString(
                    "permission.notifications.description",
                    value: "VOCR needs Notifications to:",
                    comment: "Description header for notifications permission")
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
            case .camera:
                return [
                    NSLocalizedString(
                        "permission.camera.feature1",
                        value: "Take photos for OCR analysis",
                        comment: "Camera permission feature"),
                    NSLocalizedString(
                        "permission.camera.feature2",
                        value: "Capture images for AI description",
                        comment: "Camera permission feature"),
                    NSLocalizedString(
                        "permission.camera.feature3",
                        value: "Use camera-based text recognition",
                        comment: "Camera permission feature"),
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
            }
        }

        var isRequired: Bool {
            switch self {
            case .accessibility:
                return true
            case .camera:
                return false
            case .notifications:
                return false
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
                    value: "✗ Denied",
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
        case .camera:
            return cameraStatus()
        case .notifications:
            return notificationsStatus()
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

    private func cameraStatus() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private func notificationsStatus() -> PermissionStatus {
        // Notifications status must be checked asynchronously, but we'll do a synchronous
        // approximation here. For proper async status, call getNotificationSettings directly.
        // This is a simplified version that returns notDetermined initially.
        // The actual status will be updated when the async method completes.
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

    func requestCamera(completion: @escaping (Bool) -> Void) {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch currentStatus {
        case .authorized:
            completion(true)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }

        case .denied, .restricted:
            // Need to open System Preferences
            openSystemPreferences(for: .camera)
            completion(false)

        @unknown default:
            completion(false)
        }
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
                prefPane = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            } else {
                prefPane = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            }

        case .camera:
            if #available(macOS 13, *) {
                prefPane = "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
            } else {
                prefPane = "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
            }

        case .notifications:
            if #available(macOS 13, *) {
                prefPane = "x-apple.systempreferences:com.apple.preference.notifications"
            } else {
                prefPane = "x-apple.systempreferences:com.apple.preference.notifications"
            }
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
