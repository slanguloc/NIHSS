//
//  StrokeCodeScenario.swift
//  Zysquy — Simulated stroke-code case bank (education/training only).
//
//  An educator picks a scenario; the trainee then runs the full timeline +
//  decision flow. The scenario sets initial anchors (LKW / EMS / Door),
//  carries a vignette, and provides revealable findings (CT, CTA, labs)
//  plus educator-facing expected decisions and teaching points used in the
//  post-session debrief. Not a medical device. Not for clinical use.
//

import Foundation

// MARK: - Scenario model

struct StrokeCodeScenario: Identifiable, Codable, Equatable {

    enum Difficulty: String, Codable, CaseIterable, Equatable {
        case easy, medium, hard
        var label: String {
            switch self {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }
    }

    struct Demographics: Codable, Equatable {
        let ageYears: Int
        let sex: String
        let weightKg: Int?
    }

    struct Vitals: Codable, Equatable {
        let bp: String
        let hr: Int
        let glucoseMgDl: Int
        let oxygenSat: Int
    }

    /// All times are relative to scenario load. nil = unknown (e.g., wake-up).
    struct Timing: Codable, Equatable {
        let lkwMinutesAgo: Int?
        let symptomDiscoveryMinutesAgo: Int?
        let emsArrivalMinutesAgo: Int?
        /// Typically 0 — patient just arrived at ED at scenario load.
        let doorMinutesAgo: Int
    }

    struct Findings: Codable, Equatable {
        let ctNonContrast: String
        let imagingResult: ImagingResult
        let aspects: Int?
        let cta: String
        let lvoStatus: LvoStatus
        let labs: String
    }

    struct Expectations: Codable, Equatable {
        let thrombolytic: ThrombolyticChoice
        let evt: EvtChoice
        let rationale: String
    }

    let id: String
    let title: String
    let difficulty: Difficulty
    let oneLiner: String
    let vignette: String
    let demographics: Demographics
    let history: [String]
    let presentingNihss: Int?
    let vitals: Vitals
    let timing: Timing
    let findings: Findings
    let expected: Expectations
    let teachingPoints: [String]
}

// MARK: - Bank

enum StrokeCodeScenarioBank {

    static let all: [StrokeCodeScenario] = [classicLvo,
                                            hemorrhagicStroke,
                                            lateWindowLvo,
                                            hypoglycemiaMimic,
                                            doacExclusion,
                                            wakeUpStroke]

    static func scenario(id: String) -> StrokeCodeScenario? {
        all.first(where: { $0.id == id })
    }

    // MARK: Individual cases

    static let classicLvo = StrokeCodeScenario(
        id: "case.classicLvo",
        title: "Classic anterior LVO within window",
        difficulty: .easy,
        oneLiner: "65F sudden L hemiparesis + global aphasia; LKW ~90 min ago",
        vignette: """
        A 65-year-old woman is brought to the ED by EMS after her spouse \
        found her unable to speak at the breakfast table approximately 90 \
        minutes ago. She had been talking to him 10 minutes earlier. On \
        arrival she is awake, follows simple commands intermittently, has a \
        dense right facial droop, dysarthria with global aphasia, and \
        marked left arm/leg weakness. EMS pre-notified your team as a \
        stroke alert.
        """,
        demographics: .init(ageYears: 65, sex: "F", weightKg: 78),
        history: [
            "HTN, HLD",
            "Aspirin 81 mg daily",
            "No anticoagulants",
            "No recent surgery or bleeding"
        ],
        presentingNihss: 16,
        vitals: .init(bp: "168/92", hr: 88, glucoseMgDl: 118, oxygenSat: 97),
        timing: .init(lkwMinutesAgo: 90,
                      symptomDiscoveryMinutesAgo: 85,
                      emsArrivalMinutesAgo: 60,
                      doorMinutesAgo: 0),
        findings: .init(
            ctNonContrast: "No intracranial hemorrhage. Early ischemic changes in right MCA territory. ASPECTS 9.",
            imagingResult: .ischemic,
            aspects: 9,
            cta: "Right M1 segment occlusion. Patent ICA. Good collaterals.",
            lvoStatus: .present,
            labs: "Glucose 118 mg/dL, INR 1.0, Plt 230k, Cr 0.8."
        ),
        expected: .init(
            thrombolytic: .tenecteplase,
            evt: .planned,
            rationale: "Disabling deficit, within 4.5h IV window, confirmed M1 LVO with ASPECTS 9 — candidate for IV thrombolytic and EVT (bridging)."
        ),
        teachingPoints: [
            "Time targets: door-to-CT ≤25 min, door-to-needle ≤45–60 min, door-to-puncture ≤90 min.",
            "Tenecteplase is endorsed alongside alteplase in the 2026 guideline for the 4.5h window.",
            "Do not delay bolus waiting on non-essential labs when history is reassuring.",
            "Activate EVT pathway in parallel with thrombolysis."
        ]
    )

