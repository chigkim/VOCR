import Foundation
import CryptoKit

enum SecureCrypto {
    /// Where we persist our master symmetric key in Keychain
    private static let masterKeyKeychainID = "com.chikim.VOCR.PresetMasterKey"

    /// Get the app-wide symmetric key. Create and store it in Keychain if missing.
    static func getOrCreateMasterKey() throws -> SymmetricKey {
        if let data = KeychainManager.retrieve(key: masterKeyKeychainID) {
            // existing key in Keychain
            return SymmetricKey(data: data)
        } else {
            // generate new 32-byte random key
            var keyData = Data(count: 32)
            let status = keyData.withUnsafeMutableBytes { ptr in
                SecRandomCopyBytes(kSecRandomDefault, 32, ptr.baseAddress!)
            }
            guard status == errSecSuccess else {
                throw NSError(
                    domain: "SecureCrypto",
                    code: Int(status),
                    userInfo: [NSLocalizedDescriptionKey: "Failed to generate random key"]
                )
            }

            let storeStatus = KeychainManager.store(key: masterKeyKeychainID, data: keyData)
            guard storeStatus == errSecSuccess else {
                throw NSError(
                    domain: "SecureCrypto",
                    code: Int(storeStatus),
                    userInfo: [NSLocalizedDescriptionKey: "Failed to store master key in Keychain"]
                )
            }

            return SymmetricKey(data: keyData)
        }
    }

    /// Encrypt a plaintext API key string.
    /// Returns a single Base64 string containing nonce+ciphertext+tag (AES.GCM sealed box `combined`).
    static func encryptAPIKey(_ apiKey: String) throws -> String {
        let key = try getOrCreateMasterKey()
        let plaintext = Data(apiKey.utf8)

        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw NSError(
                domain: "SecureCrypto",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Encryption failed: missing combined box"]
            )
        }

        return combined.base64EncodedString()
    }

    /// Decrypt the Base64 sealed box back into the plaintext API key string.
    static func decryptAPIKey(_ encryptedCombinedBase64: String) throws -> String {
        let key = try getOrCreateMasterKey()

        guard let combinedData = Data(base64Encoded: encryptedCombinedBase64) else {
            throw NSError(
                domain: "SecureCrypto",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Bad base64 for encrypted key"]
            )
        }

        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        guard let result = String(data: decryptedData, encoding: .utf8) else {
            throw NSError(
                domain: "SecureCrypto",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "UTF-8 decode failed"]
            )
        }

        return result
    }
}
