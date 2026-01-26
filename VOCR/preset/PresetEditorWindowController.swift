import Cocoa

protocol PresetEditorWindowControllerDelegate: AnyObject {
    func presetEditorDidFinish(_ controller: PresetEditorWindowController)
    func presetEditorDidCancel(_ controller: PresetEditorWindowController)
}

/// Modal sheet for creating or editing a preset.
final class PresetEditorWindowController: NSWindowController {

    weak var delegate: PresetEditorWindowControllerDelegate?

    /// nil => new preset
    /// non-nil => editing existing preset with that UUID
    private var editingPresetID: UUID?

    // MARK: UI elements

    private let contentViewContainer = NSView()

    private let nameField = NSTextField()
    private let providerPopUpButton = NSPopUpButton(frame: .zero)
    private let urlField = NSTextField()
    private let apiKeyField = NSTextField()
    private let modelField = NSTextField()
    private let modelPickerPopUpButton = NSPopUpButton(frame: .zero)

    private let systemPromptTextView = NSTextView()
    private let promptTextView = NSTextView()

    private let systemPromptScrollView = NSScrollView()
    private let promptScrollView = NSScrollView()

    private let cancelButton = NSButton(
        title: "Cancel",
        target: nil,
        action: nil
    )
    private let saveButton = NSButton(title: "Save", target: nil, action: nil)

    // MARK: - Init

    init(editPresetID: UUID?) {
        self.editingPresetID = editPresetID

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        if editPresetID == nil {
            win.title = "New Preset"
        } else {
            win.title = "Edit Preset"
        }

        super.init(window: win)

        setupUI()
        populateFieldsFromExistingPreset()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - UI Setup

    private func makeLabel(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.alignment = .right
        return l
    }

    private func setupScrollTextView(
        _ textView: NSTextView,
        scrollView: NSScrollView,
        minHeight: CGFloat
    ) {
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 4, height: 4)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        scrollView.heightAnchor.constraint(equalToConstant: minHeight)
            .isActive = true
    }

