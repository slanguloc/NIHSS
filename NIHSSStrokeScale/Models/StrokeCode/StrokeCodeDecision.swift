//
//  StrokeCodeDecision.swift
//  Zysquy — Decision-support catalog and state for the Stroke Code Timer
//  (education/training only).
//
//  Encodes the high-yield decision branches in an acute ischemic stroke
//  workflow as a training walkthrough:
//    1. Imaging branch (hemorrhagic vs. ischemic vs. pending)
//    2. IV thrombolysis (alteplase / tenecteplase) eligibility
//    3. LVO assessment from vascular imaging
//    4. Endovascular thrombectomy (EVT) eligibility
//
//  Each criterion has a clear "must be yes" or "must be no" polarity, an
//  educational help text, and is captured per session. The Decision view
//  derives a training-only suggestion from the answers and displays it
//  alongside an education-only banner. Not a medical device. Not for
//  clinical decisions.
//

import Foundation

// MARK: - Answer types

/// Tri-state answer for a yes/no decision criterion.
enum DecisionAnswer: String, Codable, CaseIterable, Equatable {
    case unknown
    case yes
    case no
}

/// Whether a criterion must be `yes` (required) or `no` (exclusion) to
/// support candidacy for the parent decision.
enum CriterionPolarity: String, Codable, Equatable {
    /// Criterion must be `yes` for candidacy (e.g., "within window").
    case mustBeYes
    /// Criterion must be `no` for candidacy (e.g., "active bleeding").
    case mustBeNo
}

/// One yes/no checklist item.
struct DecisionCriterion: Identifiable, Codable, Equatable {
    let id: String
    let label: String
    let helpText: String
    let polarity: CriterionPolarity
    /// Optional grouping label for UI sections (e.g., "Required", "Exclusion").
    let group: String
}

// MARK: - Branch / state enums

/// Non-contrast head CT result branch.
enum ImagingResult: String, Codable, CaseIterable, Equatable {
    case pending
    case ischemic
    case hemorrhagic
    case equivocal

    var label: String {
        switch self {
        case .pending: return "Pending / not yet read"
        case .ischemic: return "Ischemic (no hemorrhage)"
        case .hemorrhagic: return "Hemorrhage present"
        case .equivocal: return "Equivocal / atypical findings"
        }
    }
}

/// Vascular imaging (CTA / MRA) result.
enum LvoStatus: String, Codable, CaseIterable, Equatable {
    case unknown
    case present
    case absent

    var label: String {
        switch self {
        case .unknown: return "Unknown / pending"
        case .present: return "LVO present"
        case .absent: return "No LVO"
        }
    }
}

/// Captured thrombolytic choice (training).
enum ThrombolyticChoice: String, Codable, CaseIterable, Equatable {
    case undecided
    case alteplase
    case tenecteplase
    case deferred
    case declined

    var label: String {
        switch self {
        case .undecided: return "Undecided"
        case .alteplase: return "IV alteplase"
        case .tenecteplase: return "IV tenecteplase"
        case .deferred: return "Deferred (extended window / imaging)"
        case .declined: return "Not given"
        }
    }
}

/// Captured EVT choice (training).
enum EvtChoice: String, Codable, CaseIterable, Equatable {
    case undecided
    case planned
    case deferred
    case declined

    var label: String {
        switch self {
        case .undecided: return "Undecided"
        case .planned: return "EVT planned / transferring"
        case .deferred: return "Deferred (awaiting imaging)"
        case .declined: return "Not pursuing EVT"
        }
    }
}

// MARK: - Weight unit (display/entry)

/// User-facing weight unit. Storage on `DecisionState.weightKg` is always in
/// kilograms (canonical for thrombolytic dosing); this enum is only used for
/// display and direct entry.
enum WeightUnit: String, CaseIterable, Identifiable {
    case kilograms = "kg"
    case pounds = "lb"

    var id: String { rawValue }

    var label: String { rawValue }
    var verbose: String {
        switch self {
        case .kilograms: return "kilograms (kg)"
        case .pounds:    return "pounds (lb)"
        }
    }

