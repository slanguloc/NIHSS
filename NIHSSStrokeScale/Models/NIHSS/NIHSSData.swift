//
//  NIHSSData.swift
//  NIHSS Stroke Scale — All 11 categories with Spanish prompts for patients.
//

import Foundation

enum NIHSSData {

    static let allItems: [NIHSSItem] = [
        // 1a. Level of Consciousness — no Spanish audio (observation only)
        NIHSSItem(
            id: "1a",
            providerLabel: "1a. Level of Consciousness",
            providerInstructions: "Assess alertness. Score 3 only if no movement other than reflex to noxious stimulation.",
            providerPromptEnglish: "No verbal command; observe if the patient is awake and alert.",
            spanishPrompt: "",
            spanishPhrases: [],
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "1a-0", score: 0, englishText: "Alert; keenly responsive", spanishText: nil),
                NIHSSOption(id: "1a-1", score: 1, englishText: "Not alert; arousable by minor stimulation", spanishText: nil),
                NIHSSOption(id: "1a-2", score: 2, englishText: "Requires repeated or painful stimulation", spanishText: nil),
                NIHSSOption(id: "1a-3", score: 3, englishText: "Unresponsive or reflex only", spanishText: nil)
            ]
        ),
        // 1b. LOC Questions — month and age (separate phrases for audio)
        NIHSSItem(
            id: "1b",
            providerLabel: "1b. LOC Questions",
            providerInstructions: "Ask: What is the month? What is your age? Both must be correct for 0.",
            providerPromptEnglish: "Ask the patient each question separately:",
            spanishPrompt: "Dígale al paciente cada pregunta por separado:",
            spanishPhrases: ["¿En qué mes estamos?", "¿Cuántos años tiene?"],
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "1b-0", score: 0, englishText: "Answers both correctly", spanishText: "Las dos correctas"),
                NIHSSOption(id: "1b-1", score: 1, englishText: "Answers one correctly", spanishText: "Una correcta"),
                NIHSSOption(id: "1b-2", score: 2, englishText: "Answers neither correctly", spanishText: "Ninguna correcta")
            ]
        ),
        // 1c. LOC Commands (separate phrases for audio)
        NIHSSItem(
            id: "1c",
            providerLabel: "1c. LOC Commands",
            providerInstructions: "Ask patient to open and close eyes, then grip and release the non-paretic hand.",
            providerPromptEnglish: "Give each command separately (or the non-paretic hand):",
            spanishPrompt: "Dígale cada orden por separado (o la mano que no esté débil):",
            spanishPhrases: ["Abra y cierre los ojos.", "Apriete y suelte mi mano."],
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "1c-0", score: 0, englishText: "Performs both tasks correctly", spanishText: "Las dos bien"),
                NIHSSOption(id: "1c-1", score: 1, englishText: "Performs one correctly", spanishText: "Una bien"),
                NIHSSOption(id: "1c-2", score: 2, englishText: "Performs neither", spanishText: "Ninguna")
            ]
        ),
        // 2. Best Gaze
        NIHSSItem(
            id: "2",
            providerLabel: "2. Best Gaze",
            providerInstructions: "Test horizontal eye movements. Only if patient cannot follow, test oculocephalic or use voluntary saccades.",
            providerPromptEnglish: "Say: Follow my finger with your eyes (move finger left and right).",
            spanishPrompt: "Siga mi dedo con los ojos",
            spanishPhrases: nil,
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "2-0", score: 0, englishText: "Normal", spanishText: "Normal"),
                NIHSSOption(id: "2-1", score: 1, englishText: "Partial gaze palsy", spanishText: "Parcial"),
                NIHSSOption(id: "2-2", score: 2, englishText: "Forced deviation or total gaze palsy", spanishText: "Desviación forzada")
            ]
        ),
        // 3. Visual
        NIHSSItem(
            id: "3",
            providerLabel: "3. Visual",
            providerInstructions: "Visual field confrontation in upper and lower quadrants. Use finger counting or visual threat. Score 3 only if bilateral blindness or no light perception.",
            providerPromptEnglish: "Say: tell me how many you see (test each visual field).",
            spanishPrompt: "Matenga su mirada en mi nariz, y ahora dígame cuántos dedos ve",
            spanishPhrases: nil,
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "3-0", score: 0, englishText: "No visual loss", spanishText: "Sin pérdida"),
                NIHSSOption(id: "3-1", score: 1, englishText: "Partial hemianopia", spanishText: "Hemianopsia parcial"),
                NIHSSOption(id: "3-2", score: 2, englishText: "Complete hemianopia", spanishText: "Hemianopsia completa"),
                NIHSSOption(id: "3-3", score: 3, englishText: "Bilateral hemianopia or blindness", spanishText: "Bilateral o ceguera")
            ]
        ),
        // 4. Facial Palsy (separate phrases for audio)
        NIHSSItem(
            id: "4",
            providerLabel: "4. Facial Palsy",
            providerInstructions: "Ask for teeth show, eye closure, or frown. Score symmetry.",
            providerPromptEnglish: "Say each command separately:",
            spanishPrompt: "Dígale cada orden por separado:",
            spanishPhrases: ["Muéstreme los dientes.", "Cierre los ojos con fuerza."],
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "4-0", score: 0, englishText: "Normal", spanishText: "Normal"),
                NIHSSOption(id: "4-1", score: 1, englishText: "Minor paralysis", spanishText: "Parálisis menor"),
                NIHSSOption(id: "4-2", score: 2, englishText: "Partial paralysis", spanishText: "Parálisis parcial"),
                NIHSSOption(id: "4-3", score: 3, englishText: "Complete paralysis", spanishText: "Parálisis completa")
            ]
        ),
        // 5. Motor Arm — Left and Right
        NIHSSItem(
            id: "5Arm",
            providerLabel: "5. Motor Arm",
            providerInstructions: "Arm extended 90° (sitting) or 45° (supine), palms down. Hold 10 seconds. Test left then right.",
            providerPromptEnglish: "Say: Keep your arm out like this, palm down (demonstrate). Don't let it drop.",
            spanishPrompt: "Mantenga el brazo estirado con la palma hacia abajo y no lo deje caer",
            spanishPhrases: nil,
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "5-0", score: 0, englishText: "No drift", spanishText: "Sin caída"),
                NIHSSOption(id: "5-1", score: 1, englishText: "Drift before 10 sec", spanishText: "Cae antes de 10 s"),
                NIHSSOption(id: "5-2", score: 2, englishText: "Falls before 10 sec", spanishText: "Cae antes de 10 s"),
                NIHSSOption(id: "5-3", score: 3, englishText: "No effort vs gravity", spanishText: "No vence la gravedad"),
                NIHSSOption(id: "5-4", score: 4, englishText: "No movement", spanishText: "Sin movimiento")
            ]
        ),
        // 6. Motor Leg — Left and Right
        NIHSSItem(
            id: "6Leg",
            providerLabel: "6. Motor Leg",
            providerInstructions: "Leg raised 30° (always supine). Hold 5 seconds. Test left then right.",
            providerPromptEnglish: "Say: Lift your leg and hold it for a few seconds (demonstrate).",
            spanishPrompt: "Levante la pierna, manténgala arriba, y no la deje caer",
            spanishPhrases: nil,
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "6-0", score: 0, englishText: "No drift", spanishText: "Sin caída"),
                NIHSSOption(id: "6-1", score: 1, englishText: "Drift before 5 sec", spanishText: "Cae antes de 5 s"),
                NIHSSOption(id: "6-2", score: 2, englishText: "Falls before 5 sec", spanishText: "Cae antes de 5 s"),
                NIHSSOption(id: "6-3", score: 3, englishText: "No effort vs gravity", spanishText: "No vence la gravedad"),
                NIHSSOption(id: "6-4", score: 4, englishText: "No movement", spanishText: "Sin movimiento")
            ]
        ),
        // 7. Limb Ataxia (separate phrases for audio)
        NIHSSItem(
            id: "7",
            providerLabel: "7. Limb Ataxia",
            providerInstructions: "Finger-nose and heel-shin. Score only if out of proportion to weakness. Ignore if paralysis.",
            providerPromptEnglish: "Say each command separately:",
            spanishPrompt: "Dígale cada orden por separado:",
            spanishPhrases: ["Toque mi dedo y luego su nariz.", "Hazlo de nuevo varias veces.", "Deslice el talón de un pie desde la rodilla hacia abajo sobre la espinilla, y luego hacia arriba.", "Hazlo de nuevo varias veces."],
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "7-0", score: 0, englishText: "Absent", spanishText: "Ausente"),
                NIHSSOption(id: "7-1", score: 1, englishText: "Present in 1 limb", spanishText: "En una extremidad"),
                NIHSSOption(id: "7-2", score: 2, englishText: "Present in 2 limbs", spanishText: "En dos extremidades")
            ]
        ),
        // 8. Sensory
        NIHSSItem(
            id: "8",
            providerLabel: "8. Sensory",
            providerInstructions: "Pinprick to face, arm, leg. Compare sides. Score 2 only if severe loss (e.g. no sensation or unaware).",
            providerPromptEnglish: "Say: Does this feel the same on both sides? (light pinprick on face, arm, leg).",
            spanishPrompt: "Vamos a probar la sensasión del cuerpo. Voy a tocar la piel or causar un poco de dolor en diferentes partes del cuerpo",
            spanishPhrases: ["¿Siente cuando toco la piel igual en los dos lados?", "¿Siente dolor igual en los dos lados?", "Derecha, izquierda, o los dos lados"],
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "8-0", score: 0, englishText: "Normal", spanishText: "Normal"),
                NIHSSOption(id: "8-1", score: 1, englishText: "Mild to moderate decrease", spanishText: "Disminución leve o moderada"),
                NIHSSOption(id: "8-2", score: 2, englishText: "Severe or total loss", spanishText: "Pérdida severa o total")
            ]
        ),
        // 9. Best Language (separate phrases for audio; show objects + describe picture)
        NIHSSItem(
            id: "9",
            providerLabel: "9. Best Language",
            providerInstructions: "Name items, read sentences, describe picture. Score aphasia. If visual or other barrier, use naming and repetition.",
            providerPromptEnglish: "Say each prompt separately. (1) Name objects. (2) Read sentences. (3) Describe picture.",
            spanishPrompt: "Dígale cada parte por separado:",
            spanishPhrases: ["Nombre estos objetos:", "Lea las siguientes frases:", "Mire esta imagen y describa lo qué ve"],
            // Figures from Mayo Clinic Proceedings 2006;81:476-480 (see SOURCES.md)
            spanishPhraseImageNames: ["Item9_Figure2", "Item9_Figure3", "Item9_Figure4"],
            // Standard NIH/NINDS English NIHSS images: naming objects, reading
            // sentences, and the picture-description scene (public domain,
            // US Federal Government work).
            englishPhraseImageNames: ["Item9_Naming_English", "Item9_Sentences_English", "Item9_Picture_English"],
            // Creole: NIH naming + picture cards (English); Creole sentence card (app-generated).
            haitianCreolePhraseImageNames: ["Item9_Naming_English", "Item9_Sentences_Creole", "Item9_Picture_English"],
            options: [
                NIHSSOption(id: "9-0", score: 0, englishText: "No aphasia", spanishText: "Sin afasia"),
                NIHSSOption(id: "9-1", score: 1, englishText: "Mild to moderate aphasia", spanishText: "Afasia leve o moderada"),
                NIHSSOption(id: "9-2", score: 2, englishText: "Severe aphasia", spanishText: "Afasia severa"),
                NIHSSOption(id: "9-3", score: 3, englishText: "Mute or global aphasia", spanishText: "Mudo o afasia global")
            ]
        ),
        // 10. Dysarthria
        NIHSSItem(
            id: "10",
            providerLabel: "10. Dysarthria",
            providerInstructions: "Rate speech clarity: normal, mild, or severe (intelligible vs unintelligible). If intubated or mute, score 2.",
            providerPromptEnglish: "Say: Repeat these words aloud (simple sentence). Rate whether speech is clear, slurred, or unintelligible.",
            spanishPrompt: "Repita en voz alta las siguientes palabras:",
            spanishPhrases: ["Repita en voz alta las siguientes palabras:","Mamá","Ta Te Ti", "Mitad y Mitad", "Gracias", "Árbol", "Futbolista"],
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "10-0", score: 0, englishText: "Normal", spanishText: "Normal"),
                NIHSSOption(id: "10-1", score: 1, englishText: "Mild to moderate", spanishText: "Leve o moderada"),
                NIHSSOption(id: "10-2", score: 2, englishText: "Severe / unintelligible or mute", spanishText: "Severa o ininteligible / mudo")
            ]
        ),
        // 11. Extinction / Inattention (sensory + visual double simultaneous stimulation)
        NIHSSItem(
            id: "11",
            providerLabel: "11. Extinction or Inattention",
            providerInstructions: "Double simultaneous stimulation (visual, sensory). Score only if neglect in one modality after bilateral stimulation.",
            providerPromptEnglish: "Say each separately: (1) When I touch you, tell me if it's one side or both. (2) When I show you fingers, tell me how many you see (or which side/sides).",
            spanishPrompt: "Cuando le toque, dígame si es izquierdo, derecho, o los dos lados",
            spanishPhrases: [
                "Cuando le toque, dígame si es izquierdo, derecho, o los dos lados",
                "Cuando le muestre los dedos, dígame cuántos ve y en qué lado (izquierda, derecha o ambos)"
            ],
            spanishPhraseImageNames: nil,
            options: [
                NIHSSOption(id: "11-0", score: 0, englishText: "No neglect", spanishText: "Sin negligencia"),
                NIHSSOption(id: "11-1", score: 1, englishText: "Inattention or extinction in one modality", spanishText: "Inatención o extinción en una modalidad"),
                NIHSSOption(id: "11-2", score: 2, englishText: "Hemi-inattention or hemi-neglect", spanishText: "Hemi-inatención o hemi-negligencia")
            ]
        )
    ]

    /// Item 5 is Motor Arm: need left and right. Item 6 is Motor Leg: need left and right.
    /// We expose a flat list of "assessment steps" so 5 and 6 each appear twice.
    static func assessmentSteps() -> [AssessmentStep] {
        var steps: [AssessmentStep] = []
        for item in allItems {
            if item.id == "5Arm" {
                steps.append(AssessmentStep(item: item, side: .left))
                steps.append(AssessmentStep(item: item, side: .right))
            } else if item.id == "6Leg" {
                steps.append(AssessmentStep(item: item, side: .left))
                steps.append(AssessmentStep(item: item, side: .right))
            } else {
                steps.append(AssessmentStep(item: item, side: nil))
            }
        }
        return steps
    }

    // MARK: - English patient prompts
    /// Patient-facing English prompts for TTS and display.
    struct EnglishPrompts {
        static func prompt(for itemId: String, side: LimbSide?) -> String {
            switch itemId {
            case "1a": return ""
            case "1b": return "Ask the patient each question separately:"
            case "1c": return "Give each command separately (or the non-paretic hand):"
            case "2": return "Follow my finger with your eyes."
            case "3": return "Keep your eyes on my nose, and tell me how many fingers you see."
            case "4": return "Say each command separately:"
            case "5Arm":
                guard let side = side else { return "Hold your arm out straight, palm down, and don't let it drop." }
                let arm = side == .left ? "left" : "right"
                return "Hold your \(arm) arm out straight, palm down, and don't let it drop."
            case "6Leg":
                guard let side = side else { return "Lift your leg, hold it up, and don't let it drop." }
                let leg = side == .left ? "left" : "right"
                return "Lift your \(leg) leg, hold it up, and don't let it drop."
            case "7": return "Say each command separately:"
            case "8": return "We're going to test feeling on your body. I may touch your skin or cause a little discomfort in different places."
            case "9": return "Say each part separately:"
            case "10": return "Repeat these words aloud:"
            case "11": return "When I touch you, tell me if it's the left side, right side, or both."
            default: return ""
            }
        }

        static func phrases(for itemId: String, side: LimbSide?) -> [String]? {
            switch itemId {
            case "1b": return ["What month is it?", "How old are you?"]
            case "1c": return ["Open and close your eyes.", "Squeeze and release my hand."]
            case "4": return ["Show me your teeth.", "Close your eyes tightly."]
            case "5Arm" where side != nil:
                return [prompt(for: itemId, side: side), "You can lower your arm."]
            case "6Leg" where side != nil:
                return [prompt(for: itemId, side: side), "You can lower your leg."]
            case "7": return [
                "Touch my finger, then your nose.",
                "Do it again several times.",
                "Slide your heel up and down your shin.",
                "Do it again several times."
            ]
            case "8": return [
                "Do you feel the same when I touch your skin on both sides?",
                "Is the pain the same on both sides?",
                "Right, left, or both sides?"
            ]
            case "9": return ["Name these objects:", "Read these sentences:", "Look at this picture and describe what you see."]
            case "10": return ["Repeat these words aloud:", "mama", "tip-top", "fifty-fifty", "thanks", "huckleberry", "baseball player"]
            case "11": return [
                "When I touch you, tell me if it's the left side, right side, or both.",
                "When I show you fingers, tell me how many you see and on which side (left, right, or both)."
            ]
            default: return nil
            }
        }
    }

    // MARK: - Haitian Creole patient prompts (Kreyòl ayisyen)
    /// Returns the patient prompt and phrases for Haitian Creole. Used by AssessmentStep.patientPromptToSpeak(language:) / patientPhrasesToSpeak(language:).
    struct CreolePrompts {
        static func prompt(for itemId: String, side: LimbSide?) -> String {
            switch itemId {
            case "1a": return ""
            case "1b": return "Di pasyan chak kesyon an yonn apre lòt:"
            case "1c": return "Bay chak lòd yonn apre lòt (itilize men ki pa fèb la):"
            case "2": return "Swiv dwèt mwen ak je w."
            case "3": return "Gade nen mwen, epi di m konbyen dwèt ou wè."
            case "4": return "Bay chak lòd yonn apre lòt:"
            case "5Arm":
                guard let side = side else { return "Lonje bra w devan w, pa lage l." }
                let bra = side == .left ? "bra gòch" : "bra dwat"
                return "Lonje \(bra) w devan w konsa, pa lage l."
            case "6Leg":
                guard let side = side else { return "Leve janm w, kenbe l anlè, pa lage l." }
                let janm = side == .left ? "janm gòch" : "janm dwat"
                return "Leve \(janm) w, kenbe l anlè, pa lage l."
            case "7": return "Bay chak lòd yonn apre lòt:"
            case "8": return "Nou pral teste sansasyon kò w. M ap manyen po w oubyen fè w santi yon ti doulè nan plizyè kote."
            case "9": return "Bay chak pati yonn apre lòt:"
            case "10": return "Repete mo sa yo byen fò:"
            case "11": return "Lè m manyen w, di m si se yon sèl bò oubyen tou de bò."
            default: return ""
        }
    }
    static func phrases(for itemId: String, side: LimbSide?) -> [String]? {
        switch itemId {
        case "1b": return ["Ki mwa nou ye?", "Konbyen ane ou genyen?"]
        case "1c": return ["Louvri epi fèmen je w.", "Sere men mwen, epi lage l."]
        case "4": return ["Montre m dan w.", "Fèmen je w byen fèm."]
        case "5Arm" where side != nil:
            return [prompt(for: itemId, side: side), "Ou mèt desann bra w."]
        case "6Leg" where side != nil:
            return [prompt(for: itemId, side: side), "Ou mèt desann janm w."]
        case "7": return ["Touche dwèt mwen, epi touche nen w.", "Refè l plizyè fwa.", "Glise talon w sou janm ou.", "Refè l plizyè fwa."]
        case "8": return ["Èske w santi menm bagay la sou tou de bò?", "Èske doulè a menm jan sou tou de bò?", "Bò dwat, bò gòch, oubyen tou de bò?"]
        case "9": return ["Nonmen objè sa yo:", "Li fraz sa yo:", "Gade imaj sa a, epi dekri sa w wè."]
        case "10": return ["Repete mo sa yo byen fò:", "Manman", "Ta Te Ti", "Tip-Top", "Mèsi", "Pye bwa", "Foutbòl"]
        case "11": return [
            "Lè m manyen w, di m si se yon sèl bò oubyen tou de bò.",
            "Lè m montre w dwèt, di m konbyen w wè epi sou ki bò (gòch, dwat, oubyen tou de bò)."
        ]
        default: return nil
        }
    }
    }
}

