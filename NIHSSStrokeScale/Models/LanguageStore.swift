//
//  LanguageStore.swift
//  NIHSS Stroke Scale — Selected patient language.
//

import Foundation
import SwiftUI

/// Stores the selected patient language. Persists across launches (encrypted locally).
final class LanguageStore: ObservableObject {
    @Published var selectedLanguage: AppLanguage {
        didSet { save() }
    }

    private static let keyEncrypted = "NIHSSSelectedLanguageEncrypted"
    private static let keyLegacy = "NIHSSSelectedLanguage"

    init() {
        if let lang = Self.loadEncrypted() ?? Self.loadLegacy() {
            selectedLanguage = lang
        } else {
            selectedLanguage = .spanish
        }
    }

    private static func loadEncrypted() -> AppLanguage? {
        guard let stored = UserDefaults.standard.data(forKey: keyEncrypted),
              let decrypted = LocalEncryptedStorage.decrypt(stored),
              let raw = String(data: decrypted, encoding: .utf8),
              let lang = AppLanguage(rawValue: raw),
              AppLanguage.visibleToUser.contains(lang) else { return nil }
        return lang
    }

    private static func loadLegacy() -> AppLanguage? {
        guard let raw = UserDefaults.standard.string(forKey: keyLegacy),
              let lang = AppLanguage(rawValue: raw),
              AppLanguage.visibleToUser.contains(lang) else { return nil }
        return lang
    }

    private func save() {
        let raw = selectedLanguage.rawValue
        guard let data = raw.data(using: .utf8),
              let encrypted = LocalEncryptedStorage.encrypt(data) else { return }
        UserDefaults.standard.set(encrypted, forKey: Self.keyEncrypted)
    }

    /// True if user has explicitly chosen a language at app start.
    var hasCompletedLanguageSelection: Bool {
        UserDefaults.standard.data(forKey: Self.keyEncrypted) != nil
            || UserDefaults.standard.object(forKey: Self.keyLegacy) != nil
    }

    func markLanguageSelectionCompleted() {
        save()
    }
}
