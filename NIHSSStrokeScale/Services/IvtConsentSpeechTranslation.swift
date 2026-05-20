//
//  IvtConsentSpeechTranslation.swift
//  Zysquy — Patient IVT consent speech → English (training aid).
//

import Foundation

/// Training-only interpretation of whether the patient agreed to IV thrombolysis.
enum IvtConsentInterpretation: Equatable {
    case agrees
    case refuses
    case uncertain
    case unclear

    var summaryEnglish: String {
        switch self {
        case .agrees: return "Patient agrees to IV thrombolysis (training interpretation)"
        case .refuses: return "Patient declines IV thrombolysis (training interpretation)"
        case .uncertain: return "Patient uncertain / needs more discussion (training interpretation)"
        case .unclear: return "Could not classify — review transcription"
        }
    }
}

enum IvtConsentSpeechTranslation {

    /// Spanish and Haitian Creole phrases for consent answers (longer matches first).
    private static let spanishPhrases: [(String, String)] = [
        ("no estoy de acuerdo", "I do not agree"),
        ("no estoy seguro", "I am not sure"),
        ("no estoy segura", "I am not sure"),
        ("habla con mi familia", "talk to my family"),
        ("háblame con mi familia", "talk to my family"),
        ("hablé con mi familia", "talked to my family"),
        ("necesito pensarlo", "I need to think about it"),
        ("déjame pensarlo", "let me think about it"),
        ("dejame pensarlo", "let me think about it"),
        ("no quiero el tratamiento", "I do not want the treatment"),
        ("no quiero tratamiento", "I do not want treatment"),
        ("no quiero la medicina", "I do not want the medicine"),
        ("no quiero la inyección", "I do not want the injection"),
        ("no quiero inyección", "I do not want injection"),
        ("no quiero ponerme", "I do not want to get"),
        ("prefiero no", "I prefer not"),
        ("sin tratamiento", "without treatment"),
        ("estoy de acuerdo", "I agree"),
        ("de acuerdo", "agree"),
        ("por supuesto", "of course"),
        ("claro que sí", "yes of course"),
        ("claro que si", "yes of course"),
        ("sí quiero", "yes I want"),
        ("si quiero", "yes I want"),
        ("acepto el tratamiento", "I accept the treatment"),
        ("acepto la medicina", "I accept the medicine"),
        ("acepto el riesgo", "I accept the risk"),
        ("acepto los riesgos", "I accept the risks"),
        ("no acepto", "I do not accept"),
        ("no gracias", "no thank you"),
        ("me niego", "I refuse"),
        ("rechazo", "I refuse"),
        ("rechazo el tratamiento", "I refuse the treatment"),
        ("no sé", "I don't know"),
        ("no se", "I don't know"),
        ("tal vez", "maybe"),
        ("quizás", "maybe"),
        ("quizas", "maybe"),
        ("está bien", "okay"),
        ("esta bien", "okay"),
        ("vale", "okay"),
        ("por favor sí", "yes please"),
        ("por favor si", "yes please"),
        ("sí por favor", "yes please"),
        ("si por favor", "yes please"),
        ("sí", "yes"),
        ("si", "yes"),
        ("no", "no"),
        ("acepto", "I accept"),
        ("autorizo", "I authorize"),
        ("consiento", "I consent"),
        ("doy permiso", "I give permission"),
    ]

