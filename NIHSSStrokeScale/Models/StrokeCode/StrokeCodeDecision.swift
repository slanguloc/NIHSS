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

/// Occlusion site granularity (when LVO is present). Drives the per-site
/// EVT evidence class shown to the trainee. Training only.
enum LvoSite: String, Codable, CaseIterable, Equatable {
    case unknown
    case icaTerminus
    case m1
    case m2
    case m3
    case basilar
    case pca
    case aca
    case tandem
    case other

    var label: String {
        switch self {
        case .unknown:      return "Site not specified"
        case .icaTerminus:  return "ICA terminus"
        case .m1:           return "MCA – M1"
        case .m2:           return "MCA – M2"
        case .m3:           return "MCA – M3 / distal"
        case .basilar:      return "Basilar artery"
        case .pca:          return "PCA"
        case .aca:          return "ACA"
        case .tandem:       return "Tandem (cervical ICA + intracranial)"
        case .other:        return "Other / VA"
        }
    }

    /// AHA/ASA-style evidence class for EVT at this site (training-only
    /// summary; the 2026 guideline elevated several class-IIb items).
    var evidenceClass: EvtEvidenceClass {
        switch self {
        case .icaTerminus, .m1, .basilar, .tandem: return .classI
        case .m2:                                   return .classIIa
        case .m3, .pca:                             return .classIIb
        case .aca, .other:                          return .insufficient
        case .unknown:                              return .notSpecified
        }
    }

    /// One-line training note tailored to the site.
    var trainingNote: String {
        switch self {
        case .unknown:
            return "Specify the occlusion site to see the corresponding EVT evidence class."
        case .icaTerminus:
            return "ICA-terminus occlusion — strong EVT indication (HERMES, Class I)."
        case .m1:
            return "M1 occlusion — strongest evidence base for EVT (HERMES, Class I)."
        case .m2:
            return "M2 occlusion — EVT is reasonable, especially for proximal / dominant M2 with disabling deficit (Class IIa)."
        case .m3:
            return "M3 / distal MeVO — EVT may be considered (Class IIb). Recent trials (ESCAPE-MeVO, DISTAL, DISCOUNT) showed mixed benefit; weigh risks."
        case .basilar:
            return "Basilar occlusion — EVT improves outcomes within 24 h in selected patients (BAOCHE, ATTENTION). Use NIHSS ≥ 10 threshold."
        case .pca:
            return "Posterior cerebral artery — emerging evidence; EVT may be considered for disabling deficits (Class IIb)."
        case .aca:
            return "Anterior cerebral artery — insufficient RCT data; individualize."
        case .tandem:
            return "Tandem cervical ICA + intracranial — EVT reasonable; acute cervical stenting decision is individualized."
        case .other:
            return "Other / VA occlusion — insufficient evidence base; individualize via stroke / neuro-IR consult."
        }
    }
}

/// Evidence-class badge used to communicate the strength of recommendation
/// for EVT at the captured occlusion site. Training-only.
enum EvtEvidenceClass: String, Codable, Equatable {
    case classI
    case classIIa
    case classIIb
    case insufficient
    case notSpecified

    var label: String {
        switch self {
        case .classI:        return "Class I"
        case .classIIa:      return "Class IIa"
        case .classIIb:      return "Class IIb"
        case .insufficient:  return "Insufficient evidence"
        case .notSpecified:  return "—"
        }
    }
}

/// Pre-stroke baseline functional status (modified Rankin Scale buckets).
/// Used to surface EVT candidacy nuance per 2026 AHA/ASA.
enum BaselineMRS: String, Codable, CaseIterable, Equatable {
    case unknown
    case mrs0_1
    case mrs2
    case mrs3plus

    var label: String {
        switch self {
        case .unknown:  return "Not captured"
        case .mrs0_1:   return "mRS 0–1 (independent)"
        case .mrs2:     return "mRS 2 (slight disability)"
        case .mrs3plus: return "mRS ≥ 3 (moderate or worse)"
        }
    }