    static let hemorrhagicStroke = StrokeCodeScenario(
        id: "case.hemorrhagic",
        title: "Hemorrhagic stroke",
        difficulty: .easy,
        oneLiner: "72M sudden severe headache, R hemiplegia, depressed LOC",
        vignette: """
        A 72-year-old man with longstanding hypertension is brought in by \
        family ~40 minutes after sudden severe headache, vomiting, and \
        right-sided weakness with progressive lethargy. He is somnolent but \
        arousable. Right face/arm/leg are plegic. Eyes deviate to the left.
        """,
        demographics: .init(ageYears: 72, sex: "M", weightKg: 90),
        history: [
            "HTN (poorly controlled)",
            "Smoker",
            "No anticoagulants"
        ],
        presentingNihss: 22,
        vitals: .init(bp: "215/118", hr: 96, glucoseMgDl: 142, oxygenSat: 95),
        timing: .init(lkwMinutesAgo: 40,
                      symptomDiscoveryMinutesAgo: 35,
                      emsArrivalMinutesAgo: 20,
                      doorMinutesAgo: 0),
        findings: .init(
            ctNonContrast: "Large left basal ganglia hemorrhage ~30 mL with intraventricular extension. Midline shift 4 mm.",
            imagingResult: .hemorrhagic,
            aspects: nil,
            cta: "No active extravasation. No underlying vascular malformation identified on CTA.",
            lvoStatus: .absent,
            labs: "Glucose 142 mg/dL, INR 1.1, Plt 215k."
        ),
        expected: .init(
            thrombolytic: .declined,
            evt: .declined,
            rationale: "ICH on CT is an absolute contraindication to IV thrombolysis. Manage as hemorrhagic stroke (BP control, neurosurgery consult)."
        ),
        teachingPoints: [
            "If CT shows hemorrhage, halt the thrombolysis pathway immediately.",
            "Target SBP per institutional ICH protocol (often 130–150 mmHg).",
            "Reverse anticoagulation if applicable.",
            "Consult neurosurgery; consider repeat imaging for expansion."
        ]
    )

    static let lateWindowLvo = StrokeCodeScenario(
        id: "case.lateWindowLvo",
        title: "Late-window LVO with imaging mismatch",
        difficulty: .hard,
        oneLiner: "58F awoke with R weakness; LKW ~9 h ago",
        vignette: """
        A 58-year-old woman awoke at 7:00 AM unable to use her right arm \
        and slurring her words. She was last seen well by her partner at \
        ~10:00 PM the night before. EMS brings her in mid-morning, ~9 \
        hours after her last known well time. She is awake, with right \
        face/arm weakness and expressive aphasia.
        """,
        demographics: .init(ageYears: 58, sex: "F", weightKg: 70),
        history: [
            "Atrial fibrillation (not anticoagulated)",
            "HTN",
            "No prior stroke or bleeding"
        ],
        presentingNihss: 14,
        vitals: .init(bp: "158/90", hr: 92, glucoseMgDl: 110, oxygenSat: 98),
        timing: .init(lkwMinutesAgo: 540,
                      symptomDiscoveryMinutesAgo: 180,
                      emsArrivalMinutesAgo: 60,
                      doorMinutesAgo: 0),
        findings: .init(
            ctNonContrast: "No hemorrhage. Subtle early ischemic changes in left insula. ASPECTS 7.",
            imagingResult: .ischemic,
            aspects: 7,
            cta: "Left M1 occlusion. Robust pial collaterals.",
            lvoStatus: .present,
            labs: "Glucose 110 mg/dL, INR 1.0, Plt 240k. CTP: small core, large penumbra (favorable mismatch)."
        ),
        expected: .init(
            thrombolytic: .deferred,
            evt: .planned,
            rationale: "Beyond 4.5 h IV window. EVT candidate by late-window imaging selection criteria (DAWN/DEFUSE-3 type), with expanded core eligibility per 2026 guideline."
        ),
        teachingPoints: [
            "Beyond 4.5 h LKW: IV thrombolysis usually deferred unless extended-window imaging criteria are met.",
            "Late-window EVT (6–24 h) requires CTP / MR DWI imaging selection.",
            "The 2026 guideline expanded EVT to select patients with larger ischemic cores.",
            "Track door-to-puncture target ≤90 min even in late-window patients."
        ]
    )

