//
//  StrokeCodeConsent.swift
//  Zysquy — Patient / family consent scripts for IV thrombolysis (training).
//
//  Provides short, plain-language scripts a trainee can practice reading to
//  a patient or family member when alteplase or tenecteplase is recommended.
//
//  Educational only. The scripts here are training aids and do NOT replace
//  your institution's informed-consent process, your hospital's consent form,
//  or a qualified medical interpreter. Always document consent per your
//  local protocol.
//

import Foundation

/// One section of the consent script with an icon and the per-language text.
struct ConsentSection: Identifiable {
    let id: String
    /// SF Symbol used as a small section marker.
    let systemImage: String
    /// Short heading for the section (in the provider's language — English).
    let heading: String
    /// Per-language patient/family-facing script.
    let texts: [AppLanguage: String]

    func text(for language: AppLanguage) -> String {
        texts[language] ?? texts[.english] ?? ""
    }
}

/// Catalog of consent scripts (training). Plain-language summaries of the
/// most commonly covered points before IV thrombolysis. Plug `<drug>` in to
/// the script via `script(for:)` so the trainee can practice with either
/// alteplase or tenecteplase.
enum ConsentScriptCatalog {

    /// Builds the section list, substituting the chosen drug name in the
    /// language-specific way.
    static func script(for choice: ThrombolyticChoice) -> [ConsentSection] {
        let drugEN: String
        let drugES: String
        let drugHT: String
        switch choice {
        case .tenecteplase:
            drugEN = "tenecteplase (a clot-busting medicine called TNK)"
            drugES = "tenecteplasa (un medicamento que disuelve coágulos, conocido como TNK)"
            drugHT = "tenektéplaz (yon medikaman ki disoud kayo san, yo rele TNK)"
        case .alteplase:
            drugEN = "alteplase (a clot-busting medicine called tPA)"
            drugES = "alteplasa (un medicamento que disuelve coágulos, conocido como tPA)"
            drugHT = "alteplaz (yon medikaman ki disoud kayo san, yo rele tPA)"
        default:
            drugEN = "a clot-busting medicine"
            drugES = "un medicamento que disuelve coágulos"
            drugHT = "yon medikaman ki disoud kayo san"
        }

        return [
            ConsentSection(
                id: "what",
                systemImage: "exclamationmark.triangle.fill",
                heading: "What we think is happening",
                texts: [
                    .english:  "We believe you (or your loved one) is having a stroke. This means blood flow to part of the brain has been blocked, and brain cells are being injured. We have to act quickly.",
                    .spanish:  "Creemos que usted (o su familiar) está sufriendo un derrame cerebral. Esto significa que el flujo de sangre a una parte del cerebro está bloqueado y las células del cerebro se están dañando. Tenemos que actuar rápido.",
                    .haitianCreole: "Nou kwè ou menm (oswa moun ou renmen an) ap fè yon konjèksyon (AVC). Sa vle di san pa rive nan yon pati nan sèvo a, epi selil sèvo yo ap mouri. Nou bezwen aji vit."
                ]
            ),
            ConsentSection(
                id: "what-med",
                systemImage: "syringe.fill",
                heading: "The medicine we recommend",
                texts: [
                    .english:  "We recommend giving \(drugEN). It is given through an IV. It works by dissolving the clot in the blood vessel of the brain so blood flow can return.",
                    .spanish:  "Recomendamos administrar \(drugES). Se administra por vía intravenosa. Funciona disolviendo el coágulo en la arteria del cerebro para que el flujo sanguíneo pueda regresar.",
                    .haitianCreole: "Nou rekòmande pou nou bay \(drugHT). Yo bay li nan venn (IV). Li ede disoud kayo san an nan veso san sèvo a, pou san an ka pase ankò."
                ]
            ),
            ConsentSection(
                id: "benefit",
                systemImage: "heart.text.square.fill",
                heading: "The expected benefit",
                texts: [
                    .english:  "When this medicine is given within the treatment window, there is a much better chance of recovering function — walking, speaking, and using the arm or leg — than without it. The sooner we give it, the better the chance of a good outcome.",
                    .spanish:  "Cuando se administra este medicamento dentro del tiempo permitido, hay una probabilidad mucho mayor de recuperar funciones — caminar, hablar y usar el brazo o la pierna — que sin él. Cuanto antes lo demos, mejor será la posibilidad de un buen resultado.",
                    .haitianCreole: "Lè nou bay medikaman sa a nan tan ki bezwen an, gen yon pi bon chans pou refè fonksyon yo — mache, pale, sèvi ak bra oswa janm yo — pase si ou pa pran l. Plis nou bay li vit, plis chans pou yon bon rezilta."
                ]
            ),
            ConsentSection(
                id: "risk",
                systemImage: "drop.triangle.fill",
                heading: "The main risk: bleeding",
                texts: [
                    .english:  "The most important risk is bleeding. About 2 to 6 out of 100 patients can have a serious bleed in the brain that may cause more disability or, rarely, death. About 1 to 5 out of 100 may have swelling of the lips, tongue, or throat (angioedema). There can also be bleeding from the gums, IV sites, stomach, or urine.",
                    .spanish:  "El riesgo más importante es sangrado. Aproximadamente 2 a 6 de cada 100 pacientes pueden tener un sangrado serio en el cerebro, lo que puede causar más discapacidad o, raramente, la muerte. Aproximadamente 1 a 5 de cada 100 pueden tener inflamación de los labios, la lengua o la garganta (angioedema). También puede haber sangrado en las encías, sitios de IV, estómago u orina.",
                    .haitianCreole: "Risk ki pi enpòtan an se senyman. Apeprè 2 a 6 sou 100 pasyan ka gen yon gwo senyman nan sèvo a ki ka koze plis enfimite oswa, raman, lanmò. Apeprè 1 a 5 sou 100 ka gen anflamasyon nan lèv, lang, oswa goj la (angioedèm). Gen moun ki ka senyen nan jansiv, kote IV a, vant, oswa pipi."
                ]
            ),
            ConsentSection(
                id: "without",
                systemImage: "xmark.octagon.fill",
                heading: "Without the medicine",
                texts: [
                    .english:  "Without this medicine, the stroke may continue to damage the brain. The outcome could be worse — including weakness, trouble speaking, trouble walking, or other long-lasting disability.",
                    .spanish:  "Sin este medicamento, el derrame puede seguir dañando el cerebro. El resultado podría ser peor — incluyendo debilidad, problemas para hablar, dificultad para caminar u otras discapacidades duraderas.",
                    .haitianCreole: "San medikaman sa a, AVC a ka kontinye domaje sèvo a. Rezilta yo ka pi mal — tankou febles, pwoblèm pou pale, pwoblèm pou mache, oswa lòt enfimite ki dire lontan."
                ]
            ),
            ConsentSection(
                id: "ask",
                systemImage: "questionmark.bubble.fill",
                heading: "Questions and decision",
                texts: [
                    .english:  "Time is brain — every minute that passes, more brain cells are lost. Do you or the family have any questions? Do you agree for us to give this treatment?",
                    .spanish:  "El tiempo es cerebro — cada minuto que pasa, perdemos más células del cerebro. ¿Tiene usted o la familia alguna pregunta? ¿Está de acuerdo en que demos este tratamiento?",
                    .haitianCreole: "Tan se sèvo — chak minit ki pase, plis selil sèvo nou pèdi. Èske ou menm oswa fanmi an gen kesyon? Èske ou dakò pou nou bay tretman sa a?"
                ]
            )
        ]
    }
}
