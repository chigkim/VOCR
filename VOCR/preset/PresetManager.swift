import Foundation

/// Singleton backing store for presets.
/// - Persists presets to UserDefaults (without plaintext API keys).
/// - Persists which preset is currently selected.
/// - Decrypts API key only when you request it.
final class PresetManager {
    static let shared = PresetManager()

    private let presetsDefaultsKey = "VOCR.presets.v1"
    private let selectedIDDefaultsKey = "VOCR.selectedPresetID.v1"

    private(set) var presets: [Preset] = []
    private(set) var selectedPresetID: UUID?

    private init() {
        loadFromDisk()
    }

    // MARK: - Persistence

    private func makeDefaultPresets() {
        do {
            try addPreset(
                name: "Default", url: "https://api.openai.com/v1", model: "gpt-5.2",
                systemPrompt: DefaultPrompts.system,
                prompt: DefaultPrompts.user,
                apiKeyPlaintext: "your-api-key")
            if let lastID = presets.last?.id {
                selectPreset(id: lastID)
            }
        } catch {
            // If creating default presets fails (e.g., encryption error), start with empty presets.
            self.presets = []
        }
    }

    private func loadFromDisk() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: presetsDefaultsKey),
            let decoded = try? JSONDecoder().decode([Preset].self, from: data)
        {
            self.presets = decoded
        } else {
            makeDefaultPresets()
        }

        if let idString = defaults.string(forKey: selectedIDDefaultsKey),
            let id = UUID(uuidString: idString)
        {
            self.selectedPresetID = id
        }
    }

    private func saveToDisk() {
        let defaults = UserDefaults.standard

        if let data = try? JSONEncoder().encode(presets) {
            defaults.set(data, forKey: presetsDefaultsKey)
        }

        if let sel = selectedPresetID {
            defaults.set(sel.uuidString, forKey: selectedIDDefaultsKey)
        } else {
            defaults.removeObject(forKey: selectedIDDefaultsKey)
        }
    }

    // MARK: - CRUD

    func addPreset(
        name: String,
        url: String,
        model: String,
        systemPrompt: String,
        prompt: String,
        apiKeyPlaintext: String
    ) throws {

        let encryptedKey = try SecureCrypto.encryptAPIKey(apiKeyPlaintext)

        let newPreset = Preset(
            id: UUID(),
            name: name,
            url: url,
            model: model,
            systemPrompt: systemPrompt,
            prompt: prompt,
            encryptedKeyCombinedBase64: encryptedKey
        )

        presets.append(newPreset)
        saveToDisk()
    }

    func updatePreset(
        id: UUID,
        name: String,
        url: String,
        model: String,
        systemPrompt: String,
        prompt: String,
        apiKeyPlaintext: String?
    ) throws {

        guard let idx = presets.firstIndex(where: { $0.id == id }) else {
            return
        }

        var updated = presets[idx]
        updated.name = name
        updated.url = url
        updated.model = model
        updated.systemPrompt = systemPrompt
        updated.prompt = prompt

        // Only rotate the key if caller provided a new plaintext
        if let rawKey = apiKeyPlaintext, !rawKey.isEmpty {
            let encryptedKey = try SecureCrypto.encryptAPIKey(rawKey)
            updated.encryptedKeyCombinedBase64 = encryptedKey
        }

        presets[idx] = updated
        saveToDisk()
    }

    func removePreset(id: UUID) {
        if selectedPresetID == id {
            selectedPresetID = nil
        }

        presets.removeAll { $0.id == id }
        saveToDisk()
    }

    // MARK: - Selection
    /// Clone an existing preset (including encrypted key) under a new UUID and " Copy" name.
    /// Returns the new preset's ID, or nil if original not found.
    func duplicatePreset(originalID: UUID) -> UUID? {
        guard let src = presets.first(where: { $0.id == originalID }) else {
            return nil
        }

        let newPreset = Preset(
            id: UUID(),
            name: src.name + " Copy",
            url: src.url,
            model: src.model,
            systemPrompt: src.systemPrompt,
            prompt: src.prompt,
            encryptedKeyCombinedBase64: src.encryptedKeyCombinedBase64
        )

        presets.append(newPreset)

        // make the duplicate the selected preset in memory
        selectedPresetID = newPreset.id

        saveToDisk()
        return newPreset.id
    }

    func selectPreset(id: UUID) {
        guard presets.contains(where: { $0.id == id }) else { return }
        selectedPresetID = id
        saveToDisk()
    }

    // MARK: - Access / Integration point

    /// Call this right before you send a request to a model.
    /// Returns the currently selected preset, including a decrypted API key.
    func activePresetDecrypted() -> (
        id: UUID,
        name: String,
        url: String,
        model: String,
        systemPrompt: String,
        prompt: String,
        apiKey: String
    )? {
        if let preset =
            (selectedPresetID.flatMap { sel in presets.first(where: { $0.id == sel }) }
                ?? presets.first(where: { $0.name == "Default" }))
        {
            do {
                let apiKey = try SecureCrypto.decryptAPIKey(preset.encryptedKeyCombinedBase64)
                return (
                    id: preset.id,
                    name: preset.name,
                    url: preset.url,
                    model: preset.model,
                    systemPrompt: preset.systemPrompt,
                    prompt: preset.prompt,
                    apiKey: apiKey
                )
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }

    /// For populating UI lists.
    func listPresetSummaries() -> [(id: UUID, label: String)] {
        presets.map { ($0.id, $0.name) }
    }
}
