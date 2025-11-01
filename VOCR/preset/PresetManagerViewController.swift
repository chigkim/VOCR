import Cocoa

final class PresetManagerViewController: NSViewController {

    // UI
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()

    private let addButton = NSButton(title: "Add", target: nil, action: nil)
    private let editButton = NSButton(title: "Edit", target: nil, action: nil)
    private let deleteButton = NSButton(title: "Delete", target: nil, action: nil)
    private let selectButton = NSButton(title: "Select", target: nil, action: nil)

    // Keep strong ref while sheet is visible
    private var editorWC: PresetEditorWindowController?

    override func loadView() {
        self.view = NSView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        setupUI()
        reloadUI()
    }

    private func setupUI() {
        // Table / column
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("PresetColumn"))
        column.title = "Presets"
        tableView.addTableColumn(column)

        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        view.addSubview(scrollView)

        let buttonsStack = NSStackView(views: [addButton, editButton, deleteButton, selectButton])
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        buttonsStack.orientation = .horizontal
        buttonsStack.spacing = 8
        view.addSubview(buttonsStack)

        addButton.target = self
        addButton.action = #selector(addPressed)

        editButton.target = self
        editButton.action = #selector(editPressed)

        deleteButton.target = self
        deleteButton.action = #selector(deletePressed)

        selectButton.target = self
        selectButton.action = #selector(selectPressed)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            buttonsStack.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            buttonsStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),

            scrollView.heightAnchor.constraint(equalToConstant: 260)
        ])
    }

    private func reloadUI() {
        tableView.reloadData()

        let row = tableView.selectedRow
        let valid = row >= 0 && row < PresetManager.shared.presets.count

        editButton.isEnabled = valid
        deleteButton.isEnabled = valid
        selectButton.isEnabled = valid
    }

    private func selectedIndex() -> Int? {
        let r = tableView.selectedRow
        guard r >= 0 && r < PresetManager.shared.presets.count else { return nil }
        return r
    }

    // MARK: - Button Actions

    @objc private func addPressed() {
        presentEditor(for: nil)
    }

    @objc private func editPressed() {
        guard let idx = selectedIndex() else { return }
        let preset = PresetManager.shared.presets[idx]
        presentEditor(for: preset.id)
    }

    @objc private func deletePressed() {
        guard let idx = selectedIndex() else { return }
        let preset = PresetManager.shared.presets[idx]

        PresetManager.shared.removePreset(id: preset.id)
        reloadUI()
    }

    @objc private func selectPressed() {
        guard let idx = selectedIndex() else { return }
        let preset = PresetManager.shared.presets[idx]

        PresetManager.shared.selectPreset(id: preset.id)
        reloadUI()
    }

    // MARK: - Editor presentation

    private func presentEditor(for presetID: UUID?) {
        let wc = PresetEditorWindowController(editPresetID: presetID)
        wc.delegate = self
        editorWC = wc

        guard let parentWindow = self.view.window,
              let sheetWindow = wc.window else {
            wc.showWindow(self)
            return
        }

        parentWindow.beginSheet(sheetWindow) { _ in
            // ended
        }
    }
}

// MARK: - NSTableViewDataSource

extension PresetManagerViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return PresetManager.shared.presets.count
    }
}

// MARK: - NSTableViewDelegate

extension PresetManagerViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        reloadUI()
    }

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {

        let reuseID = NSUserInterfaceItemIdentifier("PresetCell")

        let cell: NSTableCellView
        if let existing = tableView.makeView(withIdentifier: reuseID, owner: self) as? NSTableCellView {
            cell = existing
        } else {
            cell = NSTableCellView(frame: .zero)
            cell.identifier = reuseID

            let tf = NSTextField(labelWithString: "")
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.lineBreakMode = .byTruncatingTail
            cell.textField = tf
            cell.addSubview(tf)

            NSLayoutConstraint.activate([
                tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
                tf.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
                tf.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4),
            ])
        }

        let preset = PresetManager.shared.presets[row]
        let activeID = PresetManager.shared.selectedPresetID

        // We'll show name and model. Checkmark if it's the active preset.
        if activeID == preset.id {
            cell.textField?.stringValue = "✔︎ \(preset.name) (\(preset.model))"
        } else {
            cell.textField?.stringValue = "\(preset.name) (\(preset.model))"
        }

        return cell
    }
}

// MARK: - PresetEditorWindowControllerDelegate

extension PresetManagerViewController: PresetEditorWindowControllerDelegate {
    func presetEditorDidFinish(_ controller: PresetEditorWindowController) {
        if let w = controller.window,
           let parent = self.view.window {
            parent.endSheet(w)
        }
        editorWC = nil
        reloadUI()
    }

    func presetEditorDidCancel(_ controller: PresetEditorWindowController) {
        if let w = controller.window,
           let parent = self.view.window {
            parent.endSheet(w)
        }
        editorWC = nil
        reloadUI()
    }
}
