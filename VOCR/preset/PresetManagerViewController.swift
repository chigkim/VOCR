import Cocoa

final class PresetManagerViewController: NSViewController {

    // UI
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()

    private let addButton = NSButton(title: "Add", target: nil, action: nil)
    private let editButton = NSButton(title: "Edit", target: nil, action: nil)
    private let deleteButton = NSButton(title: "Delete", target: nil, action: nil)

    // Keep strong ref while sheet is visible
    private var editorWC: PresetEditorWindowController?
    private enum ColumnID {
        static let name  = NSUserInterfaceItemIdentifier("NameColumn")
        static let model = NSUserInterfaceItemIdentifier("ModelColumn")
    }

    override func loadView() {
        self.view = NSView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        setupUI()
        reloadUI()
    }

    private func setupUI() {
        // Table / column
        let presetColumn = NSTableColumn(identifier: ColumnID.name)
        presetColumn.title = "Name"
        tableView.addTableColumn(presetColumn)
        let modelColumn = NSTableColumn(identifier: ColumnID.model)
        modelColumn.title = "Model"
        tableView.addTableColumn(modelColumn)

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

        let buttonsStack = NSStackView(views: [addButton, editButton, deleteButton])
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
        if tableView.selectedRow < 0 && PresetManager.shared.presets.count > 0 {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            if let first = PresetManager.shared.presets.first {
                PresetManager.shared.selectPreset(id: first.id)
            }
        }

        let row = tableView.selectedRow
        let valid = row >= 0 && row < PresetManager.shared.presets.count

        editButton.isEnabled = valid
        deleteButton.isEnabled = valid
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.makeFirstResponder(tableView)
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

// MARK: - NSTableViewDelegate
extension PresetManagerViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return PresetManager.shared.presets.count
    }

    // Cell-based table: return strings for each column
    func tableView(_ tableView: NSTableView,
                   objectValueFor tableColumn: NSTableColumn?,
                   row: Int) -> Any? {
        let preset = PresetManager.shared.presets[row]
        guard let colID = tableColumn?.identifier else {
            return nil
        }

        switch colID {
        case ColumnID.name:
            return preset.name

        case ColumnID.model:
            return preset.model

        default:
            return nil
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let idx = tableView.selectedRow
        guard idx >= 0 && idx < PresetManager.shared.presets.count else {
            reloadUI()
            return
        }

        let preset = PresetManager.shared.presets[idx]
        PresetManager.shared.selectPreset(id: preset.id)
        reloadUI()
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
