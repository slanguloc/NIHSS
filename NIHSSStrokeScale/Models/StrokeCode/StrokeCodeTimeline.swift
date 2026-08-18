//
//  StrokeCodeTimeline.swift
//  Zysquy — Stroke Code Timer (education/training subset).
//
//  Models a simulated/training stroke-code timeline with milestones aligned
//  to AHA/ASA Target: Stroke time windows (e.g., door-to-needle ≤60 min,
//  door-to-CT ≤25 min, door-to-puncture ≤90 min). Not for clinical use.
//

import Foundation

// MARK: - Targets and references

/// Time target window for a milestone, expressed in minutes from a reference event.
struct StrokeCodeTarget: Codable, Equatable {
    /// Standard target in minutes (e.g., 60 minutes for door-to-needle).
    let targetMinutes: Int
    /// Optional stretch goal in minutes (e.g., 45 minutes for door-to-needle).
    let stretchMinutes: Int?
}

/// Which earlier event this milestone is measured from when computing elapsed time.
enum StrokeCodeReference: String, Codable, Equatable {
    /// Measured from ED arrival (door time, the in-hospital t=0).
    case door
    /// Measured from Last Known Well (LKW), the treatment-window anchor.
    case lastKnownWell
    /// Free-standing anchor event (no elapsed-from value).
    case anchor
}

// MARK: - Milestone catalog

/// One milestone in a stroke code timeline.
struct StrokeCodeMilestone: Identifiable, Codable, Equatable {
    /// Stable identifier used for event lookup (e.g., "doorTime", "needle").
    let id: String
    /// Display label, kept short for tap targets.
    let label: String
    /// Educational help text explaining the milestone.
    let helpText: String
    /// Which prior event the elapsed time is computed against.
    let measuredFrom: StrokeCodeReference
    /// Optional target window for goal-vs-actual coloring.
    let target: StrokeCodeTarget?
    /// True if this milestone defines an anchor (Door or LKW).
    let isAnchor: Bool
    /// Display order in the timeline.
    let order: Int
}