    private func setupUI() {
        guard let window = self.window else { return }

        window.contentView = contentViewContainer
        contentViewContainer.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 10.12, *), let layoutGuide = window.contentLayoutGuide as? NSLayoutGuide
        {
            NSLayoutConstraint.activate([
                contentViewContainer.leadingAnchor.constraint(
                    equalTo: layoutGuide.leadingAnchor
                ),
                contentViewContainer.trailingAnchor.constraint(
                    equalTo: layoutGuide.trailingAnchor
                ),
                contentViewContainer.topAnchor.constraint(
                    equalTo: layoutGuide.topAnchor
                ),
                contentViewContainer.bottomAnchor.constraint(
                    equalTo: layoutGuide.bottomAnchor
                ),
            ])
        } else {
            guard let contentView = window.contentView else { return }
            NSLayoutConstraint.activate([
                contentViewContainer.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                contentViewContainer.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                contentViewContainer.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                contentViewContainer.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                ),
            ])
        }

        // Labels
        let nameLabel = makeLabel("Name:")
        let apiKeyLabel = makeLabel("API Key:")
        let systemPromptLabel = makeLabel("System Prompt:")
        let promptLabel = makeLabel("User Prompt:")

        // Text fields
        [nameField, urlField, modelField, apiKeyField].forEach { tf in
            tf.translatesAutoresizingMaskIntoConstraints = false
        }
        nameField.setAccessibilityLabel("Name")
        urlField.placeholderString = "https://"
        urlField.setAccessibilityLabel("Provider URL")
        apiKeyField.setAccessibilityLabel("API Key")
        modelField.setAccessibilityLabel("Model Name")
        systemPromptTextView.setAccessibilityLabel("System Prompt")
        promptTextView.setAccessibilityLabel("User Prompt")

        // Configure provider pop up button (only for new presets)
        providerPopUpButton.translatesAutoresizingMaskIntoConstraints = false
        providerPopUpButton.title = "Provider"
        providerPopUpButton.removeAllItems()
        providerPopUpButton.addItem(withTitle: "Provider")
        providerPopUpButton.item(at: 0)?.isHidden = true
        providerPopUpButton.addItems(withTitles: ModelProvider.predefinedProviders.map { $0.name })
        providerPopUpButton.target = self
        providerPopUpButton.action = #selector(providerDidChange)
        providerPopUpButton.menu?.delegate = self
        providerPopUpButton.selectItem(at: 0)
        providerPopUpButton.title = "Provider"

        // Configure model picker pop up button
        modelPickerPopUpButton.translatesAutoresizingMaskIntoConstraints = false
        modelPickerPopUpButton.title = "Model"
        let modelMenu = NSMenu()
        modelMenu.delegate = self
        modelPickerPopUpButton.menu = modelMenu
        modelMenu.addItem(withTitle: "Model", action: nil, keyEquivalent: "")
        modelMenu.item(at: 0)?.isHidden = true
        modelPickerPopUpButton.selectItem(at: 0)

        // Configure URL field delegate to detect manual changes
        urlField.delegate = self

        // Scroll text views
        setupScrollTextView(
            systemPromptTextView,
            scrollView: systemPromptScrollView,
            minHeight: 100
        )
        setupScrollTextView(
            promptTextView,
            scrollView: promptScrollView,
            minHeight: 100
        )

        // Buttons
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.target = self
        cancelButton.action = #selector(cancelPressed)
        saveButton.target = self
        saveButton.action = #selector(savePressed)

        // Add subviews
        var views: [NSView] = [
            nameLabel, nameField,
        ]

        // Only add provider pop up button for new presets
        views.append(providerPopUpButton)

        views.append(contentsOf: [
            urlField,
            apiKeyLabel, apiKeyField,
            modelPickerPopUpButton, modelField,
            systemPromptLabel, systemPromptScrollView,
            promptLabel, promptScrollView,
            cancelButton, saveButton,
        ])

        views.forEach { contentViewContainer.addSubview($0) }

        // Layout
        let pad: CGFloat = 8
        let labelWidth: CGFloat = 110

        var constraints: [NSLayoutConstraint] = [
            // Row: Name
            nameLabel.leadingAnchor.constraint(
                equalTo: contentViewContainer.leadingAnchor,
                constant: 20
            ),
            nameLabel.topAnchor.constraint(
                equalTo: contentViewContainer.topAnchor,
                constant: 20
            ),
            nameLabel.widthAnchor.constraint(equalToConstant: labelWidth),

            nameField.leadingAnchor.constraint(
                equalTo: nameLabel.trailingAnchor,
                constant: 8
            ),
            nameField.trailingAnchor.constraint(
                equalTo: contentViewContainer.trailingAnchor,
                constant: -20
            ),
            nameField.centerYAnchor.constraint(
                equalTo: nameLabel.centerYAnchor
            ),
        ]

        // Row: Model Provider (only for new presets)
        let urlTopAnchor: NSLayoutYAxisAnchor
        constraints.append(contentsOf: [
            providerPopUpButton.leadingAnchor.constraint(
                equalTo: nameField.leadingAnchor
            ),
            providerPopUpButton.topAnchor.constraint(
                equalTo: nameField.bottomAnchor,
                constant: pad
            ),
            providerPopUpButton.trailingAnchor.constraint(
                equalTo: nameField.trailingAnchor
            ),
        ])
        urlTopAnchor = providerPopUpButton.bottomAnchor

        constraints.append(contentsOf: [
            // Row: URL
            urlField.leadingAnchor.constraint(
                equalTo: nameField.leadingAnchor
            ),
            urlField.trailingAnchor.constraint(
                equalTo: nameField.trailingAnchor
            ),
            urlField.topAnchor.constraint(
                equalTo: urlTopAnchor,
                constant: pad
            ),

            // Row: API Key
            apiKeyLabel.leadingAnchor.constraint(
                equalTo: nameLabel.leadingAnchor
            ),
            apiKeyLabel.topAnchor.constraint(
                equalTo: urlField.bottomAnchor,
                constant: pad
            ),
            apiKeyLabel.widthAnchor.constraint(equalToConstant: labelWidth),

            apiKeyField.leadingAnchor.constraint(
                equalTo: apiKeyLabel.trailingAnchor,
                constant: 8
            ),
            apiKeyField.trailingAnchor.constraint(
                equalTo: nameField.trailingAnchor
            ),
            apiKeyField.centerYAnchor.constraint(
                equalTo: apiKeyLabel.centerYAnchor
            ),

            // Row: Model
            modelPickerPopUpButton.leadingAnchor.constraint(
                equalTo: nameField.leadingAnchor
            ),
            modelPickerPopUpButton.topAnchor.constraint(
                equalTo: apiKeyField.bottomAnchor,
                constant: pad
            ),

            modelField.leadingAnchor.constraint(
                equalTo: modelPickerPopUpButton.trailingAnchor,
                constant: 8
            ),
            modelField.trailingAnchor.constraint(
                equalTo: nameField.trailingAnchor
            ),
            modelField.centerYAnchor.constraint(
                equalTo: modelPickerPopUpButton.centerYAnchor
            ),

            // Row: System Prompt
            systemPromptLabel.leadingAnchor.constraint(
                equalTo: nameLabel.leadingAnchor
            ),
            systemPromptLabel.topAnchor.constraint(
                equalTo: modelPickerPopUpButton.bottomAnchor,
                constant: pad
            ),
            systemPromptLabel.widthAnchor.constraint(
                equalToConstant: labelWidth
            ),

            systemPromptScrollView.leadingAnchor.constraint(
                equalTo: systemPromptLabel.trailingAnchor,
                constant: 8
            ),
            systemPromptScrollView.trailingAnchor.constraint(
                equalTo: nameField.trailingAnchor
            ),
            systemPromptScrollView.topAnchor.constraint(
                equalTo: systemPromptLabel.topAnchor
            ),

            // Row: User Prompt
            promptLabel.leadingAnchor.constraint(
                equalTo: nameLabel.leadingAnchor
            ),
            promptLabel.topAnchor.constraint(
                equalTo: systemPromptScrollView.bottomAnchor,
                constant: pad
            ),
            promptLabel.widthAnchor.constraint(equalToConstant: labelWidth),

            promptScrollView.leadingAnchor.constraint(
                equalTo: promptLabel.trailingAnchor,
                constant: 8
            ),
            promptScrollView.trailingAnchor.constraint(
                equalTo: nameField.trailingAnchor
            ),
            promptScrollView.topAnchor.constraint(
                equalTo: promptLabel.topAnchor
            ),

            // Buttons
            cancelButton.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentViewContainer.leadingAnchor,
                constant: 20
            ),
            cancelButton.bottomAnchor.constraint(
                equalTo: contentViewContainer.bottomAnchor,
                constant: -20
            ),

            saveButton.trailingAnchor.constraint(
                equalTo: contentViewContainer.trailingAnchor,
                constant: -20
            ),
            saveButton.bottomAnchor.constraint(
                equalTo: contentViewContainer.bottomAnchor,
                constant: -20
            ),

            cancelButton.trailingAnchor.constraint(
                equalTo: saveButton.leadingAnchor,
                constant: -12
            ),
            cancelButton.centerYAnchor.constraint(
                equalTo: saveButton.centerYAnchor
            ),
        ])

        NSLayoutConstraint.activate(constraints)
    }

    private func populateFieldsFromExistingPreset() {
        guard let editingID = editingPresetID else { return }

        guard
            let preset = PresetManager.shared.presets.first(where: {
                $0.id == editingID
            })
        else {
            return
        }

        nameField.stringValue = preset.name
        urlField.stringValue = preset.url
        modelField.stringValue = preset.model
        systemPromptTextView.string = preset.systemPrompt
        promptTextView.string = preset.prompt
        apiKeyField.stringValue = ""
        apiKeyField.placeholderString = "Will Not be shown After saving."
    }

    // MARK: - Actions

    @objc private func cancelPressed() {
        delegate?.presetEditorDidCancel(self)
    }

    @objc private func providerDidChange(_ sender: NSPopUpButton) {
        let selectedIndex = sender.indexOfSelectedItem
        let providerIndex = selectedIndex - 1
        guard providerIndex >= 0 && providerIndex < ModelProvider.predefinedProviders.count else {
            return
        }

        let selectedProvider = ModelProvider.predefinedProviders[providerIndex]

        // Populate the URL field
        urlField.stringValue = selectedProvider.apiURL

        // Reset the button's selection to the title item
        sender.selectItem(at: 0)
        sender.title = "Provider"
    }

    @objc private func savePressed() {
        let name = nameField.stringValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let url = urlField.stringValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let model = modelField.stringValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let systemPrompt = systemPromptTextView.string
        let prompt = promptTextView.string
        let apiKeyCandidate = apiKeyField.stringValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        do {
            if let editingID = editingPresetID {
                // Update existing preset.
                // Only rotate API key if user actually typed a new one.
                let newKeyOrNil =
                    apiKeyCandidate.isEmpty ? nil : apiKeyCandidate

                try PresetManager.shared.updatePreset(
                    id: editingID,
                    name: name,
                    url: url,
                    model: model,
                    systemPrompt: systemPrompt,
                    prompt: prompt,
                    apiKeyPlaintext: newKeyOrNil
                )
            } else {
                // New preset. Require an API key.
                try PresetManager.shared.addPreset(
                    name: name,
                    url: url,
                    model: model,
                    systemPrompt: systemPrompt,
                    prompt: prompt,
                    apiKeyPlaintext: apiKeyCandidate
                )
            }

            delegate?.presetEditorDidFinish(self)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Failed to save preset."
            alert.informativeText = "\(error)"
            alert.runModal()
        }
    }

    // MARK: - Model picker logic

    /// Build an NSMenu of models and pop it anchored to the Choose… button.
    private func showModelMenu(_ modelIDs: [String]) {
        guard let menu = modelPickerPopUpButton.menu else { return }
        menu.removeAllItems()

        modelPickerPopUpButton.title = "Model"
        menu.addItem(withTitle: "Model", action: nil, keyEquivalent: "")
        menu.item(at: 0)?.isHidden = true

        guard !modelIDs.isEmpty else {
            menu.addItem(withTitle: "No models found", action: nil, keyEquivalent: "")
            return
        }

        for id in modelIDs {
            let item = NSMenuItem(
                title: id,
                action: #selector(modelPicked(_:)),
                keyEquivalent: ""
            )
            item.target = self
            menu.addItem(item)
        }

        let currentModel = modelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !currentModel.isEmpty,
            let matchingItem = menu.items.first(where: { $0.title == currentModel })
        {
            modelPickerPopUpButton.select(matchingItem)
        } else {
            modelPickerPopUpButton.selectItem(at: 0)
        }
    }

    private func showModelLoadingMenu() {
        guard let menu = modelPickerPopUpButton.menu else { return }
        menu.removeAllItems()
        modelPickerPopUpButton.title = "Model"
        menu.addItem(withTitle: "Model", action: nil, keyEquivalent: "")
        menu.item(at: 0)?.isHidden = true
        let loadingItem = NSMenuItem(title: "Loading…", action: nil, keyEquivalent: "")
        loadingItem.isEnabled = false
        menu.addItem(loadingItem)
        modelPickerPopUpButton.selectItem(at: 0)
    }

    /// Called when user picks a model from the popup menu.
    @objc private func modelPicked(_ sender: NSMenuItem?) {
        guard let sender = sender else {
            return
        }
        if sender.title == "Model" {
            return
        }
        modelField.stringValue = sender.title
        modelPickerPopUpButton.selectItem(at: 0)
        modelPickerPopUpButton.title = "Model"
    }
}