    static let hypoglycemiaMimic = StrokeCodeScenario(
        id: "case.hypoglycemiaMimic",
        title: "Stroke mimic — hypoglycemia",
        difficulty: .medium,
        oneLiner: "77M diabetic with confusion + dysarthria; LKW 30 min ago",
        vignette: """
        A 77-year-old man with type 2 diabetes is brought in by his \
        daughter after being found confused and slurring his speech 30 \
        minutes ago. He used insulin this morning. On exam he is \
        intermittently following commands with dysarthria and mild right \
        face/arm drift.
        """,
        demographics: .init(ageYears: 77, sex: "M", weightKg: 82),
        history: [
            "Type 2 diabetes on basal-bolus insulin",
            "HTN",
            "CKD stage 3"
        ],
        presentingNihss: 6,
        vitals: .init(bp: "145/80", hr: 102, glucoseMgDl: 38, oxygenSat: 98),
        timing: .init(lkwMinutesAgo: 30,
                      symptomDiscoveryMinutesAgo: 30,
                      emsArrivalMinutesAgo: 15,
                      doorMinutesAgo: 0),
        findings: .init(
            ctNonContrast: "No intracranial hemorrhage. No early ischemic changes. ASPECTS 10.",
            imagingResult: .ischemic,
            aspects: 10,
            cta: "No large vessel occlusion. Normal intracranial vasculature.",
            lvoStatus: .absent,
            labs: "Glucose 38 mg/dL (low). INR 1.0, Plt 220k. After D50 IV push, glucose 132 and symptoms fully resolved."
        ),
        expected: .init(
            thrombolytic: .declined,
            evt: .declined,
            rationale: "Hypoglycemia is a stroke mimic — correct glucose and reassess. With full resolution after dextrose, thrombolysis is not indicated."
        ),
        teachingPoints: [
            "Check fingerstick glucose on every stroke alert before deciding to bolus.",
            "Glucose <50 mg/dL is a contraindication to thrombolysis and a common mimic.",
            "Reassess deficit after correction; many mimics resolve fully.",
            "Continue stroke workup if deficits persist after correction."
        ]
    )

    static let doacExclusion = StrokeCodeScenario(
        id: "case.doacExclusion",
        title: "DOAC exclusion within window",
        difficulty: .medium,
        oneLiner: "69M on apixaban, LKW 60 min ago, right hemiparesis",
        vignette: """
        A 69-year-old man with atrial fibrillation on apixaban develops \
        sudden right arm weakness and slurred speech 60 minutes ago. His \
        wife reports his last apixaban dose was about 20 hours ago. He is \
        awake with right face/arm weakness and mild dysarthria.
        """,
        demographics: .init(ageYears: 69, sex: "M", weightKg: 88),
        history: [
            "Atrial fibrillation on apixaban 5 mg BID (last dose ~20 h ago)",
            "HTN, HLD",
            "Prior TIA 4 years ago"
        ],
        presentingNihss: 10,
        vitals: .init(bp: "160/88", hr: 80, glucoseMgDl: 130, oxygenSat: 97),
        timing: .init(lkwMinutesAgo: 60,
                      symptomDiscoveryMinutesAgo: 55,
                      emsArrivalMinutesAgo: 30,
                      doorMinutesAgo: 0),
        findings: .init(
            ctNonContrast: "No hemorrhage. No early ischemic changes. ASPECTS 10.",
            imagingResult: .ischemic,
            aspects: 10,
            cta: "Right M2 occlusion. Good collaterals.",
            lvoStatus: .present,
            labs: "Glucose 130 mg/dL, INR 1.1, Plt 210k. Anti-Xa level (apixaban) pending."
        ),
        expected: .init(
            thrombolytic: .declined,
            evt: .planned,
            rationale: "DOAC within 48 h is a contraindication to IV thrombolysis unless reversal/anti-Xa criteria are met by protocol. EVT candidate based on confirmed M2 LVO."
        ),
        teachingPoints: [
            "DOAC within 48 h is a contraindication to IV thrombolysis without protocol-specific reversal pathway.",
            "EVT is not contraindicated by DOAC use.",
            "Verify last DOAC dose time precisely; consider anti-Xa or specific reversal per protocol.",
            "Activate EVT pathway in parallel."
        ]
    )

