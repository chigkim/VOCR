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
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()

    private let detailPanel = NSView()
    private let detailTitleLabel = NSTextField()
    private let detailDescriptionLabel = NSTextField()
    private let detailFeaturesLabel = NSTextField()
    private let detailRequirementLabel = NSTextField()

    // Data
    private var permissions: [PermissionsManager.Permission] = PermissionsManager.Permission.allCases
    private var statuses: [PermissionsManager.Permission: PermissionsManager.PermissionStatus] = [:]

    // Column IDs
    private enum ColumnID {
        static let permission = NSUserInterfaceItemIdentifier("PermissionColumn")
        static let status = NSUserInterfaceItemIdentifier("StatusColumn")
        static let action = NSUserInterfaceItemIdentifier("ActionColumn")
    }

    override func loadView() {
        self.view = NSView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        setupUI()
        refreshStatuses()
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
        NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        refreshStatuses()
    }

    private func setupUI() {
        // Configure table columns
        let permissionColumn = NSTableColumn(identifier: ColumnID.permission)
        permissionColumn.title = NSLocalizedString(
            "column.permission", value: "Permission", comment: "Table column header for permission name")
        permissionColumn.width = 150
        tableView.addTableColumn(permissionColumn)

        let statusColumn = NSTableColumn(identifier: ColumnID.status)
        statusColumn.title = NSLocalizedString(
            "column.status", value: "Status", comment: "Table column header for permission status")
        statusColumn.width = 100
        tableView.addTableColumn(statusColumn)

        let actionColumn = NSTableColumn(identifier: ColumnID.action)
        actionColumn.title = NSLocalizedString(
            "column.action", value: "Action", comment: "Table column header for permission action")
        actionColumn.width = 150
        tableView.addTableColumn(actionColumn)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        tableView.selectionHighlightStyle = .regular

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        view.addSubview(scrollView)

        // Setup detail panel
        setupDetailPanel()

        // Layout constraints
        NSLayoutConstraint.activate([
            // Table view at top
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 120),

            // Detail panel below table, pinned to bottom
            detailPanel.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 20),
            detailPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            detailPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            detailPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }

    private func setupDetailPanel() {
        detailPanel.translatesAutoresizingMaskIntoConstraints = false
        detailPanel.wantsLayer = true
        detailPanel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        detailPanel.layer?.cornerRadius = 6
        detailPanel.layer?.borderWidth = 1
        detailPanel.layer?.borderColor = NSColor.separatorColor.cgColor
        view.addSubview(detailPanel)

        // Title label (e.g., "Accessibility")
        detailTitleLabel.isEditable = false
        detailTitleLabel.isSelectable = true
        detailTitleLabel.isBordered = false
        detailTitleLabel.drawsBackground = false
        detailTitleLabel.font = .boldSystemFont(ofSize: 16)
        detailTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailPanel.addSubview(detailTitleLabel)

        // Description label (e.g., "VOCR needs Accessibility access to:")
        detailDescriptionLabel.isEditable = false
        detailDescriptionLabel.isSelectable = true
        detailDescriptionLabel.isBordered = false
        detailDescriptionLabel.drawsBackground = false
        detailDescriptionLabel.font = .systemFont(ofSize: 12)
        detailDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        detailPanel.addSubview(detailDescriptionLabel)

        // Features list
        detailFeaturesLabel.isEditable = false
        detailFeaturesLabel.isSelectable = true
        detailFeaturesLabel.isBordered = false
        detailFeaturesLabel.drawsBackground = false
        detailFeaturesLabel.font = .systemFont(ofSize: 11)
        detailFeaturesLabel.maximumNumberOfLines = 0
        detailFeaturesLabel.translatesAutoresizingMaskIntoConstraints = false
        detailPanel.addSubview(detailFeaturesLabel)

        // Requirement text (required vs optional)
        detailRequirementLabel.isEditable = false
        detailRequirementLabel.isSelectable = true
        detailRequirementLabel.isBordered = false
        detailRequirementLabel.drawsBackground = false
        detailRequirementLabel.font = .systemFont(ofSize: 11)
        detailRequirementLabel.textColor = .secondaryLabelColor
        detailRequirementLabel.maximumNumberOfLines = 0
        detailRequirementLabel.translatesAutoresizingMaskIntoConstraints = false
        detailPanel.addSubview(detailRequirementLabel)

        NSLayoutConstraint.activate([
            detailTitleLabel.topAnchor.constraint(equalTo: detailPanel.topAnchor, constant: 12),
            detailTitleLabel.leadingAnchor.constraint(equalTo: detailPanel.leadingAnchor, constant: 12),
            detailTitleLabel.trailingAnchor.constraint(equalTo: detailPanel.trailingAnchor, constant: -12),

            detailDescriptionLabel.topAnchor.constraint(equalTo: detailTitleLabel.bottomAnchor, constant: 8),
            detailDescriptionLabel.leadingAnchor.constraint(equalTo: detailPanel.leadingAnchor, constant: 12),
            detailDescriptionLabel.trailingAnchor.constraint(equalTo: detailPanel.trailingAnchor, constant: -12),

            detailFeaturesLabel.topAnchor.constraint(equalTo: detailDescriptionLabel.bottomAnchor, constant: 8),
            detailFeaturesLabel.leadingAnchor.constraint(equalTo: detailPanel.leadingAnchor, constant: 12),
            detailFeaturesLabel.trailingAnchor.constraint(equalTo: detailPanel.trailingAnchor, constant: -12),

            detailRequirementLabel.topAnchor.constraint(equalTo: detailFeaturesLabel.bottomAnchor, constant: 12),
            detailRequirementLabel.leadingAnchor.constraint(equalTo: detailPanel.leadingAnchor, constant: 12),
            detailRequirementLabel.trailingAnchor.constraint(equalTo: detailPanel.trailingAnchor, constant: -12),
            detailRequirementLabel.bottomAnchor.constraint(lessThanOrEqualTo: detailPanel.bottomAnchor, constant: -12),
        ])
    }


    private func refreshStatuses() {
        statuses = PermissionsManager.shared.checkAllStatuses()

        // For notifications, we need to check asynchronously
        PermissionsManager.shared.checkNotificationStatus { [weak self] status in
            self?.statuses[.notifications] = status
            self?.tableView.reloadData()

            // Update detail panel if notifications is selected
            if let selectedRow = self?.tableView.selectedRow,
               selectedRow >= 0,
               selectedRow < (self?.permissions.count ?? 0),
               self?.permissions[selectedRow] == .notifications
            {
                self?.updateDetailPanel(for: .notifications)
            }
        }

        tableView.reloadData()

        // Select first row if nothing is selected
        if tableView.selectedRow < 0 && !permissions.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            updateDetailPanel(for: permissions[0])
        }
    }

    private func updateDetailPanel(for permission: PermissionsManager.Permission) {
        detailTitleLabel.stringValue = permission.displayName
        detailDescriptionLabel.stringValue = permission.description

        let features = permission.featuresList.map { " • \($0)" }.joined(separator: "\n")
        detailFeaturesLabel.stringValue = features

        detailRequirementLabel.stringValue = permission.requirementText
    }

    private func actionButtonTitle(for permission: PermissionsManager.Permission) -> String {
        let status = statuses[permission] ?? .notDetermined

        switch (permission, status) {
        case (.accessibility, .granted):
            return NSLocalizedString(
                "button.permission.granted", value: "✓ Granted", comment: "Button text when permission is granted")
        case (.accessibility, _):
            return NSLocalizedString(
                "button.permission.opensystemprefs", value: "Open System Settings",
                comment: "Button text to open system settings")

        case (.screenRecording, .granted):
            return NSLocalizedString(
                "button.permission.granted", value: "✓ Granted", comment: "Button text when permission is granted")
        case (.screenRecording, _):
            return NSLocalizedString(
                "button.permission.opensystemprefs", value: "Open System Settings",
                comment: "Button text to open system settings")

        case (.notifications, .granted):
            return NSLocalizedString(
                "button.permission.granted", value: "✓ Granted", comment: "Button text when permission is granted")
        case (.notifications, .notDetermined):
            return NSLocalizedString(
                "button.permission.enable", value: "Enable", comment: "Button text to enable permission")
        case (.notifications, _):
            return NSLocalizedString(
                "button.permission.opensystemprefs", value: "Open System Settings",
                comment: "Button text to open system settings")

        case (.voiceOver, .granted):
            return NSLocalizedString(
                "button.permission.granted", value: "✓ Granted", comment: "Button text when permission is granted")
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
            cellView.stringValue = permission.displayName
            return cellView

        case ColumnID.status:
            let cellView = NSTextField()
            cellView.isEditable = false
            cellView.isSelectable = false
            cellView.isBordered = false
            cellView.drawsBackground = false
            cellView.stringValue = status.displayText
            return cellView

        case ColumnID.action:
            let button = NSButton(title: actionButtonTitle(for: permission), target: self, action: #selector(handleActionButton(_:)))
            button.bezelStyle = .rounded
            button.isEnabled = (status != .granted && status != .restricted)
            return button

        default:
            return nil
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0 && row < permissions.count else { return }

        let permission = permissions[row]
        updateDetailPanel(for: permission)
    }
}
