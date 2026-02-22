//
//  LanguageStore.swift
//  NIHSS Stroke Scale — Selected patient language.
//

import Foundation
import SwiftUI

/// Stores the selected patient language. Persists across launches.
final class LanguageStore: ObservableObject {
    @Published var selectedLanguage: AppLanguage {
        didSet { save() }
    }

    private let key = "NIHSSSelectedLanguage"

    init() {
        if let raw = UserDefaults.standard.string(forKey: key),
           let lang = AppLanguage(rawValue: raw),
           AppLanguage.visibleToUser.contains(lang) {
            selectedLanguage = lang
        } else {
            selectedLanguage = .spanish
        }
    }

    private func save() {
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: key)
    }

    /// True if user has explicitly chosen a language at app start.
    var hasCompletedLanguageSelection: Bool {
        UserDefaults.standard.object(forKey: key) != nil
    }

    func markLanguageSelectionCompleted() {
        save()
    }
}