extension StrokeCodeMilestone {
    /// The default training catalog. Time windows reflect widely used
    /// AHA/ASA Target: Stroke goals; see SOURCES.md.
    static let defaultMilestones: [StrokeCodeMilestone] = [
        StrokeCodeMilestone(
            id: "lkw",
            label: "Last Known Well",
            helpText: "Last time the patient was confirmed at neurologic baseline. Anchors thrombolysis and EVT treatment windows. If truly unknown (found down, no historian), mark Unknown LKW and use imaging selection.",
            measuredFrom: .anchor,
            target: nil,
            isAnchor: true,
            order: 0
        ),
        StrokeCodeMilestone(
            id: "symptomDiscovery",
            label: "Symptom discovery",
            helpText: "When deficits were first noticed. If unknown, use Last Known Well for treatment-window decisions.",
            measuredFrom: .lastKnownWell,
            target: nil,
            isAnchor: false,
            order: 1
        ),
        StrokeCodeMilestone(
            id: "emsArrival",
            label: "EMS on scene / MSU",
            helpText: "Time EMS or a Mobile Stroke Unit reached the patient.",
            measuredFrom: .lastKnownWell,
            target: nil,
            isAnchor: false,
            order: 2
        ),
        StrokeCodeMilestone(
            id: "doorTime",
            label: "ED arrival (Door)",
            helpText: "Hospital arrival. Anchors in-hospital timing (t=0) for Target: Stroke metrics.",
            measuredFrom: .anchor,
            target: nil,
            isAnchor: true,
            order: 3
        ),
        StrokeCodeMilestone(
            id: "codeActivated",
            label: "Stroke code activated",
            helpText: "Stroke team paged and resources mobilized.",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 5, stretchMinutes: nil),
            isAnchor: false,
            order: 4
        ),
        StrokeCodeMilestone(
            id: "mdEval",
            label: "MD evaluation",
            helpText: "Initial physician evaluation begins.",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 10, stretchMinutes: nil),
            isAnchor: false,
            order: 5
        ),
        StrokeCodeMilestone(
            id: "nihssDone",
            label: "NIHSS completed",
            helpText: "NIH Stroke Scale documented. The NIHSS module of this app supports this step.",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 15, stretchMinutes: nil),
            isAnchor: false,
            order: 6
        ),
        StrokeCodeMilestone(
            id: "ctStart",
            label: "Non-contrast CT started",
            helpText: "Patient on scanner. Hemorrhage rule-out before thrombolysis.",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 25, stretchMinutes: nil),
            isAnchor: false,
            order: 7
        ),
        StrokeCodeMilestone(
            id: "ctRead",
            label: "CT interpreted",
            helpText: "Head CT read complete (hemorrhage ruled out / ASPECTS noted).",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 45, stretchMinutes: nil),
            isAnchor: false,
            order: 8
        ),
        StrokeCodeMilestone(
            id: "labs",
            label: "Critical labs resulted",
            helpText: "Glucose at minimum; INR if on warfarin; other labs per protocol. Do not delay thrombolysis waiting on non-essential labs.",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 45, stretchMinutes: nil),
            isAnchor: false,
            order: 9
        ),
        StrokeCodeMilestone(
            id: "cta",
            label: "CTA / vessel imaging",
            helpText: "CT angiography (and CT perfusion if indicated) to identify large vessel occlusion (LVO).",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 45, stretchMinutes: nil),
            isAnchor: false,
            order: 10
        ),
        StrokeCodeMilestone(
            id: "thrombolyticDecision",
            label: "Thrombolytic decision",
            helpText: "Eligibility for IV alteplase or tenecteplase determined; consent as required.",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 55, stretchMinutes: nil),
            isAnchor: false,
            order: 11
        ),
        StrokeCodeMilestone(
            id: "needle",
            label: "Thrombolytic bolus (Door-to-Needle)",
            helpText: "IV thrombolytic administered. AHA/ASA Target: Stroke standard ≤60 min; stretch goal ≤45 min.",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 60, stretchMinutes: 45),
            isAnchor: false,
            order: 12
        ),
        StrokeCodeMilestone(
            id: "evtDecision",
            label: "EVT decision",
            helpText: "Endovascular thrombectomy candidacy determined (LVO, imaging criteria, time window).",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 75, stretchMinutes: nil),
            isAnchor: false,
            order: 13
        ),
        StrokeCodeMilestone(
            id: "puncture",
            label: "Arterial puncture (Door-to-Puncture)",
            helpText: "Femoral/radial access for EVT. Target ≤90 min in-hospital; ≤60 min for transfers (after arrival at EVT center).",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 90, stretchMinutes: 60),
            isAnchor: false,
            order: 14
        ),
        StrokeCodeMilestone(
            id: "recanalization",
            label: "Recanalization (Door-to-Reperfusion)",
            helpText: "TICI 2b or better achieved. Target ≤120 min from door.",
            measuredFrom: .door,
            target: StrokeCodeTarget(targetMinutes: 120, stretchMinutes: nil),
            isAnchor: false,
            order: 15
        )
    ]

    /// Compact label for the time-point navigator.
    var shortLabel: String {
        switch id {
        case "lkw": return "LKW"
        case "symptomDiscovery": return "Discovery"
        case "emsArrival": return "EMS"
        case "doorTime": return "Door"
        case "codeActivated": return "Code"
        case "mdEval": return "MD eval"
        case "nihssDone": return "NIHSS"
        case "ctStart": return "CT start"
        case "ctRead": return "CT read"
        case "labs": return "Labs"
        case "cta": return "CTA"
        case "thrombolyticDecision": return "IVT decision"
        case "needle": return "Needle"
        case "evtDecision": return "EVT decision"
        case "puncture": return "Puncture"
        case "recanalization": return "Reperfusion"
        default: return label
        }
    }

    /// Grouping used by the simplified timeline list.
    var sectionTitle: String {
        switch id {
        case "lkw", "doorTime": return "Anchors"
        case "symptomDiscovery", "emsArrival": return "Pre-hospital"
        case "codeActivated", "mdEval", "nihssDone": return "ED evaluation"
        case "ctStart", "ctRead", "labs", "cta": return "Imaging"
        default: return "Reperfusion"
        }
    }
}

// MARK: - Captured events

/// A captured timestamp for a milestone, with optional free-text note.
struct StrokeCodeEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let milestoneId: String
    let timestamp: Date
    let note: String?

    init(id: UUID = UUID(), milestoneId: String, timestamp: Date, note: String? = nil) {
        self.id = id
        self.milestoneId = milestoneId
        self.timestamp = timestamp
        self.note = note
    }
}

// MARK: - Session