    static let wakeUpStroke = StrokeCodeScenario(
        id: "case.wakeUpStroke",
        title: "Wake-up stroke — extended-window IV decision",
        difficulty: .medium,
        oneLiner: "60F awoke with L hemiparesis; LKW ~9 h ago, no LVO",
        vignette: """
        A 60-year-old woman wakes at 6:00 AM with left arm weakness and \
        facial droop. Her husband last saw her well at ~9:00 PM. She \
        arrives at the ED at 7:30 AM, approximately 9 hours after LKW. \
        She is awake with left face/arm weakness.
        """,
        demographics: .init(ageYears: 60, sex: "F", weightKg: 72),
        history: [
            "HTN",
            "No anticoagulants",
            "No recent surgery or bleeding"
        ],
        presentingNihss: 12,
        vitals: .init(bp: "152/86", hr: 84, glucoseMgDl: 105, oxygenSat: 98),
        timing: .init(lkwMinutesAgo: 540,
                      symptomDiscoveryMinutesAgo: 90,
                      emsArrivalMinutesAgo: 45,
                      doorMinutesAgo: 0),
        findings: .init(
            ctNonContrast: "No hemorrhage. ASPECTS 8.",
            imagingResult: .ischemic,
            aspects: 8,
            cta: "No large vessel occlusion identified.",
            lvoStatus: .absent,
            labs: "Glucose 105 mg/dL, INR 1.0, Plt 250k. MRI: DWI lesion right corona radiata with FLAIR mismatch (suggests <4.5 h since infarction)."
        ),
        expected: .init(
            thrombolytic: .alteplase,
            evt: .declined,
            rationale: "Wake-up stroke with DWI/FLAIR mismatch supports IV thrombolysis via imaging-guided extended-window pathway. No LVO — EVT not indicated."
        ),
        teachingPoints: [
            "Wake-up stroke is not automatically excluded from IV thrombolysis when MRI mismatch criteria are met.",
            "Imaging-guided extended-window IV thrombolysis is recognized in current guidelines.",
            "Absent LVO closes the EVT pathway — manage medically.",
            "Document the imaging rationale clearly when treating a wake-up stroke."
        ]
    )
}

// MARK: - Anchor application

/// A computed set of milestone events derived from a scenario's timing,
/// relative to a load time. These get pre-populated when the educator
/// drops a scenario into the timer.
extension StrokeCodeScenario {

    /// Returns the pre-populated milestone events for this scenario as of `loadedAt`.
    func initialEvents(loadedAt: Date = Date()) -> [StrokeCodeEvent] {
        var events: [StrokeCodeEvent] = []

        func add(_ id: String, minutesAgo: Int?) {
            guard let m = minutesAgo else { return }
            let date = loadedAt.addingTimeInterval(-Double(m) * 60.0)
            events.append(StrokeCodeEvent(milestoneId: id, timestamp: date, note: nil))
        }

        add("lkw", minutesAgo: timing.lkwMinutesAgo)
        add("symptomDiscovery", minutesAgo: timing.symptomDiscoveryMinutesAgo)
        add("emsArrival", minutesAgo: timing.emsArrivalMinutesAgo)
        add("doorTime", minutesAgo: timing.doorMinutesAgo)
        return events
    }
}