enum LimbSide: String, CaseIterable {
    case left = "Left"
    case right = "Right"
    var spanish: String { self == .left ? "Izquierdo" : "Derecho" }
    /// Left/right label in the given patient language.
    func label(for language: AppLanguage) -> String {
        switch language {
        case .english: return rawValue
        case .spanish: return spanish
        case .haitianCreole: return self == .left ? "gòch" : "dwat"
        }
    }
}

struct AssessmentStep: Identifiable {
    let item: NIHSSItem
    let side: LimbSide?
    var id: String {
        if let s = side { return "\(item.id)-\(s.rawValue)" }
        return item.id
    }
    var providerLabel: String {
        if let s = side { return "\(item.providerLabel) (\(s.rawValue))" }
        return item.providerLabel
    }
    /// Full Spanish text to speak. Items 5 and 6 use side in the sentence (brazo izquierdo/derecho, pierna izquierda/derecha).
    var spanishPromptToSpeak: String {
        let base = item.spanishPrompt
        guard let side = side else { return base }
        // Item 5 (Motor Arm): side in sentence — "brazo izquierdo" / "brazo derecho"
        if item.id == "5Arm" {
            let armSide = side == .left ? "izquierdo" : "derecho"
            return "Mantenga el brazo \(armSide) estirado con la palma hacia abajo y no lo deje caer"
        }
        // Item 6 (Motor Leg): side in sentence — "pierna izquierda" / "pierna derecha"
        if item.id == "6Leg" {
            let legSide = side == .left ? "izquierda" : "derecha"
            return "Levante la pierna \(legSide), manténgala arriba, y no la deje caer"
        }
        return base + " Lado \(side.spanish)."
    }