    /// 1 kg = 2.20462 lb. We convert with rounding to the nearest integer.
    private static let kgPerLb: Double = 0.45359237
    private static let lbPerKg: Double = 2.20462

    /// Converts the canonical kg value to this unit (rounded to int).
    func displayedValue(forKg kg: Int) -> Int {
        switch self {
        case .kilograms: return kg
        case .pounds:    return Int((Double(kg) * Self.lbPerKg).rounded())
        }
    }

    /// Converts an integer entered in this unit back to canonical kg
    /// (rounded to nearest kg).
    func kgValue(fromDisplayed value: Int) -> Int {
        switch self {
        case .kilograms: return value
        case .pounds:    return Int((Double(value) * Self.kgPerLb).rounded())
        }
    }

    /// Stepper / range bounds in this unit, equivalent to 30–250 kg.
    var range: ClosedRange<Int> {
        switch self {
        case .kilograms: return 30...250
        case .pounds:    return 66...551
        }
    }
}

// MARK: - 3–4.5 h IV thrombolysis (extended early window, ECASS-3)

/// Captures the trainee's responses for the additional ECASS-3 exclusion
/// criteria applicable in the 3–4.5 h IV thrombolysis window, plus the
/// AHA/ASA 2018/2019 (reaffirmed in subsequent updates) clarifications
/// that relaxed several of them. Educational only.
struct ExtendedEarlyIvtState: Codable, Equatable {
    var ageOver80: Bool = false
    var nihssOver25: Bool = false
    var priorStrokeAndDiabetes: Bool = false
    var anticoagNOACwithin48h: Bool = false
    var anticoagWarfarinINRover1_7: Bool = false

    static let empty = ExtendedEarlyIvtState()
}

/// Verdict for the 3–4.5 h IVT additional-criteria card.
enum ExtendedEarlyIvtVerdict: Equatable {
    case notInWindow
    case noAdditionalConcerns
    case relativeCautions(reasons: [String])
    case hardContraindication(reasons: [String])

    var label: String {
        switch self {
        case .notInWindow:             return "Not in 3–4.5 h window"
        case .noAdditionalConcerns:    return "No additional 3–4.5 h exclusions captured"
        case .relativeCautions:        return "Relative cautions (per 2024 AHA/ASA, IIb)"
        case .hardContraindication:    return "Hard contraindication captured"
        }
    }
}

extension ExtendedEarlyIvtState {
    /// Returns the training verdict for the 3–4.5 h window. The window is
    /// `minutesSinceLKW` in [180, 270].
    func verdict(minutesSinceLKW: Double?) -> ExtendedEarlyIvtVerdict {
        guard let mins = minutesSinceLKW, mins >= 180.0, mins <= 270.0 else {
            return .notInWindow
        }

        var hard: [String] = []
        if anticoagNOACwithin48h {
            hard.append("NOAC within 48 h without documented normal labs")
        }
        if anticoagWarfarinINRover1_7 {
            hard.append("Warfarin with INR > 1.7")
        }
        if !hard.isEmpty {
            return .hardContraindication(reasons: hard)
        }

        var cautions: [String] = []
        if ageOver80 { cautions.append("Age > 80 (Class IIb — alteplase reasonable)") }
        if nihssOver25 { cautions.append("NIHSS > 25 (Class IIb — alteplase may be considered)") }
        if priorStrokeAndDiabetes {
            cautions.append("Prior stroke + diabetes (Class IIb — alteplase reasonable)")
        }

        return cautions.isEmpty ? .noAdditionalConcerns : .relativeCautions(reasons: cautions)
    }
}

// MARK: - Extended-window eligibility (training)

/// Captures the trainee's responses for late-window thrombolysis and EVT
/// eligibility criteria (WAKE-UP, EXTEND, DAWN, DEFUSE-3, SELECT2 / RESCUE /
/// ANGEL-ASPECT). All flags default to `false`. Used by `DecisionState` to
/// generate training-only suggestions; not a clinical decision tool.
struct ExtendedWindowState: Codable, Equatable {
    /// Advanced imaging (MRI DWI/FLAIR or CT/MR perfusion) was performed.
    var advancedImagingDone: Bool = false