/// A single stroke-code training session: the captured events plus metadata.
struct StrokeCodeSession: Identifiable, Codable, Equatable {
    let id: UUID
    /// When the timer session was started in-app.
    let startedAt: Date
    /// All captured milestone events.
    var events: [StrokeCodeEvent]
    /// Free-text notes (kept local-only, encrypted at rest).
    var notes: String
    /// When the user closed/finalized the session.
    var completedAt: Date?
    /// Decision-support state for this session. Optional for backward
    /// compatibility with sessions saved before the decision pane existed.
    var decisions: DecisionState?
    /// Identifier of the educator-selected scenario, if any.
    var scenarioId: String?
    /// True when Last Known Well cannot be determined (found down, no historian).
    /// Distinct from “not yet captured.” Optional for backward compatibility.
    var lkwUnknown: Bool? = nil

    init(id: UUID = UUID(),
         startedAt: Date = Date(),
         events: [StrokeCodeEvent] = [],
         notes: String = "",
         completedAt: Date? = nil,
         decisions: DecisionState? = nil,
         scenarioId: String? = nil,
         lkwUnknown: Bool? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.events = events
        self.notes = notes
        self.completedAt = completedAt
        self.decisions = decisions
        self.scenarioId = scenarioId
        self.lkwUnknown = lkwUnknown
    }

    /// First event timestamp for a given milestone id, if captured.
    func timestamp(for milestoneId: String) -> Date? {
        events.first(where: { $0.milestoneId == milestoneId })?.timestamp
    }

    /// Door time (in-hospital t=0).
    var doorTime: Date? { timestamp(for: "doorTime") }

    /// Last Known Well (treatment-window anchor). Nil when not captured or marked unknown.
    var lastKnownWell: Date? { timestamp(for: "lkw") }

    /// True when the trainee marked LKW as unknown (wake-up / found down with no historian).
    var isLKWUnknown: Bool { lkwUnknown == true }

    /// Minutes from captured LKW to `date`. Nil when LKW is missing or unknown.
    func minutesSinceLKW(at date: Date = Date()) -> Double? {
        guard !isLKWUnknown, let lkw = lastKnownWell else { return nil }
        return date.timeIntervalSince(lkw) / 60.0
    }

    /// A milestone is complete when timestamped, or when LKW is marked unknown.
    func isComplete(_ milestone: StrokeCodeMilestone) -> Bool {
        if milestone.id == "lkw" && isLKWUnknown { return true }
        return timestamp(for: milestone.id) != nil
    }

    func nextPendingMilestone(from catalog: [StrokeCodeMilestone] = StrokeCodeMilestone.defaultMilestones) -> StrokeCodeMilestone? {
        catalog.first { !isComplete($0) }
    }

    func previousPendingMilestone(before id: String,
                                  from catalog: [StrokeCodeMilestone] = StrokeCodeMilestone.defaultMilestones) -> StrokeCodeMilestone? {
        guard let idx = catalog.firstIndex(where: { $0.id == id }) else {
            return catalog.last { !isComplete($0) }
        }
        return catalog.prefix(idx).last { !isComplete($0) }
    }

    /// Reference time for a milestone, given the milestone catalog.
    func referenceTime(for milestone: StrokeCodeMilestone) -> Date? {
        switch milestone.measuredFrom {
        case .door: return doorTime
        case .lastKnownWell: return lastKnownWell
        case .anchor: return nil
        }
    }

    /// Elapsed seconds from the milestone's reference time to its captured timestamp.
    /// Returns nil if either is missing.
    func elapsedSeconds(for milestone: StrokeCodeMilestone) -> TimeInterval? {
        guard let captured = timestamp(for: milestone.id),
              let reference = referenceTime(for: milestone) else { return nil }
        return captured.timeIntervalSince(reference)
    }
}

// MARK: - Status helpers

/// How a captured milestone compares to its target window.
enum StrokeCodeTargetStatus {
    case onTrackStretch    // met stretch goal
    case onTrackTarget     // met standard goal
    case missed            // beyond standard target
    case notCaptured       // no timestamp yet

    var label: String {
        switch self {
        case .onTrackStretch: return "Stretch met"
        case .onTrackTarget: return "Target met"
        case .missed: return "Target missed"
        case .notCaptured: return "Pending"
        }
    }
}

extension StrokeCodeSession {
    /// Compares captured time against the milestone's target window.
    func status(for milestone: StrokeCodeMilestone) -> StrokeCodeTargetStatus {
        guard let target = milestone.target else { return .notCaptured }
        guard let elapsed = elapsedSeconds(for: milestone) else { return .notCaptured }
        let minutes = elapsed / 60.0
        if let stretch = target.stretchMinutes, minutes <= Double(stretch) {
            return .onTrackStretch
        }
        if minutes <= Double(target.targetMinutes) {
            return .onTrackTarget
        }
        return .missed
    }
}