    var evtNote: String {
        switch self {
        case .unknown:
            return "Capture baseline mRS to refine EVT candidacy."
        case .mrs0_1:
            return "Standard EVT candidacy (independent at baseline)."
        case .mrs2:
            return "EVT reasonable in selected patients (Class IIa/IIb per 2026 update). Weigh ASCVD burden and goals of care."
        case .mrs3plus:
            return "EVT generally NOT recommended outside select cases / shared decision-making. Discuss goals of care."
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

    /// Trial labels for toggles the trainee marked as met (EVT 6–24 h section).
    var evtTrialLabelsMet: [String] {
        var labels: [String] = []
        if dawnMismatch { labels.append("DAWN") }
        if defuse3Mismatch { labels.append("DEFUSE-3") }
        if largeCoreEvtCandidate { labels.append("Large-core (SELECT2-type)") }
        return labels
    }

    var evtExtendedCriteriaSelected: Bool {
        dawnMismatch || defuse3Mismatch || largeCoreEvtCandidate
    }
}

// MARK: - Aggregated state per session

/// All decision-support answers for a single session. Stored on the
/// `StrokeCodeSession` as an optional field for backward compatibility.
struct DecisionState: Codable, Equatable {
    var imagingResult: ImagingResult = .pending
    var lvoStatus: LvoStatus = .unknown

    /// Occlusion site granularity when LVO is present. Optional for
    /// backward compatibility with older saves; treated as `.unknown`
    /// when nil. Used to surface site-specific EVT evidence class.
    var lvoSite: LvoSite? = nil

    /// Pre-stroke baseline functional status (mRS bucket). Optional for
    /// backward compatibility with older saves; treated as `.unknown`
    /// when nil. Used to surface EVT candidacy nuance.
    var baselineMRS: BaselineMRS? = nil

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

    /// True when the extended-window summary supports considering late-window EVT.
    var suggestsEVTDiscussion: Bool {
        switch self {
        case .evtCandidate, .bothCandidate: return true
        default: return false
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
            helpText: "Auto-filled from Last known well on the Timeline when still unanswered. Standard window ≤4.5 h; 4.5–9 h requires Extended window imaging criteria (WAKE-UP / EXTEND). You may override Yes/No.",
            polarity: .mustBeYes,
            group: "Required"
        ),
        DecisionCriterion(
            id: "ivt.noHemorrhage",
            label: "Hemorrhage ruled out on non-contrast head CT",
            helpText: "Answer Yes if NCCT shows no intracranial hemorrhage. Answer No if hemorrhage is present, findings are equivocal, or the scan is not yet read. Hemorrhage excludes IV thrombolysis (see imaging branch above).",
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

    /// Manual EVT checklist items only for data **not** captured elsewhere
    /// (LVO status, LKW/extended window, ASPECTS, baseline mRS, NIHSS total).
    static let evtManual: [DecisionCriterion] = [
        DecisionCriterion(
            id: "evt.adultPathway",
            label: "Age ≥ 18 (adult pathway)",
            helpText: "Adult EVT pathway. For patients under 18, consult a pediatric stroke team per 2026 AHA/ASA guidance.",
            polarity: .mustBeYes,
            group: "Confirm"
        ),
        DecisionCriterion(
            id: "evt.disablingDeficit",
            label: "Disabling neurologic deficit on exam",
            helpText: "Shown when NIHSS total is not captured. Typically NIHSS ≥6 (≥10 for basilar LVO).",
            polarity: .mustBeYes,
            group: "Confirm"
        )
    ]

    /// Legacy alias — use `evtManual` plus structured EVT assessment in `DecisionState`.
    static var evt: [DecisionCriterion] { evtManual }
}

// MARK: - EVT structured assessment (training)

/// One row in the EVT “captured from workflow” summary (not a duplicate
/// yes/no question — derived from LVO, LKW, ASPECTS, etc.).
struct EvtStructuredCriterion: Identifiable, Equatable {
    let id: String
    let label: String
    let detail: String
    /// `nil` = still needs input elsewhere in the workflow.
    let isMet: Bool?
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

    /// Training assessment of IV thrombolysis time window from LKW and,
    /// when applicable, extended-window imaging toggles.
    func ivtTimeWindowAssessment(minutesSinceLKW: Double?) -> (met: Bool?, detail: String) {
        guard let mins = minutesSinceLKW else {
            return (nil, "Capture Last known well on the Timeline tab.")
        }
        let elapsed = Self.formatMinutesSinceLKW(mins)
        if mins < 0 {
            return (false, "LKW is in the future (\(elapsed)) — verify timing.")
        }
        if mins <= 270 {
            return (true, "\(elapsed) since LKW — within standard IV window (≤4.5 h).")
        }
        if mins <= 540 {
            let ew = extendedWindow ?? .empty
            let extendedMet = ew.advancedImagingDone &&
                (ew.dwiFlairMismatch || ew.perfusionMismatchIvt)
            if extendedMet {
                return (true, "\(elapsed) since LKW — extended IV window (4.5–9 h) with imaging selection documented.")
            }
            return (false, "\(elapsed) since LKW — past 4.5 h; mark WAKE-UP / EXTEND criteria on Extended window card if eligible.")
        }
        return (false, "\(elapsed) since LKW — beyond IV thrombolysis windows (>9 h).")
    }

    /// Sets `ivt.windowLKW45h` from LKW timing. Only fills when still unknown.
    mutating func applyIVTTimeWindowFromLKW(minutesSinceLKW: Double?) {
        let assessment = ivtTimeWindowAssessment(minutesSinceLKW: minutesSinceLKW)
        guard let met = assessment.met else { return }
        let current = ivtCriteria["ivt.windowLKW45h"] ?? .unknown
        guard current == .unknown else { return }
        ivtCriteria["ivt.windowLKW45h"] = met ? .yes : .no
    }

    private static func formatMinutesSinceLKW(_ totalMins: Double) -> String {
        let m = max(0, Int(totalMins.rounded()))
        let h = m / 60
        let r = m % 60
        return h > 0 ? String(format: "%dh %02dm", h, r) : String(format: "%d min", r)
    }

    /// Rows derived from data entered on other decision cards (not re-asked
    /// as yes/no checklist items).
    func evtStructuredCriteria(minutesSinceLKW: Double?) -> [EvtStructuredCriterion] {
        var rows: [EvtStructuredCriterion] = []

        switch lvoStatus {
        case .present:
            rows.append(EvtStructuredCriterion(
                id: "lvo",
                label: "LVO confirmed",
                detail: "Set on vascular imaging card.",
                isMet: true
            ))
        case .absent:
            rows.append(EvtStructuredCriterion(
                id: "lvo",
                label: "LVO confirmed",
                detail: "No LVO — EVT not indicated.",
                isMet: false
            ))
        case .unknown:
            rows.append(EvtStructuredCriterion(
                id: "lvo",
                label: "LVO confirmed",
                detail: "Set LVO status on vascular imaging card.",
                isMet: nil
            ))
        }

        if let mins = minutesSinceLKW {
            if mins <= 360 {
                rows.append(EvtStructuredCriterion(
                    id: "window",
                    label: "Treatment time window",
                    detail: "Within standard EVT window (≤6 h from LKW).",
                    isMet: true
                ))
            } else if mins <= 1440 {
                let ew = extendedWindow ?? .empty
                let met = suggestsExtendedWindowEVT(minutesSinceLKW: mins)
                let trialDetail = ew.evtTrialLabelsMet.isEmpty
                    ? "Complete Extended window card: advanced imaging + DAWN / DEFUSE-3 / large-core criteria."
                    : "Extended window: " + ew.evtTrialLabelsMet.joined(separator: ", ")
                rows.append(EvtStructuredCriterion(
                    id: "window",
                    label: "Treatment time window",
                    detail: met ? "6–24 h with imaging selection — \(trialDetail)." : "6–24 h — imaging selection not yet documented (\(trialDetail)).",
                    isMet: met
                ))
            } else {
                rows.append(EvtStructuredCriterion(
                    id: "window",
                    label: "Treatment time window",
                    detail: "Beyond 24 h from LKW — outside conventional EVT windows.",
                    isMet: false
                ))
            }
        } else {
            rows.append(EvtStructuredCriterion(
                id: "window",
                label: "Treatment time window",
                detail: "Capture Last known well on Timeline tab.",
                isMet: nil
            ))
        }

        if let score = aspectsScore {
            let ew = extendedWindow ?? .empty
            if score >= 6 {
                rows.append(EvtStructuredCriterion(
                    id: "core",
                    label: "Infarct core / ASPECTS",
                    detail: "ASPECTS \(score)/10 — favorable for standard EVT.",
                    isMet: true
                ))
            } else if (3...5).contains(score) {
                rows.append(EvtStructuredCriterion(
                    id: "core",
                    label: "Infarct core / ASPECTS",
                    detail: ew.largeCoreEvtCandidate
                        ? "ASPECTS \(score)/10 — large-core pathway documented (Extended window card)."
                        : "ASPECTS \(score)/10 — mark large-core eligibility on Extended window card if applicable.",
                    isMet: ew.largeCoreEvtCandidate
                ))
            } else {
                rows.append(EvtStructuredCriterion(
                    id: "core",
                    label: "Infarct core / ASPECTS",
                    detail: "ASPECTS \(score)/10 — extensive core; EVT generally not recommended outside trials.",
                    isMet: false
                ))
            }
        } else {
            rows.append(EvtStructuredCriterion(
                id: "core",
                label: "Infarct core / ASPECTS",
                detail: "Set ASPECTS in Patient details.",
                isMet: nil
            ))
        }

        switch baselineMRS ?? .unknown {
        case .mrs0_1:
            rows.append(EvtStructuredCriterion(
                id: "mrs",
                label: "Baseline function",
                detail: "mRS 0–1 — standard EVT candidacy.",
                isMet: true
            ))
        case .mrs2:
            rows.append(EvtStructuredCriterion(
                id: "mrs",
                label: "Baseline function",
                detail: "mRS 2 — EVT reasonable in selected patients; individualize.",
                isMet: true
            ))
        case .mrs3plus:
            rows.append(EvtStructuredCriterion(
                id: "mrs",
                label: "Baseline function",
                detail: "mRS ≥3 — EVT generally not recommended; discuss goals of care.",
                isMet: false
            ))
        case .unknown:
            rows.append(EvtStructuredCriterion(
                id: "mrs",
                label: "Baseline function",
                detail: "Select baseline mRS below.",
                isMet: nil
            ))
        }

        if let nihss = nihssTotal {
            let basilar = (lvoSite ?? .unknown) == .basilar
            let threshold = basilar ? 10 : 6
            let met = nihss >= threshold
            rows.append(EvtStructuredCriterion(
                id: "nihss",
                label: "Deficit severity (NIHSS)",
                detail: "NIHSS \(nihss) — threshold ≥\(threshold)\(basilar ? " (basilar)" : "").",
                isMet: met
            ))
        }

        return rows
    }

    /// Manual EVT checklist items to show (e.g. hide NIHSS question when total captured).
    func evtManualCriteriaForDisplay() -> [DecisionCriterion] {
        StrokeCodeDecisionCatalog.evtManual.filter { c in
            if c.id == "evt.disablingDeficit" { return nihssTotal == nil }
            return true
        }
    }

    /// EVT verdict: structured workflow data + small manual confirm list.
    func evtVerdict(minutesSinceLKW: Double? = nil) -> CandidacyVerdict {
        var failedRequired: [String] = []
        var missing = 0

        for row in evtStructuredCriteria(minutesSinceLKW: minutesSinceLKW) {
            switch row.isMet {
            case .some(false): failedRequired.append(row.label)
            case .none: missing += 1
            case .some(true): break
            }
        }

        for c in evtManualCriteriaForDisplay() {
            let answer = evtCriteria[c.id] ?? .unknown
            switch answer {
            case .unknown: missing += 1
            case .no: failedRequired.append(c.label)
            case .yes: break
            }
        }

        if !failedRequired.isEmpty {
            return .ineligibleRequired(failed: failedRequired)
        }
        if missing > 0 {
            return .incomplete(missing: missing)
        }
        return .eligible
    }

    /// Extended-window training verdict from LKW time and imaging toggles.
    func extendedWindowVerdict(minutesSinceLKW: Double?) -> ExtendedWindowVerdict {
        (extendedWindow ?? .empty).verdict(minutesSinceLKW: minutesSinceLKW)
    }

    /// True when LKW is 6–24 h, advanced imaging is done, and at least one
    /// late-window EVT trial criterion is toggled on.
    func suggestsExtendedWindowEVT(minutesSinceLKW: Double?) -> Bool {
        extendedWindowVerdict(minutesSinceLKW: minutesSinceLKW).suggestsEVTDiscussion
    }

    /// No-op: EVT checklist items are derived from structured workflow data.
    mutating func applyExtendedWindowEVTChecklistHints(minutesSinceLKW: Double?) {
        _ = minutesSinceLKW
    }
}