    // IV thrombolysis (4.5–9 h or wake-up stroke)
    /// DWI-FLAIR mismatch present (WAKE-UP).
    var dwiFlairMismatch: Bool = false
    /// CTP/MRP mismatch with small core (EXTEND / EPITHET).
    var perfusionMismatchIvt: Bool = false

    // Endovascular thrombectomy (6–24 h)
    /// DAWN clinical-core mismatch met.
    var dawnMismatch: Bool = false
    /// DEFUSE-3 imaging mismatch met (core < 70 mL, ratio ≥ 1.8, mismatch ≥ 15 mL).
    var defuse3Mismatch: Bool = false
    /// Large-core EVT candidate per SELECT2 / RESCUE-Japan LIMIT / ANGEL-ASPECT
    /// (ASPECTS 3–5 with otherwise favorable profile).
    var largeCoreEvtCandidate: Bool = false

    static let empty = ExtendedWindowState()
}

// MARK: - Aggregated state per session

/// All decision-support answers for a single session. Stored on the
/// `StrokeCodeSession` as an optional field for backward compatibility.
struct DecisionState: Codable, Equatable {
    var imagingResult: ImagingResult = .pending
    var lvoStatus: LvoStatus = .unknown

    /// Criterion id → answer, for IV thrombolysis checklist.
    var ivtCriteria: [String: DecisionAnswer] = [:]
    /// Criterion id → answer, for EVT checklist.
    var evtCriteria: [String: DecisionAnswer] = [:]

    var thrombolyticChosen: ThrombolyticChoice = .undecided
    var evtChosen: EvtChoice = .undecided

    /// Patient weight in kilograms used for thrombolytic dose calculation.
    /// Optional for backward compatibility with older saved sessions.
    var weightKg: Int? = nil

    /// NIHSS total captured during the stroke code (e.g., via the inline
    /// NIHSS launcher). Optional for backward compatibility.
    var nihssTotal: Int? = nil

    /// ASPECTS score (Alberta Stroke Program Early CT Score), 0–10. `nil`
    /// means not assessed. Optional for backward compatibility.
    var aspectsScore: Int? = nil

    /// Extended-window (late presentation / wake-up) eligibility responses.
    /// Optional decoded value for backward compatibility with older saves;
    /// always normalized to a non-nil struct on read.
    var extendedWindow: ExtendedWindowState? = nil

    /// 3–4.5 h IV thrombolysis additional-criteria responses (ECASS-3 +
    /// 2018/2019 AHA/ASA relaxations). Optional for backward compatibility.
    var extendedEarlyIvt: ExtendedEarlyIvtState? = nil

    /// Free-text decision-pane notes (kept local-only, encrypted on disk).
    var notes: String = ""

    static let empty = DecisionState()
}

// MARK: - Thrombolytic dosing (training)

/// Computed thrombolytic dose for a given patient weight (training-only).
/// References standard published doses; see SOURCES.md.
struct ThrombolyticDose: Equatable {
    let drug: ThrombolyticChoice
    let weightKg: Int
    /// Total drug dose in mg.
    let totalMg: Double
    /// True if the weight-based dose was capped at the drug's maximum.
    let cappedAtMax: Bool
    /// For alteplase: 10% bolus over 1 minute (mg). nil for TNK.
    let bolusMg: Double?
    /// For alteplase: 90% infused over 60 minutes (mg). nil for TNK.
    let infusionMg: Double?

    /// Standard dose label (e.g., "0.25 mg/kg, max 25 mg").
    var standardDoseLabel: String {
        switch drug {
        case .alteplase: return "0.9 mg/kg, max 90 mg"
        case .tenecteplase: return "0.25 mg/kg, max 25 mg"
        default: return ""
        }
    }

