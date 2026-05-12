//
//  AppLanguage.swift
//  NIHSS Stroke Scale — Patient language selection.
//

import Foundation

/// Patient-facing language. Extensible for future languages.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case spanish = "es"
    case haitianCreole = "ht"  // Implemented but hidden from UI until ready to release

    var id: String { rawValue }

    /// Languages shown in the language picker. Haitian Creole is hidden for now.
    static var visibleToUser: [AppLanguage] { [.english, .spanish] }

    /// Display name for the language picker.
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .haitianCreole: return "Kreyòl ayisyen"
        }
    }

    /// AVSpeechSynthesisVoice language code.
    var speechLocale: String {
        switch self {
        case .english: return "en-US"
        case .spanish: return "es-CO"  // Colombian — neutral accent
        case .haitianCreole: return "ht-HT"  // Haitian Creole (Haiti)
        }
    }

    /// Fallback voice codes if primary not available (order tried after speechLocale).
    var speechFallbacks: [String] {
        switch self {
        case .english: return ["en-GB", "en-AU", "en-CA", "en"]
        case .spanish: return ["es-MX", "es-ES", "es-US", "es-AR", "es"]
        case .haitianCreole: return ["ht", "fr"]
        }
    }

    /// Language prefix for scanning AVSpeechSynthesisVoice.speechVoices() (e.g. "es", "ht").
    var voiceLanguagePrefix: String {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        case .haitianCreole: return "ht"
        }
    }
}
