//
//  AppLanguage.swift
//  NIHSS Stroke Scale — Patient language selection.
//

import Foundation

/// Patient-facing language. Extensible for future languages.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case spanish = "es"

    var id: String { rawValue }

    /// Display name for the language picker.
    var displayName: String {
        switch self {
        case .spanish: return "Español"
        }
    }

    /// AVSpeechSynthesisVoice language code.
    var speechLocale: String {
        switch self {
        case .spanish: return "es-CO"  // Colombian — neutral accent
        }
    }

    /// Fallback voice codes if primary not available.
    var speechFallbacks: [String] {
        switch self {
        case .spanish: return ["es-MX", "es"]
        }
    }
}