    /// Short administration summary.
    var administrationSummary: String {
        switch drug {
        case .alteplase:
            return "10% as IV bolus over 1 min, then the remaining 90% as IV infusion over 60 min."
        case .tenecteplase:
            return "Single IV bolus over ~5 seconds. No infusion required."
        default:
            return ""
        }
    }

    /// Post-treatment monitoring bullets (training reminders).
    static let postTreatmentBullets: [String] = [
        "Target BP ≤ 180/105 mmHg for 24 h after treatment.",
        "No antiplatelet or anticoagulant for 24 h.",
        "Neuro checks per protocol (often q15 min × 2 h, q30 min × 6 h, q1 h × 16 h).",
        "Repeat imaging at ~24 h before starting antithrombotics.",
        "Treat suspected angioedema / orolingual edema and bleeding per protocol."
    ]
}

/// Computes a thrombolytic dose for `drug` at `weightKg`. Returns nil when
/// the drug is not a thrombolytic (e.g., undecided/deferred/declined) or
/// the weight is not a positive number.
func computeThrombolyticDose(drug: ThrombolyticChoice, weightKg: Int) -> ThrombolyticDose? {
    guard weightKg > 0 else { return nil }
    let w = Double(weightKg)

    switch drug {
    case .alteplase:
        let raw = 0.9 * w
        let total = min(raw, 90.0)
        let capped = raw > 90.0
        let bolus = (total * 0.10 * 10).rounded() / 10
        let infusion = ((total - bolus) * 10).rounded() / 10
        let roundedTotal = (total * 10).rounded() / 10
        return ThrombolyticDose(drug: .alteplase,
                                weightKg: weightKg,
                                totalMg: roundedTotal,
                                cappedAtMax: capped,
                                bolusMg: bolus,
                                infusionMg: infusion)

    case .tenecteplase:
        let raw = 0.25 * w
        let total = min(raw, 25.0)
        let capped = raw > 25.0
        let roundedTotal = (total * 10).rounded() / 10
        return ThrombolyticDose(drug: .tenecteplase,
                                weightKg: weightKg,
                                totalMg: roundedTotal,
                                cappedAtMax: capped,
                                bolusMg: nil,
                                infusionMg: nil)

    case .undecided, .deferred, .declined:
        return nil
    }
}

// MARK: - ASPECTS categorization (training)

/// Training-only categorization of an ASPECTS score for EVT decision support.
/// Aligned with HERMES (classic 0–6 h, ASPECTS ≥ 6) and the 2023 large-core
/// trial cluster (SELECT2 / RESCUE-Japan LIMIT / ANGEL-ASPECT) supporting
/// EVT consideration for selected patients with ASPECTS 3–5. Educational
/// summary, not a clinical decision tool.
enum AspectsCategory: Equatable {
    case notAssessed
    case favorable        // 8–10
    case borderline       // 6–7
    case largeCore        // 3–5
    case extensiveInfarct // 0–2

    init(score: Int?) {
        guard let s = score else { self = .notAssessed; return }
        switch s {
        case 8...10: self = .favorable
        case 6...7:  self = .borderline
        case 3...5:  self = .largeCore
        case 0...2:  self = .extensiveInfarct
        default:     self = .notAssessed
        }
    }

    var label: String {
        switch self {
        case .notAssessed:      return "Not assessed"
        case .favorable:        return "Favorable (8–10)"
        case .borderline:       return "Borderline (6–7)"
        case .largeCore:        return "Large core (3–5)"
        case .extensiveInfarct: return "Extensive infarct (0–2)"
        }
    }

    var evtTrainingNote: String {
        switch self {
        case .notAssessed:
            return "Capture ASPECTS to display EVT-eligibility training notes."
        case .favorable:
            return "Standard EVT candidacy supported (HERMES). No ASPECTS-based exclusion."
        case .borderline:
            return "Borderline — verify ASPECTS with neuroradiology. Most institutions still proceed with EVT in selected patients."
        case .largeCore:
            return "EVT may be considered in selected patients per 2023 RCTs (SELECT2, RESCUE-Japan LIMIT, ANGEL-ASPECT). Weigh hemorrhagic conversion risk; involve neurology and IR."
        case .extensiveInfarct:
            return "EVT is generally NOT recommended outside of clinical trials. Continue best medical management."
        }
    }