// MARK: - Persistent store

private let maxStrokeCodes = 50
private let strokeCodeStoreKey = "ZysquyStrokeCodeSessions"

/// Persists completed stroke-code sessions (encrypted on disk) and holds the
/// active in-progress session in memory.
final class StrokeCodeStore: ObservableObject {
    /// Completed sessions, newest first. Capped at `maxStrokeCodes`.
    @Published private(set) var sessions: [StrokeCodeSession] = []
    /// The currently running session, if any.
    @Published var active: StrokeCodeSession?
    /// True when the active session was reopened from history for editing.
    @Published private(set) var isEditingExisting: Bool = false
    /// Snapshot of the saved session at the moment of reopening. Used to
    /// restore the original on edit-cancel.
    private var editingOriginal: StrokeCodeSession?

    init() {
        load()
    }

    // MARK: Active session lifecycle

    func startNew() {
        active = StrokeCodeSession(startedAt: Date())
        isEditingExisting = false
        editingOriginal = nil
        // Sensible training defaults: weight 75 kg (typical adult, supports
        // dose calculator) and ASPECTS 10 (normal NCCT). Trainee modifies
        // as findings emerge.
        mutateDecisions {
            $0.aspectsScore = 10
            $0.pcAspectsScore = 10
            $0.weightKg = 75
        }
    }

    /// Reopens a previously saved session for editing. The saved copy is
    /// removed from `sessions`; on the next `completeAndSaveActive()` the
    /// edited session is re-inserted (preserving its id). If the user
    /// cancels mid-edit, the original is restored.
    func reopen(_ session: StrokeCodeSession) {
        sessions.removeAll(where: { $0.id == session.id })
        editingOriginal = session
        var s = session
        s.completedAt = nil
        active = s
        isEditingExisting = true
        save()
    }

    /// Starts a new session pre-populated with milestones from the
    /// scenario's timing. The scenario id is recorded on the session, and
    /// the patient weight (if any) is seeded into the decision state so the
    /// dosing calculator has a starting point.
    func startFromScenario(_ scenario: StrokeCodeScenario, loadedAt: Date = Date()) {
        var seeded = DecisionState.empty
        seeded.weightKg = scenario.demographics.weightKg ?? 75
        seeded.aspectsScore = 10
        seeded.pcAspectsScore = 10
        var session = StrokeCodeSession(
            startedAt: loadedAt,
            events: scenario.initialEvents(loadedAt: loadedAt),
            notes: "",
            completedAt: nil,
            decisions: seeded,
            scenarioId: scenario.id,
            lkwUnknown: scenario.timing.lkwMinutesAgo == nil ? true : nil
        )
        active = session
        isEditingExisting = false
        editingOriginal = nil
        applyIVTTimeWindowHintsIfApplicable()
    }

    func cancelActive() {
        // If editing an existing session, restore the pre-edit snapshot.
        if let original = editingOriginal {
            sessions.insert(original, at: 0)
            if sessions.count > maxStrokeCodes {
                sessions = Array(sessions.prefix(maxStrokeCodes))
            }
            save()
        }
        active = nil
        isEditingExisting = false
        editingOriginal = nil
    }

    func completeAndSaveActive() {
        guard var s = active else { return }
        s.completedAt = Date()
        sessions.insert(s, at: 0)
        if sessions.count > maxStrokeCodes {
            sessions = Array(sessions.prefix(maxStrokeCodes))
        }
        active = nil
        isEditingExisting = false
        editingOriginal = nil
        save()
    }

    // MARK: Mutating the active session

    /// Captures (or replaces) the timestamp for a milestone in the active session.
    func capture(milestoneId: String, at date: Date = Date(), note: String? = nil) {
        guard var s = active else { return }
        s.events.removeAll(where: { $0.milestoneId == milestoneId })
        s.events.append(StrokeCodeEvent(milestoneId: milestoneId, timestamp: date, note: note))
        if milestoneId == "lkw" {
            s.lkwUnknown = false
        }
        active = s
        if milestoneId == "lkw" {
            applyIVTTimeWindowHintsIfApplicable()
        }
    }