    /// Separate phrases for audio. When item has spanishPhrases (e.g. 1b, 1c), one per Play button; else single element. Items 5 and 6 add a follow-up "you can lower" phrase.
    var spanishPhrasesToSpeak: [String] {
        if let phrases = item.spanishPhrases {
            return phrases
        }
        // Item 5: main command + "Puede bajar el brazo"
        if item.id == "5Arm", side != nil {
            return [spanishPromptToSpeak, "Puede bajar el brazo"]
        }
        // Item 6: main command + "Puede bajar la pierna"
        if item.id == "6Leg", side != nil {
            return [spanishPromptToSpeak, "Puede bajar la pierna"]
        }
        return [spanishPromptToSpeak]
    }

    /// Patient prompt to speak (single string). Uses selected language.
    func patientPromptToSpeak(language: AppLanguage) -> String {
        switch language {
        case .english: return NIHSSData.EnglishPrompts.prompt(for: item.id, side: side)
        case .spanish: return spanishPromptToSpeak
        case .haitianCreole: return NIHSSData.CreolePrompts.prompt(for: item.id, side: side)
        }
    }

    /// Patient phrases to speak (one per Play). Uses selected language.
    func patientPhrasesToSpeak(language: AppLanguage) -> [String] {
        switch language {
        case .english:
            if let phrases = NIHSSData.EnglishPrompts.phrases(for: item.id, side: side) {
                return phrases
            }
            let single = NIHSSData.EnglishPrompts.prompt(for: item.id, side: side)
            return single.isEmpty ? [] : [single]
        case .spanish: return spanishPhrasesToSpeak
        case .haitianCreole:
            if let phrases = NIHSSData.CreolePrompts.phrases(for: item.id, side: side) {
                return phrases
            }
            let single = NIHSSData.CreolePrompts.prompt(for: item.id, side: side)
            return single.isEmpty ? [] : [single]
        }
    }
}