    var ivtTrainingNote: String {
        // ASPECTS does not strictly disqualify IV thrombolysis. The relevant
        // historic IVT imaging caution is extensive early hypoattenuation
        // (>1/3 MCA territory), which broadly corresponds to very low ASPECTS.
        switch self {
        case .extensiveInfarct:
            return "Extensive early hypoattenuation (>1/3 MCA territory) is a relative IVT caution. Confirm imaging interpretation; individualize."
        default:
            return "ASPECTS does not strictly exclude IV thrombolysis. Standard inclusion/exclusion criteria apply."
        }
    }
}

// MARK: - Extended-window verdict (training)

/// Categorical outcome for the late-window training card.
enum ExtendedWindowVerdict: Equatable {
    case notApplicable   // imaging not done or LKW within standard windows
    case ivtCandidate    // IVT extended window criteria met
    case evtCandidate    // EVT extended window criteria met
    case bothCandidate   // both IVT and EVT extended candidates
    case noCriteriaMet   // imaging done but no mismatch / criteria met

    var label: String {
        switch self {
        case .notApplicable:  return "Not applicable yet"
        case .ivtCandidate:   return "IVT extended-window candidate (training)"
        case .evtCandidate:   return "EVT extended-window candidate (training)"
        case .bothCandidate:  return "IVT + EVT extended candidate (training)"
        case .noCriteriaMet:  return "No extended-window criteria currently met"
        }
    }
}

extension ExtendedWindowState {
    /// Compares time-since-LKW (minutes) to relevant windows to summarize
    /// extended-window training candidacy.
    func verdict(minutesSinceLKW: Double?) -> ExtendedWindowVerdict {
        // No LKW captured yet → nothing to evaluate.
        guard let mins = minutesSinceLKW else { return .notApplicable }

        let inIvtExtended = mins >= 270.0 && mins <= 540.0  // 4.5–9 h
        let inEvtExtended = mins > 360.0 && mins <= 1440.0  // 6–24 h
        let pastEvtExtended = mins > 1440.0

        // If both windows are already past, nothing to evaluate.
        if pastEvtExtended && !inEvtExtended && !inIvtExtended {
            return .notApplicable
        }

        let ivtMet = inIvtExtended && advancedImagingDone &&
                     (dwiFlairMismatch || perfusionMismatchIvt)
        let evtMet = inEvtExtended && advancedImagingDone &&
                     (dawnMismatch || defuse3Mismatch || largeCoreEvtCandidate)

        switch (ivtMet, evtMet) {
        case (true, true):  return .bothCandidate
        case (true, false): return .ivtCandidate
        case (false, true): return .evtCandidate
        case (false, false):
            if (inIvtExtended || inEvtExtended) && advancedImagingDone {
                return .noCriteriaMet
            }
            return .notApplicable
        }
    }
}

// MARK: - Catalogs

enum StrokeCodeDecisionCatalog {

