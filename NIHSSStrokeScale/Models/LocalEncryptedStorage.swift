//
//  LocalEncryptedStorage.swift
//  Zysquy — Encrypt local data for patient information safety.
//

import Foundation
import CryptoKit
import Security

/// Encrypts and decrypts data for local storage. Key is stored in the Keychain and never leaves the device.
enum LocalEncryptedStorage {
    private static let keychainService = "ZysquyLocalEncryption"
    private static let keychainAccount = "LocalDataKey"

    /// Encrypts data for storage. Returns nil on failure.
    static func encrypt(_ data: Data) -> Data? {
        guard let key = getOrCreateKey() else { return nil }
        let symmetricKey = SymmetricKey(data: key)
        do {
            let sealed = try AES.GCM.seal(data, using: symmetricKey)
            return sealed.combined
        } catch {
            return nil
        }
    }

    /// Decrypts data from storage. Returns nil if decryption fails (e.g. wrong key or corrupted).
    static func decrypt(_ data: Data) -> Data? {
        guard let key = getOrCreateKey() else { return nil }
        let symmetricKey = SymmetricKey(data: key)
        do {
            let box = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(box, using: symmetricKey)
        } catch {
            return nil
        }
    }

    private static func getOrCreateKey() -> Data? {
        if let existing = loadKeyFromKeychain() { return existing }
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes { ptr -> Int32 in
            guard let base = ptr.baseAddress else { return errSecAllocate }
            return SecRandomCopyBytes(kSecRandomDefault, 32, base)
        }
        guard result == errSecSuccess else { return nil }
        guard saveKeyToKeychain(keyData) else { return nil }
        return keyData
    }

    private static func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data, data.count == 32 else { return nil }
        return data
    }

    private static func saveKeyToKeychain(_ keyData: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