    /// Marks Last Known Well as unknown (no usable timestamp). Clears any
    /// previously captured LKW time.
    func markLKWUnknown() {
        guard var s = active else { return }
        s.events.removeAll(where: { $0.milestoneId == "lkw" })
        s.lkwUnknown = true
        active = s
        mutateDecisions { $0.ivtCriteria["ivt.windowLKW45h"] = .unknown }
        applyIVTTimeWindowHintsIfApplicable()
    }

    /// Captures `milestoneId` only if it hasn't been captured yet. Returns
    /// true when a new capture is created. Used by the Decisions tab to
    /// auto-stamp the matching timeline milestone (e.g. when imaging is
    /// interpreted or a thrombolytic decision is made) without
    /// overwriting a manual capture the trainee already entered.
    @discardableResult
    func captureIfAbsent(milestoneId: String, at date: Date = Date(), note: String? = nil) -> Bool {
        guard var s = active else { return false }
        if s.events.contains(where: { $0.milestoneId == milestoneId }) { return false }
        s.events.append(StrokeCodeEvent(milestoneId: milestoneId, timestamp: date, note: note))
        active = s
        return true
    }

    /// Removes the timestamp for a given milestone from the active session.
    func clear(milestoneId: String) {
        guard var s = active else { return }
        s.events.removeAll(where: { $0.milestoneId == milestoneId })
        if milestoneId == "lkw" {
            s.lkwUnknown = false
        }
        active = s
        if milestoneId == "lkw" {
            mutateDecisions { $0.ivtCriteria["ivt.windowLKW45h"] = .unknown }
        }
    }

    /// Updates the free-text notes on the active session.
    func updateNotes(_ text: String) {
        guard var s = active else { return }
        s.notes = text
        active = s
    }

    // MARK: Decision-support helpers

    /// Replaces the entire decision state on the active session.
    func updateDecisions(_ state: DecisionState) {
        guard var s = active else { return }
        s.decisions = state
        active = s
    }

    /// Convenience: mutates the active session's decision state via a closure.
    func mutateDecisions(_ mutate: (inout DecisionState) -> Void) {
        guard var s = active else { return }
        var d = s.decisions ?? .empty
        mutate(&d)
        s.decisions = d
        active = s
    }

    /// After extended-window EVT toggles change, pre-fill related EVT checklist
    /// answers when still unknown (training aid only).
    func applyExtendedWindowEVTHintsIfApplicable() {
        guard let lkw = active?.lastKnownWell else { return }
        let minutesSinceLKW = Date().timeIntervalSince(lkw) / 60.0
        mutateDecisions { $0.applyExtendedWindowEVTChecklistHints(minutesSinceLKW: minutesSinceLKW) }
    }

    /// Auto-fills IVT “within 4.5 h / extended window” from Timeline LKW when unanswered.
    func applyIVTTimeWindowHintsIfApplicable() {
        let unknown = active?.isLKWUnknown == true
        let minutes = active?.minutesSinceLKW()
        guard unknown || minutes != nil else { return }
        mutateDecisions { $0.applyIVTTimeWindowFromLKW(minutesSinceLKW: minutes, lkwUnknown: unknown) }
    }

    /// Auto-fills the IVT “disabling deficit” item from NIHSS and the mild-stroke classification.
    func applyDisablingDeficitHintsIfApplicable() {
        mutateDecisions { $0.applyIVTDisablingFromCapturedDeficit() }
    }

    // MARK: Persistence

    private func load() {
        guard let stored = UserDefaults.standard.data(forKey: strokeCodeStoreKey) else { return }
        let dataToDecode = LocalEncryptedStorage.decrypt(stored) ?? stored
        if let decoded = try? JSONDecoder().decode([StrokeCodeSession].self, from: dataToDecode) {
            sessions = decoded
        }
    }

    private func save() {
        guard let plain = try? JSONEncoder().encode(sessions),
              let encrypted = LocalEncryptedStorage.encrypt(plain) else { return }
        UserDefaults.standard.set(encrypted, forKey: strokeCodeStoreKey)
    }

    // MARK: Utilities

    /// Formats a TimeInterval as +HH:MM:SS (positive) or -HH:MM:SS.
    static func format(elapsed: TimeInterval) -> String {
        let sign = elapsed < 0 ? "-" : "+"
        let total = Int(abs(elapsed).rounded(.down))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%@%d:%02d:%02d", sign, h, m, s)
        }
        return String(format: "%@%02d:%02d", sign, m, s)
    }
}
