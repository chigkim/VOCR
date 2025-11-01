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
	private let urlField = NSTextField()
	private let modelField = NSTextField()
	private let apiKeyField = NSSecureTextField()

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

		if #available(macOS 10.12, *), let layoutGuide = window.contentLayoutGuide as? NSLayoutGuide {
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
		let urlLabel = makeLabel("URL:")
		let modelLabel = makeLabel("Model:")
		let apiKeyLabel = makeLabel("API Key:")
		let systemPromptLabel = makeLabel("System Prompt:")
		let promptLabel = makeLabel("User Prompt:")

		// Text fields
		[nameField, urlField, modelField, apiKeyField].forEach { tf in
			tf.translatesAutoresizingMaskIntoConstraints = false
		}

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
		let views: [NSView] = [
			nameLabel, nameField,
			urlLabel, urlField,
			modelLabel, modelField,
			apiKeyLabel, apiKeyField,
			systemPromptLabel, systemPromptScrollView,
			promptLabel, promptScrollView,
			cancelButton, saveButton,
		]
		views.forEach { contentViewContainer.addSubview($0) }

		// Layout
		// We'll lay these out vertically with some padding.
		let pad: CGFloat = 8
		let labelWidth: CGFloat = 110

		NSLayoutConstraint.activate([
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

			// Row: URL
			urlLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
			urlLabel.topAnchor.constraint(
				equalTo: nameLabel.bottomAnchor,
				constant: pad
			),
			urlLabel.widthAnchor.constraint(equalToConstant: labelWidth),

			urlField.leadingAnchor.constraint(
				equalTo: urlLabel.trailingAnchor,
				constant: 8
			),
			urlField.trailingAnchor.constraint(
				equalTo: nameField.trailingAnchor
			),
			urlField.centerYAnchor.constraint(equalTo: urlLabel.centerYAnchor),

			// Row: Model
			modelLabel.leadingAnchor.constraint(
				equalTo: nameLabel.leadingAnchor
			),
			modelLabel.topAnchor.constraint(
				equalTo: urlLabel.bottomAnchor,
				constant: pad
			),
			modelLabel.widthAnchor.constraint(equalToConstant: labelWidth),

			modelField.leadingAnchor.constraint(
				equalTo: modelLabel.trailingAnchor,
				constant: 8
			),
			modelField.trailingAnchor.constraint(
				equalTo: nameField.trailingAnchor
			),
			modelField.centerYAnchor.constraint(
				equalTo: modelLabel.centerYAnchor
			),

			// Row: API Key
			apiKeyLabel.leadingAnchor.constraint(
				equalTo: nameLabel.leadingAnchor
			),
			apiKeyLabel.topAnchor.constraint(
				equalTo: modelLabel.bottomAnchor,
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

			// Row: System Prompt
			systemPromptLabel.leadingAnchor.constraint(
				equalTo: nameLabel.leadingAnchor
			),
			systemPromptLabel.topAnchor.constraint(
				equalTo: apiKeyLabel.bottomAnchor,
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

		// For security, we DO NOT auto-fill decrypted API key here.
		apiKeyField.stringValue = ""
	}

	// MARK: - Actions

	@objc private func cancelPressed() {
		delegate?.presetEditorDidCancel(self)
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
}

