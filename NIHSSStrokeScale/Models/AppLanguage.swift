//
//  AppLanguage.swift
//  NIHSS Stroke Scale — Patient language selection.
//

import Foundation

/// Patient-facing language. Extensible for future languages.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case spanish = "es"
    case haitianCreole = "ht"

    var id: String { rawValue }

    /// Languages exposed to the user in the language picker.
    /// All three languages have full coverage: NIHSS prompts, TTS, speech
    /// recognition + simple back-translation, and consent script translations.
    static var visibleToUser: [AppLanguage] { [.english, .spanish, .haitianCreole] }

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
