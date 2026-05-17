//
//  NIHSSItem.swift
//  NIHSS Stroke Scale
//

import Foundation

/// One item (or sub-item) of the NIH Stroke Scale.
struct NIHSSItem: Identifiable {
    let id: String
    /// Short label for provider (e.g. "1a. LOC")
    let providerLabel: String
    /// Full English instructions for the provider.
    let providerInstructions: String
    /// English instruction for the provider: what to say or do (displayed in the prompt section).
    let providerPromptEnglish: String
    /// Spanish phrase(s) for the patient. When spanishPhrases is set, this is not shown as main text; otherwise used for display and single Play.
    let spanishPrompt: String
    /// When set, separate phrases for audio (e.g. 1b: two questions; 1c: two commands). Each gets its own Play.
    let spanishPhrases: [String]?
    /// Optional image asset names, one per spanishPhrases (e.g. item 9: Figure 2, 3, 4 from Mayo PDF). When set, count must match spanishPhrases.
    let spanishPhraseImageNames: [String]?
    /// Optional English-specific image asset names. Same indexing as
    /// `spanishPhraseImageNames`. When nil, the Spanish image is reused.
    /// Used by item 9 to show the standard NIH/NINDS English NIHSS images
    /// (naming card, sentence card, picture).
    var englishPhraseImageNames: [String]? = nil
    /// Haitian Creole Item 9 images: naming + picture reuse English NIH
    /// assets; sentences use a dedicated Creole card.
    var haitianCreolePhraseImageNames: [String]? = nil
    /// Scoring options: score value and Spanish text for that option (when relevant).
    let options: [NIHSSOption]
    /// If true, this item has two sides (e.g. motor arm left/right) and options may repeat.
    var hasLeftRight: Bool { id.hasSuffix("Arm") || id.hasSuffix("Leg") }

    /// Returns the appropriate image names to show for the given patient
    /// language. Falls back to the Spanish/default set when no language-
    /// specific set is provided.
    func phraseImageNames(for language: AppLanguage) -> [String]? {
        switch language {
        case .english:
            return englishPhraseImageNames ?? spanishPhraseImageNames
        case .spanish:
            return spanishPhraseImageNames
        case .haitianCreole:
            return haitianCreolePhraseImageNames ?? englishPhraseImageNames ?? spanishPhraseImageNames
        }
    }
}

struct NIHSSOption: Identifiable {
    let id: String
    let score: Int
    let englishText: String
    let spanishText: String?
}