    /// IV thrombolysis (IVT) checklist. Educational; criteria are
    /// summaries of widely published AHA/ASA inclusion/exclusion items.
    static let ivt: [DecisionCriterion] = [
        // Required (must be YES)
        DecisionCriterion(
            id: "ivt.dxIschemicStroke",
            label: "Acute ischemic stroke with measurable, disabling deficit",
            helpText: "Clinical diagnosis of ischemic stroke causing a measurable, potentially disabling neurologic deficit on exam.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "ivt.age18",
            label: "Age ≥ 18 (adult pathway)",
            helpText: "Adult thrombolysis pathway. The 2026 AHA/ASA guideline also introduces a pediatric stroke pathway; consult pediatric stroke team.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "ivt.windowLKW45h",
            label: "Within 4.5 hours of Last Known Well (or extended-window eligible)",
            helpText: "Standard IV thrombolysis window is ≤4.5h from LKW. Extended window (up to ~9h) requires advanced imaging selection per protocol.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "ivt.noHemorrhage",
            label: "Non-contrast CT shows no intracranial hemorrhage",
            helpText: "Hemorrhage on CT excludes IV thrombolysis. Imaging branch above must be 'ischemic'.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "ivt.bp185_110",
            label: "BP ≤ 185/110 mmHg before treatment",
            helpText: "Lower BP per protocol if needed before treatment. Persistent BP above this threshold is a contraindication.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "ivt.glucose50",
            label: "Glucose > 50 mg/dL (and not a pure hypoglycemia mimic)",
            helpText: "Check fingerstick glucose. Correct hypoglycemia and reassess; do not treat a hypoglycemic mimic.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "ivt.platelets100k",
            label: "Platelets ≥ 100,000/µL (or no history of thrombocytopenia)",
            helpText: "Do not delay thrombolysis waiting on labs in patients with no reason to suspect abnormal platelets.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "ivt.inr17",
            label: "INR ≤ 1.7 (or no history of anticoagulation)",
            helpText: "If on warfarin: INR must be ≤1.7. If no anticoagulant history, do not wait on coagulation labs to bolus.",
            polarity: .mustBeYes,
            group: "Required"
        ),

        // Exclusions (must be NO)
        DecisionCriterion(
            id: "ivt.activeBleeding",
            label: "Active internal bleeding",
            helpText: "Active GI / GU / other internal bleeding is an absolute contraindication.",
            polarity: .mustBeNo,
            group: "Exclusion"
        ),
        DecisionCriterion(
            id: "ivt.recentICHorStroke",
            label: "ICH, severe head trauma, or ischemic stroke within 3 months",
            helpText: "Recent intracranial hemorrhage, severe head trauma, or ischemic stroke within 3 months.",
            polarity: .mustBeNo,
            group: "Exclusion"
        ),
        DecisionCriterion(
            id: "ivt.intracranialMass",
            label: "Intracranial neoplasm / AVM / aneurysm with high hemorrhage risk",
            helpText: "Known intracranial lesions with high hemorrhage risk are contraindications.",
            polarity: .mustBeNo,
            group: "Exclusion"
        ),
        DecisionCriterion(
            id: "ivt.recentIntracranialSurgery",
            label: "Intracranial or spinal surgery within 3 months",
            helpText: "Recent intracranial or spinal surgery is a contraindication.",
            polarity: .mustBeNo,
            group: "Exclusion"
        ),
        DecisionCriterion(
            id: "ivt.giMalignancyOrBleed21d",
            label: "GI malignancy or GI bleed within 21 days",
            helpText: "Known GI malignancy or GI bleed within 21 days.",
            polarity: .mustBeNo,
            group: "Exclusion"
        ),
        DecisionCriterion(
            id: "ivt.therapeuticLmwh24h",
            label: "Therapeutic-dose LMWH within 24 h",
            helpText: "Therapeutic LMWH within 24h is a contraindication.",
            polarity: .mustBeNo,
            group: "Exclusion"
        ),
        DecisionCriterion(
            id: "ivt.doac48h",
            label: "DOAC within 48 h (with abnormal coagulation testing)",
            helpText: "DOAC within 48h with abnormal coags. Consider antidote/reversal pathway; verify per protocol.",
            polarity: .mustBeNo,
            group: "Exclusion"
        ),
        DecisionCriterion(
            id: "ivt.endocarditisOrDissection",
            label: "Suspected septic embolism / infective endocarditis / aortic dissection",
            helpText: "Suspected infective endocarditis or aortic dissection is a contraindication.",
            polarity: .mustBeNo,
            group: "Exclusion"
        )
    ]