// MARK: - NSMenuDelegate
extension PresetEditorWindowController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if menu == modelPickerPopUpButton.menu {
            showModelLoadingMenu()
            OpenAIAPI.getModels(urlField.stringValue, apiKeyField.stringValue) { [weak self] ids in
                DispatchQueue.main.async {
                    self?.showModelMenu(ids)
                }
            }
        } else if menu == providerPopUpButton.menu {
            let currentURL = urlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let index = ModelProvider.predefinedProviders.firstIndex(where: {
                $0.apiURL == currentURL
            }
            ) {
                providerPopUpButton.selectItem(at: index + 1)
            } else {
                providerPopUpButton.selectItem(at: 0)
            }
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        if menu == modelPickerPopUpButton.menu {
            modelPickerPopUpButton.selectItem(at: 0)
            modelPickerPopUpButton.title = "Model"
        } else if menu == providerPopUpButton.menu {
            providerPopUpButton.selectItem(at: 0)
            providerPopUpButton.title = "Provider"
        }
    }
}

// MARK: - NSTextFieldDelegate
extension PresetEditorWindowController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }

        // Only handle URL field changes
        guard textField == urlField else { return }

        // Clear provider selection when URL is manually edited
        providerPopUpButton.selectItem(at: 0)
        providerPopUpButton.title = "Provider"
    }
}
