//
//  PermissionsViewController.swift
//  VOCR
//
//  Created by Claude Code on 2/11/26.
//  Copyright © 2026 Chi Kim. All rights reserved.
//

import Cocoa

final class PermissionsViewController: NSViewController {

    // UI Components
    private let headerLabel = NSTextField()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()

    // Data
    private var permissions: [PermissionsManager.Permission] = [
        .accessibility,
        .voiceOver,
        .screenRecording,
        .camera,
        .notifications,
    ]
    private var statuses: [PermissionsManager.Permission: PermissionsManager.PermissionStatus] = [:]

    // Column IDs
    private enum ColumnID {
        static let permission = NSUserInterfaceItemIdentifier("PermissionColumn")
        static let reason = NSUserInterfaceItemIdentifier("ReasonColumn")
        static let action = NSUserInterfaceItemIdentifier("ActionColumn")
    }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 280))
        setupUI()
        refreshStatuses()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        tableView.frame = scrollView.contentView.bounds
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.makeFirstResponder(tableView)
        refreshStatuses()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        NotificationCenter.default.removeObserver(
            self, name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        refreshStatuses()
    }

    private func setupUI() {
        headerLabel.isEditable = false
        headerLabel.isSelectable = true
        headerLabel.isBordered = false
        headerLabel.drawsBackground = false
        headerLabel.font = .systemFont(ofSize: 13)
        headerLabel.textColor = .labelColor
        headerLabel.maximumNumberOfLines = 0
        headerLabel.stringValue = NSLocalizedString(
            "permissions.window.instructions",
            value: "Please grant the following permissions for VOCR to work properly.",
            comment: "Instruction text at the top of the permissions window")
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)

        // Configure table columns
        let permissionColumn = NSTableColumn(identifier: ColumnID.permission)
        permissionColumn.title = NSLocalizedString(
            "column.permission", value: "Permission",
            comment: "Table column header for permission name")
        permissionColumn.width = 150
        tableView.addTableColumn(permissionColumn)

        let reasonColumn = NSTableColumn(identifier: ColumnID.reason)
        reasonColumn.title = NSLocalizedString(
            "column.reason", value: "Reason", comment: "Table column header for permission reason")
        reasonColumn.width = 220
        tableView.addTableColumn(reasonColumn)

        let actionColumn = NSTableColumn(identifier: ColumnID.action)
        actionColumn.title = NSLocalizedString(
            "column.action", value: "Action", comment: "Table column header for permission action")
        actionColumn.width = 150
        tableView.addTableColumn(actionColumn)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = NSRect(x: 0, y: 0, width: 560, height: 150)
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        tableView.selectionHighlightStyle = .regular

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        view.addSubview(scrollView)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Instruction text at top
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Table view below instruction text
            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 150),
            scrollView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20),
        ])
    }

    private func refreshStatuses() {
        statuses = PermissionsManager.shared.checkAllStatuses()

        // For notifications, we need to check asynchronously
        PermissionsManager.shared.checkNotificationStatus { [weak self] status in
            self?.statuses[.notifications] = status
            self?.tableView.reloadData()
        }

        tableView.reloadData()

        // Select first row if nothing is selected
        if tableView.selectedRow < 0 && !permissions.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    private func title(for permission: PermissionsManager.Permission) -> String {
        switch permission {
        case .camera:
            return NSLocalizedString(
                "permission.camera.optional_name",
                value: "Camera (Optional)",
                comment: "Name for optional camera permission")
        case .notifications:
            return NSLocalizedString(
                "permission.notifications.optional_name",
                value: "Notification (Optional)",
                comment: "Name for optional notification permission")
        default:
            return permission.displayName
        }
    }

    private func reason(for permission: PermissionsManager.Permission) -> String {
        switch permission {
        case .accessibility:
            return NSLocalizedString(
                "permission.accessibility.reason",
                value: "Capture global shortcuts",
                comment: "Short reason for accessibility permission")
        case .voiceOver:
            return NSLocalizedString(
                "permission.voiceover.reason",
                value: "Read announcements with VoiceOver",
                comment: "Short reason for VoiceOver permission")
        case .screenRecording:
            return NSLocalizedString(
                "permission.screenrecording.reason",
                value: "Capture screenshots for OCR",
                comment: "Short reason for screen recording permission")
        case .camera:
            return NSLocalizedString(
                "permission.camera.reason",
                value: "Describe images from camera",
                comment: "Short reason for camera permission")
        case .notifications:
            return NSLocalizedString(
                "permission.notifications.reason",
                value: "Notify for updates",
                comment: "Short reason for notifications permission")
        }
    }

    private func actionButtonTitle(for permission: PermissionsManager.Permission) -> String {
        let status = statuses[permission] ?? .notDetermined

        switch (permission, status) {
        case (.accessibility, .granted):
            return NSLocalizedString(
                "button.permission.granted", value: "✓ Granted",
                comment: "Button text when permission is granted")
        case (.accessibility, _):
            return NSLocalizedString(
                "button.permission.opensystemprefs", value: "Open System Settings",
                comment: "Button text to open system settings")

        case (.screenRecording, .granted):
            return NSLocalizedString(
                "button.permission.granted", value: "✓ Granted",
                comment: "Button text when permission is granted")
        case (.screenRecording, _):
            return NSLocalizedString(
                "button.permission.opensystemprefs", value: "Open System Settings",
                comment: "Button text to open system settings")

        case (.camera, .granted):
            return NSLocalizedString(
                "button.permission.granted", value: "✓ Granted",
                comment: "Button text when permission is granted")
        case (.camera, .notDetermined):
            return NSLocalizedString(
                "button.permission.enable", value: "Enable",
                comment: "Button text to enable permission")
        case (.camera, _):
            return NSLocalizedString(
                "button.permission.opensystemprefs", value: "Open System Settings",
                comment: "Button text to open system settings")

        case (.notifications, .granted):
            return NSLocalizedString(
                "button.permission.granted", value: "✓ Granted",
                comment: "Button text when permission is granted")
        case (.notifications, .notDetermined):
            return NSLocalizedString(
                "button.permission.enable", value: "Enable",
                comment: "Button text to enable permission")
        case (.notifications, _):
            return NSLocalizedString(
                "button.permission.opensystemprefs", value: "Open System Settings",
                comment: "Button text to open system settings")

        case (.voiceOver, .granted):
            return NSLocalizedString(
                "button.permission.granted", value: "✓ Granted",
                comment: "Button text when permission is granted")
        case (.voiceOver, _):
            return NSLocalizedString(
                "button.permission.opensystemprefs", value: "Open System Settings",
                comment: "Button text to open system settings")
        }
    }

    @objc private func handleActionButton(_ sender: NSButton) {
        let row = tableView.row(for: sender)
        guard row >= 0 && row < permissions.count else { return }

        let permission = permissions[row]
        let status = statuses[permission] ?? .notDetermined

        switch permission {
        case .accessibility:
            PermissionsManager.shared.requestAccessibility()
            // Give user time to grant permission, then refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.refreshStatuses()
            }

        case .screenRecording:
            PermissionsManager.shared.requestScreenRecording()
            // Give user time to grant permission, then refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.refreshStatuses()
            }

        case .camera:
            if status == .notDetermined {
                PermissionsManager.shared.requestCamera { [weak self] granted in
                    self?.refreshStatuses()
                }
            } else {
                PermissionsManager.shared.openSystemPreferences(for: .camera)
            }

        case .notifications:
            if status == .notDetermined {
                PermissionsManager.shared.requestNotifications { [weak self] granted in
                    self?.refreshStatuses()
                }
            } else {
                PermissionsManager.shared.openSystemPreferences(for: .notifications)
            }

        case .voiceOver:
            PermissionsManager.shared.requestVoiceOver()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.refreshStatuses()
            }
        }
    }
}

// MARK: - NSTableViewDataSource & NSTableViewDelegate

extension PermissionsViewController: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return permissions.count
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        guard let columnID = tableColumn?.identifier else { return nil }
        guard row >= 0 && row < permissions.count else { return nil }

        let permission = permissions[row]
        let status = statuses[permission] ?? .notDetermined

        switch columnID {
        case ColumnID.permission:
            let cellView = NSTextField()
            cellView.isEditable = false
            cellView.isSelectable = false
            cellView.isBordered = false
            cellView.drawsBackground = false
            cellView.stringValue = title(for: permission)
            return cellView

        case ColumnID.reason:
            let cellView = NSTextField()
            cellView.isEditable = false
            cellView.isSelectable = false
            cellView.isBordered = false
            cellView.drawsBackground = false
            cellView.stringValue = reason(for: permission)
            return cellView

        case ColumnID.action:
            let button = NSButton(
                title: actionButtonTitle(for: permission), target: self,
                action: #selector(handleActionButton(_:)))
            button.bezelStyle = .rounded
            button.isEnabled = (status != .granted && status != .restricted)
            return button

        default:
            return nil
        }
    }
}