    /// Endovascular thrombectomy (EVT) checklist. All items must be YES
    /// to suggest training-eligibility for EVT.
    static let evt: [DecisionCriterion] = [
        DecisionCriterion(
            id: "evt.lvoConfirmed",
            label: "Confirmed LVO on vascular imaging",
            helpText: "Anterior circulation: ICA terminus or M1 (M2 selected). Posterior: basilar artery. Other locations in select patients.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "evt.nihssThreshold",
            label: "NIHSS ≥ 6 (or ≥ 10 for basilar)",
            helpText: "Disabling deficit threshold. Basilar artery occlusion requires NIHSS ≥10 per 2026 AHA/ASA recommendation.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "evt.preStrokeFunction",
            label: "Acceptable pre-stroke functional status (e.g., mRS ≤ 1)",
            helpText: "Pre-stroke modified Rankin Scale typically ≤1 for standard EVT trials; institutional protocols may vary.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "evt.windowLKW",
            label: "Within 6 h of LKW (or 6–24 h with imaging selection)",
            helpText: "Standard window ≤6h; late window 6–24h requires advanced imaging (DAWN / DEFUSE-3 type criteria). The 2026 guideline endorses select patients with larger ischemic cores.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "evt.aspectsOrCore",
            label: "ASPECTS ≥ 6 (or large-core eligible per 2026 criteria)",
            helpText: "ASPECTS ≥6 on non-contrast CT, or selected larger-core patients per 2026 AHA/ASA expanded EVT recommendations.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "evt.adultPathway",
            label: "Age ≥ 18 (adult pathway)",
            helpText: "Adult EVT pathway. The 2026 AHA/ASA guideline introduces first-time pediatric stroke recommendations; consult pediatric stroke team for under-18 patients.",
            polarity: .mustBeYes,
            group: "Required"
        )
    ]
}

// MARK: - Verdict (training suggestion)

/// Aggregated training-only verdict for a candidacy pathway.
enum CandidacyVerdict: Equatable {
    case incomplete(missing: Int)
    case eligible
    case ineligibleRequired(failed: [String])
    case ineligibleExclusion(failed: [String])

    var headline: String {
        switch self {
        case .incomplete(let n):
            return "Incomplete — \(n) item(s) still unknown"
        case .eligible:
            return "Training suggestion: candidate (all criteria met)"
        case .ineligibleRequired:
            return "Training suggestion: not a candidate (required criterion not met)"
        case .ineligibleExclusion:
            return "Training suggestion: not a candidate (exclusion present)"
        }
    }

    var failedLabels: [String] {
        switch self {
        case .incomplete: return []
        case .eligible: return []
        case .ineligibleRequired(let labels): return labels
        case .ineligibleExclusion(let labels): return labels
        }
    }
}

extension DecisionState {

    /// Computes the training verdict for a checklist against the given catalog.
    func verdict(for criteria: [DecisionCriterion], answers: [String: DecisionAnswer]) -> CandidacyVerdict {
        var missing = 0
        var failedRequired: [String] = []
        var failedExclusion: [String] = []

        for c in criteria {
            let answer = answers[c.id] ?? .unknown
            switch c.polarity {
            case .mustBeYes:
                switch answer {
                case .unknown: missing += 1
                case .no: failedRequired.append(c.label)
                case .yes: break
                }
            case .mustBeNo:
                switch answer {
                case .unknown: missing += 1
                case .yes: failedExclusion.append(c.label)
                case .no: break
                }
            }
        }

        if !failedExclusion.isEmpty {
            return .ineligibleExclusion(failed: failedExclusion)
        }
        if !failedRequired.isEmpty {
            return .ineligibleRequired(failed: failedRequired)
        }
        if missing > 0 {
            return .incomplete(missing: missing)
        }
        return .eligible
    }

    /// IVT verdict from the catalog and current answers.
    func ivtVerdict() -> CandidacyVerdict {
        verdict(for: StrokeCodeDecisionCatalog.ivt, answers: ivtCriteria)
    }

    /// EVT verdict from the catalog and current answers.
    func evtVerdict() -> CandidacyVerdict {
        verdict(for: StrokeCodeDecisionCatalog.evt, answers: evtCriteria)
    }
}