    private static let creolePhrases: [(String, String)] = [
        ("mwen pa dakò", "I do not agree"),
        ("mwen pa dakò ak sa", "I do not agree with that"),
        ("mwen pa dakò ak tretman an", "I do not agree with the treatment"),
        ("mwen pa vle tretman an", "I do not want the treatment"),
        ("mwen pa vle medikaman an", "I do not want the medicine"),
        ("mwen pa vle pike a", "I do not want the shot"),
        ("mwen pa vle piqûre a", "I do not want the shot"),
        ("mwen pa vle anyen", "I do not want anything"),
        ("mwen bezwen pale ak fanmi m", "I need to talk to my family"),
        ("mwen bezwen pale ak fanmi mwen", "I need to talk to my family"),
        ("mwen bezwen tan reflechi", "I need time to think"),
        ("mwen pa konnen", "I don't know"),
        ("mwen pa sèten", "I am not sure"),
        ("mwen pa seten", "I am not sure"),
        ("mwen pa sè", "I am not sure"),
        ("mwen dakò", "I agree"),
        ("mwen dakò ak tretman an", "I agree with the treatment"),
        ("mwen dakò ak medikaman an", "I agree with the medicine"),
        ("wi mwen dakò", "yes I agree"),
        ("wi mwen vle", "yes I want"),
        ("mwen vle tretman an", "I want the treatment"),
        ("mwen vle medikaman an", "I want the medicine"),
        ("mwen accepte", "I accept"),
        ("mwen aksepte", "I accept"),
        ("mwen bay pèmisyon", "I give permission"),
        ("mwen bay pemisyon", "I give permission"),
        ("mwen refize", "I refuse"),
        ("mwen refize tretman an", "I refuse the treatment"),
        ("non mèsi", "no thank you"),
        ("non mesi", "no thank you"),
        ("non mwen pa vle", "no I do not want"),
        ("pa vle", "do not want"),
        ("wi byen", "yes okay"),
        ("wi anfòm", "yes fine"),
        ("anfòm", "fine"),
        ("anfom", "fine"),
        ("oke", "okay"),
        ("dakò", "agree"),
        ("dakò wi", "agree yes"),
        ("wi", "yes"),
        ("non", "no"),
        ("wi mèsi", "yes thank you"),
        ("wi mesi", "yes thank you"),
        ("mwen pa vle", "I do not want"),
        ("petèt", "maybe"),
        ("petet", "maybe"),
    ]

    private static let englishPhrases: [(String, String)] = [
        ("i don't want", "I do not want"),
        ("i do not want", "I do not want"),
        ("i don't know", "I don't know"),
        ("not sure", "not sure"),
        ("need to think", "need to think"),
        ("talk to my family", "talk to my family"),
        ("i agree", "I agree"),
        ("i accept", "I accept"),
        ("go ahead", "go ahead"),
        ("that's fine", "that's fine"),
        ("yes please", "yes please"),
        ("no thank you", "no thank you"),
        ("i refuse", "I refuse"),
        ("i decline", "I decline"),
    ]

    static func translate(_ text: String, from language: AppLanguage) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        var normalized = trimmed.lowercased()
        normalized = normalized.folding(options: .diacriticInsensitive, locale: nil)

        let phrases: [(String, String)]
        switch language {
        case .english: phrases = englishPhrases
        case .spanish: phrases = spanishPhrases
        case .haitianCreole: phrases = creolePhrases
        }

        for (source, english) in phrases.sorted(by: { $0.0.count > $1.0.count }) {
            let src = source.folding(options: .diacriticInsensitive, locale: nil)
            normalized = normalized.replacingOccurrences(of: src, with: english.lowercased())
        }

        let interpretation = interpret(normalized)
        let gloss = normalized.isEmpty ? trimmed : normalized
        return "\(gloss.capitalizedFirst) — \(interpretation.summaryEnglish)"
    }

    static func interpret(_ normalizedEnglish: String) -> IvtConsentInterpretation {
        let t = normalizedEnglish.lowercased()

        let refuseMarkers = [
            "i do not want", "i don't want", "do not want", "i do not agree",
            "i don't agree", "i refuse", "i decline", "no thank you",
            "without treatment", "i do not accept", "prefer not"
        ]
        let agreeMarkers = [
            "i agree", "i accept", "i consent", "i authorize", "i give permission",
            "yes", "of course", "okay", "go ahead", "i want the treatment",
            "i want the medicine", "yes i want", "fine", "that's fine"
        ]
        let uncertainMarkers = [
            "don't know", "not sure", "need to think", "talk to my family",
            "maybe", "let me think", "need time"
        ]

        if refuseMarkers.contains(where: { t.contains($0) }) { return .refuses }
        if uncertainMarkers.contains(where: { t.contains($0) }) { return .uncertain }
        if agreeMarkers.contains(where: { t.contains($0) }) { return .agrees }

        // Standalone "no" / "yes" after phrase pass
        let tokens = Set(t.split(separator: " ").map(String.init))
        if tokens.contains("no") && !tokens.contains("yes") { return .refuses }
        if tokens.contains("yes") || tokens == ["okay"] || tokens == ["ok"] { return .agrees }

        return .unclear
    }
}

private extension String {
    var capitalizedFirst: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}
