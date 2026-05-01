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

    private func presetSummary(_ preset: Preset) -> String {
        let host = URL(string: preset.url)?.host ?? preset.url
        return "\(preset.name) id=\(preset.id.uuidString) model=\(preset.model) host=\(host)"
    }

    private func makeDefaultPresets() {
        log("PresetManager: creating default preset")
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
            log("PresetManager: failed to create default preset: \(error)")
            self.presets = []
        }
    }

    private func loadFromDisk() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: presetsDefaultsKey) {
            do {
                let decoded = try JSONDecoder().decode([Preset].self, from: data)
                self.presets = decoded
                log("PresetManager: loaded \(decoded.count) presets from defaults")
                for preset in decoded {
                    log("PresetManager: loaded preset \(presetSummary(preset))")
                }
            } catch {
                log("PresetManager: failed to decode presets from defaults: \(error)")
                makeDefaultPresets()
            }
        } else {
            log("PresetManager: no presets found in defaults")
            makeDefaultPresets()
        }

        if let idString = defaults.string(forKey: selectedIDDefaultsKey),
            let id = UUID(uuidString: idString)
        {
            self.selectedPresetID = id
            log("PresetManager: loaded selected preset id \(id.uuidString)")
        } else if let idString = defaults.string(forKey: selectedIDDefaultsKey) {
            log("PresetManager: ignored invalid selected preset id \(idString)")
        } else {
            log("PresetManager: no selected preset id in defaults")
        }
    }

    private func saveToDisk() {
        let defaults = UserDefaults.standard

        if let data = try? JSONEncoder().encode(presets) {
            defaults.set(data, forKey: presetsDefaultsKey)
            log("PresetManager: saved \(presets.count) presets to defaults")
        } else {
            log("PresetManager: failed to encode presets for saving")
        }

        if let sel = selectedPresetID {
            defaults.set(sel.uuidString, forKey: selectedIDDefaultsKey)
            log("PresetManager: saved selected preset id \(sel.uuidString)")
        } else {
            defaults.removeObject(forKey: selectedIDDefaultsKey)
            log("PresetManager: cleared selected preset id")
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
        log("PresetManager: added preset \(presetSummary(newPreset))")
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
        log("PresetManager: updated preset \(presetSummary(updated)); keyRotated=\(apiKeyPlaintext?.isEmpty == false)")
        saveToDisk()
    }

    func removePreset(id: UUID) {
        if selectedPresetID == id {
            selectedPresetID = nil
        }

        presets.removeAll { $0.id == id }
        log("PresetManager: removed preset id \(id.uuidString)")
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

        log("PresetManager: duplicated preset \(originalID.uuidString) as \(presetSummary(newPreset))")
        saveToDisk()
        return newPreset.id
    }

    func selectPreset(id: UUID) {
        guard let preset = presets.first(where: { $0.id == id }) else {
            log("PresetManager: ignored selection for unknown preset id \(id.uuidString)")
            return
        }
        selectedPresetID = id
        log("PresetManager: selected preset \(presetSummary(preset))")
        saveToDisk()
    }

    // MARK: - Access / Integration point

    /// Call this right before you send a request to a model.
    /// Returns the currently selected preset, including a decrypted API key.
    func activePreset() -> ActivePreset? {
        let selectedPreset = selectedPresetID.flatMap { sel in
            presets.first(where: { $0.id == sel })
        }
        let defaultPreset = presets.first(where: { $0.name == "Default" })

        if selectedPreset == nil, let selectedPresetID {
            log("PresetManager: selected preset id \(selectedPresetID.uuidString) was not found")
        }

        guard let preset = selectedPreset ?? defaultPreset else {
            log("PresetManager: active preset unavailable; presets=\(presets.count), selected=\(selectedPresetID?.uuidString ?? "nil")")
            return nil
        }

        log("PresetManager: resolving active preset \(presetSummary(preset))")

        do {
            let apiKey = try SecureCrypto.decryptAPIKey(preset.encryptedKeyCombinedBase64)
            log("PresetManager: active preset key decrypted for \(preset.name) id=\(preset.id.uuidString)")
            return ActivePreset(
                id: preset.id,
                name: preset.name,
                url: preset.url,
                model: preset.model,
                systemPrompt: preset.systemPrompt,
                prompt: preset.prompt,
                apiKey: apiKey
            )
        } catch {
            log("PresetManager: failed to decrypt active preset key for \(presetSummary(preset)): \(error)")
            alertPresetKeyDecryptionFailure(presetName: preset.name)
            return nil
        }
    }

    private func alertPresetKeyDecryptionFailure(presetName: String) {
        let title = NSLocalizedString(
            "error.preset.decryptKey.title",
            value: "Cannot Decrypt API Key",
            comment: "Alert title when a preset API key cannot be decrypted")
        let message = String(
            format: NSLocalizedString(
                "error.preset.decryptKey.message",
                value:
                    "VOCR could not decrypt the API key for the \"%@\" preset. Please open Preset Manager, edit this preset, re-enter the API key, and save it.",
                comment: "Alert message when a preset API key cannot be decrypted"),
            presetName)
        alert(title, message)
    }

}
