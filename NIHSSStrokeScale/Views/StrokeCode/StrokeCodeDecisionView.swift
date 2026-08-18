//
//  StrokeCodeDecisionView.swift
//  Zysquy — Decision-support walkthrough for the Stroke Code Timer
//  (education/training only).
//
//  Walks the trainee through the same decision branches as a real stroke
//  code workflow:
//    • Imaging branch (hemorrhagic / ischemic / pending)
//    • IV thrombolysis (alteplase / tenecteplase) eligibility
//    • LVO assessment
//    • EVT eligibility
//  Each pane shows a "training suggestion" that updates as criteria are
//  answered. Not a medical device. Not for clinical decisions.
//

import SwiftUI

struct StrokeCodeDecisionView: View {
    @EnvironmentObject var store: StrokeCodeStore
    @EnvironmentObject var languageStore: LanguageStore
    @EnvironmentObject var spanishSpeech: SpanishSpeechService
    @EnvironmentObject var patientResponse: PatientResponseService
    @AppStorage("preferredWeightUnit") private var preferredWeightUnitRaw: String = WeightUnit.kilograms.rawValue

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: preferredWeightUnitRaw) ?? .kilograms
    }

    private var state: DecisionState {
        store.active?.decisions ?? .empty
    }

    var body: some View {
        VStack(spacing: 12) {
            disclaimerBanner
            timelineAutoCaptureBanner
            patientDetailsCard
            if shouldShowMildStrokeGuide {
                mildStrokeDisablingCard
            }
            anchorsCard
            imagingCard
            if state.imagingResult != .hemorrhagic {
                aspectsHowToCalculateCard
                aspectsCard
                pcAspectsHowToCalculateCard
                pcAspectsCard
            }
            if state.imagingResult == .hemorrhagic {
                hemorrhagicAdvisory
            } else {
                if shouldShowExtendedEarlyIvt {
                    extendedEarlyIvtCard
                }
                ivtCard
                if state.thrombolyticChosen == .alteplase || state.thrombolyticChosen == .tenecteplase {
                    dosingCard
                    consentCard
                }
            }
            if state.imagingResult != .hemorrhagic {
                extendedWindowCard
            }
            lvoCard
            if state.lvoStatus == .present {
                evtCard
            } else if shouldShowExtendedWindowEvtBridge {
                extendedWindowEvtBridgeCard
            }
            if shouldShowMedicalManagement {
                medicalManagementCard
            }
            finalDecisionsCard
            appReferencesCard
            educationalFooter
                .padding(.top, 8)
        }
    }

    /// Shows medical-management guidance whenever a (presumed) ischemic
    /// stroke is not being actively treated with IV thrombolysis or EVT —
    /// covering ischemic, equivocal, or still-pending imaging so trainees
    /// see the antiplatelet / BP / secondary-prevention bundle for any
    /// scenario where neither reperfusion therapy is moving forward.
    /// Hidden only when imaging is hemorrhagic (separate ICH advisory)
    /// or when either reperfusion therapy IS being given.
    private var shouldShowMedicalManagement: Bool {
        if state.imagingResult == .hemorrhagic { return false }
        let ivtGiven = state.thrombolyticChosen == .alteplase ||
                       state.thrombolyticChosen == .tenecteplase
        let evtGiven = state.evtChosen == .planned
        return !ivtGiven && !evtGiven
    }

    /// True when the user has not yet committed to a non-treatment path on
    /// either branch. Used to soften the medical-management card with a
    /// "interim guidance" note instead of a strong "no IVT / EVT" header.
    private var isMedicalManagementInterim: Bool {
        let ivtUncommitted = state.thrombolyticChosen == .undecided
        let evtUncommitted = state.evtChosen == .undecided ||
                             state.lvoStatus == .unknown
        return ivtUncommitted || evtUncommitted
    }

    private var minutesSinceLKW: Double? {
        store.active?.minutesSinceLKW()
    }

    private var isLKWUnknown: Bool {
        store.active?.isLKWUnknown == true
    }

    private var shouldShowMildStrokeGuide: Bool {
        if state.imagingResult == .hemorrhagic { return false }
        if let n = state.nihssTotal { return n <= DecisionState.mildNihssMax }
        return true
    }

    /// Shown when late-window EVT criteria are met but LVO is not yet confirmed.
    private var shouldShowExtendedWindowEvtBridge: Bool {
        guard state.lvoStatus != .present else { return false }
        if isLKWUnknown {
            return state.suggestsExtendedWindowEVT(minutesSinceLKW: nil, lkwUnknown: true)
        }
        guard let mins = minutesSinceLKW else { return false }
        return state.suggestsExtendedWindowEVT(minutesSinceLKW: mins, lkwUnknown: false)
    }

    // MARK: - Banner / footer

    /// One-line note explaining that committing decisions here will
    /// time-stamp the matching Timeline milestone (unless already set).
    private var timelineAutoCaptureBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "clock.badge.checkmark.fill")
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Decisions auto-stamp the Timeline")
                    .font(.subheadline.bold())
                Text("Setting imaging, LVO status, or committing an IVT / EVT choice marks the matching Timeline milestone (CT interpreted, CTA, thrombolytic decision, EVT decision). Manual captures are never overwritten.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.blue.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Decision support — training only")
                    .font(.subheadline.bold())
                Text("Educational walkthrough of common decision branches. Not a medical device. Not for clinical decisions or documentation.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var educationalFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Training references")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text("Criteria summarize widely published AHA/ASA inclusion/exclusion items for IV thrombolysis and EVT. Follow your institution's stroke protocol for patient care. See SOURCES.md.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Education only. Not for clinical use.")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Anchors card

    private var anchorsCard: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { ctx in
            let now = ctx.date
            let lkw = store.active?.lastKnownWell
            let door = store.active?.doorTime
            let unknown = isLKWUnknown
            VStack(alignment: .leading, spacing: 6) {
                Text("Anchors")
                    .font(.headline)
                HStack(spacing: 12) {
                    anchorTile(title: "LKW",
                               time: unknown ? nil : lkw,
                               now: now,
                               subtitle: unknown
                                ? "Imaging selection pathway"
                                : (lkw == nil ? "Set on Timeline tab, or mark unknown" : windowHint(lkw: lkw, now: now)),
                               color: unknown ? .orange : .blue,
                               valueOverride: unknown ? "Unknown" : nil)
                    anchorTile(title: "Door (t=0)", time: door, now: now,
                               subtitle: door == nil ? "Set on Timeline tab" : "In-hospital t=0",
                               color: .red)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func anchorTile(title: String, time: Date?, now: Date, subtitle: String, color: Color, valueOverride: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(valueOverride ?? (time.map { StrokeCodeStore.format(elapsed: now.timeIntervalSince($0)) } ?? "—"))
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle((valueOverride != nil || time != nil) ? color : Color.secondary)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func windowHint(lkw: Date?, now: Date) -> String {
        guard let lkw else { return "—" }
        let minutes = now.timeIntervalSince(lkw) / 60.0
        if minutes < 0 { return "LKW in the future" }
        if minutes <= 270 { return "≤4.5h IV window" }
        if minutes <= 540 { return "Extended IV (select, by imaging)" }
        if minutes <= 1440 { return "≤24h EVT (select, by imaging)" }
        return "Beyond standard windows"
    }

    // MARK: - Imaging card

    private var imagingCard: some View {
        card(title: "Non-contrast head CT", systemImage: "brain.head.profile") {
            Picker("Imaging result", selection: imagingBinding) {
                ForEach(ImagingResult.allCases, id: \.self) { r in
                    Text(r.label).tag(r)
                }
            }
            .pickerStyle(.segmented)

            switch state.imagingResult {
            case .pending:
                hint("Awaiting CT interpretation. IV thrombolysis and EVT decisions depend on this.")
            case .ischemic:
                hint("No hemorrhage. IV thrombolysis pathway and vascular imaging pathway are both open.", color: .blue)
            case .hemorrhagic:
                hint("Hemorrhage present. Thrombolysis pathway closed; see advisory below.", color: .red)
            case .equivocal:
                hint("Equivocal findings. Obtain neuroradiology review before treatment decisions.")
            }
        }
    }

    private var hemorrhagicAdvisory: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Hemorrhagic stroke pathway (training)")
                    .font(.headline)
            }
            Text("• Hold IV thrombolytics.")
            Text("• Consult neurosurgery and neurology.")
            Text("• BP management per institutional ICH protocol (typically goal SBP 130–150 mmHg).")
            Text("• Reverse anticoagulation per protocol if applicable.")
            Text("• Recheck CT / consider CTA for vascular cause.")
            Text("Education only. Follow your institution's protocol.")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
                .padding(.top, 4)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - IVT card

    private var ivtCard: some View {
        TimelineView(.periodic(from: .now, by: 60.0)) { ctx in
            ivtCardContent
                .task(id: Int(ctx.date.timeIntervalSinceReferenceDate / 60)) {
                    store.applyIVTTimeWindowHintsIfApplicable()
                }
        }
        .onAppear { store.applyIVTTimeWindowHintsIfApplicable() }
    }

    private var ivtCardContent: some View {
        let verdict = state.ivtVerdict()
        let timing = state.ivtTimeWindowAssessment(minutesSinceLKW: minutesSinceLKW, lkwUnknown: isLKWUnknown)
        let disabling = state.ivtDisablingAssessment()
        return card(title: "IV thrombolysis eligibility", systemImage: "syringe") {
            if store.active?.lastKnownWell != nil || isLKWUnknown {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: timing.met == true ? "clock.badge.checkmark" : (timing.met == false ? "clock.badge.exclamationmark" : "clock"))
                        .foregroundStyle(timing.met == true ? .green : (timing.met == false ? .orange : .secondary))
                    Text(timing.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if shouldShowMildStrokeGuide {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: disabling.met == true ? "checkmark.circle" : (disabling.met == false ? "xmark.circle" : "questionmark.circle"))
                        .foregroundStyle(disabling.met == true ? .green : (disabling.met == false ? .orange : .secondary))
                    Text(disabling.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            verdictBadge(verdict)

            ForEach(groupedIvt(), id: \.0) { group, items in
                Text(group)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                ForEach(items) { c in
                    ivtCriterionRow(criterion: c, timingDetail: c.id == "ivt.windowLKW45h" ? timing.detail : nil)
                }
            }

            failedList(verdict)

            HStack {
                Text("Chosen (training):")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Choice", selection: thrombolyticBinding) {
                    ForEach(ThrombolyticChoice.allCases, id: \.self) { c in
                        Text(c.label).tag(c)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .padding(.top, 4)
        }
    }

    private func groupedIvt() -> [(String, [DecisionCriterion])] {
        let all = StrokeCodeDecisionCatalog.ivt
        let groups = Array(Set(all.map { $0.group }))
            .sorted { $0 == "Required" ? true : ($1 == "Required" ? false : $0 < $1) }
        return groups.map { g in
            (g, all.filter { $0.group == g })
        }
    }

    private func ivtCriterionRow(criterion: DecisionCriterion, timingDetail: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            criterionRow(
                criterion: criterion,
                answer: state.ivtCriteria[criterion.id] ?? .unknown,
                onChange: { newValue in
                    store.mutateDecisions { $0.ivtCriteria[criterion.id] = newValue }
                }
            )
            if let timingDetail,
               (state.ivtCriteria[criterion.id] ?? .unknown) != .unknown {
                Text("From LKW: \(timingDetail)")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .padding(.leading, 4)
            }
        }
    }

    // MARK: - LVO card

    private var lvoCard: some View {
        card(title: "Vascular imaging (CTA / MRA)", systemImage: "waveform.path.ecg") {
            Picker("LVO", selection: lvoBinding) {
                ForEach(LvoStatus.allCases, id: \.self) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)

            switch state.lvoStatus {
            case .unknown:
                hint("Obtain CTA (and CT perfusion if indicated) for LVO assessment.")
            case .present:
                hint("LVO present — see EVT eligibility below.", color: .blue)
            case .absent:
                hint("No LVO — EVT not indicated. Continue medical management per protocol.")
            }
        }
    }

    // MARK: - EVT card

    private var evtCard: some View {
        let verdict = state.evtVerdict(minutesSinceLKW: minutesSinceLKW, lkwUnknown: isLKWUnknown)
        let site = state.lvoSite ?? .unknown
        let mrs = state.baselineMRS ?? .unknown
        return card(title: "EVT eligibility", systemImage: "scissors") {
            if state.suggestsExtendedWindowEVT(minutesSinceLKW: minutesSinceLKW, lkwUnknown: isLKWUnknown) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "link")
                        .foregroundStyle(.blue)
                    Text("Late-window EVT criteria are documented on the Extended window card above. Consider neuro-IR discussion (training only).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            verdictBadge(verdict)

            HStack {
                Text("Occlusion site")
                    .font(.subheadline)
                Spacer()
                Picker("Occlusion site", selection: lvoSiteBinding) {
                    ForEach(LvoSite.allCases, id: \.self) { s in
                        Text(s.label).tag(s)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            evidenceBadge(for: site)
            Text(site.trainingNote)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            HStack {
                Text("Baseline mRS")
                    .font(.subheadline)
                Spacer()
                Picker("Baseline mRS", selection: baselineMrsBinding) {
                    ForEach(BaselineMRS.allCases, id: \.self) { m in
                        Text(m.label).tag(m)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Divider().padding(.vertical, 2)

            Text("Captured from workflow")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(state.evtStructuredCriteria(minutesSinceLKW: minutesSinceLKW, lkwUnknown: isLKWUnknown)) { row in
                evtStructuredCriterionRow(row)
            }

            let manual = state.evtManualCriteriaForDisplay()
            if !manual.isEmpty {
                Divider().padding(.vertical, 2)
                Text("Confirm")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                ForEach(manual) { c in
                    criterionRow(
                        criterion: c,
                        answer: state.evtCriteria[c.id] ?? .unknown,
                        onChange: { newValue in
                            store.mutateDecisions { $0.evtCriteria[c.id] = newValue }
                        }
                    )
                }
            }

            failedList(verdict)

            evtConsiderations2026

            HStack {
                Text("Plan (training):")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Plan", selection: evtBinding) {
                    ForEach(EvtChoice.allCases, id: \.self) { c in
                        Text(c.label).tag(c)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - EVT pickers + considerations helpers

    /// Pill that summarizes the evidence class for the chosen occlusion site.
    private func evidenceBadge(for site: LvoSite) -> some View {
        let evidence = site.evidenceClass
        let tint: Color = {
            switch evidence {
            case .classI:        return .green
            case .classIIa:      return .blue
            case .classIIb:      return .orange
            case .insufficient:  return .gray
            case .notSpecified:  return .gray
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: "stethoscope")
                .font(.caption2)
            Text("EVT evidence: \(evidence.label)")
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.18))
        .foregroundStyle(tint)
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func evtStructuredCriterionRow(_ row: EvtStructuredCriterion) -> some View {
        let statusIcon: String = {
            switch row.isMet {
            case .some(true): return "checkmark.circle.fill"
            case .some(false): return "xmark.circle.fill"
            case .none: return "questionmark.circle"
            }
        }()
        let statusColor: Color = {
            switch row.isMet {
            case .some(true): return .green
            case .some(false): return .orange
            case .none: return .secondary
            }
        }()
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.label)
                    .font(.caption.bold())
                Text(row.detail)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    /// Nuances not captured in structured fields or the short confirm list.
    private var evtConsiderations2026: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Additional nuances (2026, training)", systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(.purple)
            ForEach([
                "If IVT-eligible, give thrombolysis before EVT; do not skip IVT to expedite transfer (DIRECT-MT / SKIP).",
                "Low NIHSS (0–5) with disabling deficit (e.g., aphasia, hemianopia, neglect, weakness limiting gait or hand use): EVT may be reasonable (Class IIb). NIHSS 5 is still in the mild band — do not use a ≥6 cutoff to exclude treatment.",
                "Anesthesia (GA vs conscious sedation): Class IIa; institution- and patient-specific (SIESTA, GOLIATH, AnStroke)."
            ], id: \.self) { item in
                Text("• \(item)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Patient details card

    private var patientDetailsCard: some View {
        let aspectsCategory = AspectsCategory(score: state.aspectsScore ?? 10)
        let pcCategory = PcAspectsCategory(score: state.pcAspectsScore)

        return card(title: "Patient details", systemImage: "person.text.rectangle") {
            // Weight row — tap the field for direct numeric entry, use ± for
            // fine tuning, and tap the unit pill to switch between kg and lb.
            HStack(spacing: 10) {
                Text("Weight")
                    .font(.subheadline)
                Spacer()
                weightInputField
                Stepper("Weight",
                        value: displayedWeightBinding,
                        in: weightUnit.range,
                        step: 1)
                    .labelsHidden()
                    .fixedSize()
            }
            if weightUnit == .pounds, let kg = state.weightKg {
                Text("≈ \(kg) kg (used for dose calculation).")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Tap the value to type weight directly, use ± for ±1, or tap the unit to switch kg ↔ lb.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider().padding(.vertical, 2)

            // NIHSS row
            HStack {
                Text("NIHSS total")
                    .font(.subheadline)
                Spacer()
                if let n = state.nihssTotal {
                    Text("\(n)")
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(severityColor(nihss: n))
                } else {
                    Text("Not captured")
                        .font(.subheadline.italic())
                        .foregroundStyle(.secondary)
                }
            }
            Text("Capture from the Timeline tab → ‘Run NIHSS’.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if let n = state.nihssTotal, n <= DecisionState.mildNihssMax {
                Text("NIHSS \(n) is in the mild band (0–5). Classify disabling vs non-disabling below — NIHSS 5 does not by itself exclude IVT or EVT.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            Divider().padding(.vertical, 2)

            // ASPECTS row — always editable here regardless of imaging.
            // Defaults to 10 (normal NCCT); trainee dials down as findings emerge.
            HStack(spacing: 10) {
                Text("ASPECTS")
                    .font(.subheadline)
                Spacer()
                Text("\(state.aspectsScore ?? 10) / 10")
                    .font(.subheadline.monospacedDigit().bold())
                    .frame(minWidth: 70, alignment: .trailing)
                Stepper("ASPECTS", value: aspectsBinding, in: 0...10, step: 1)
                    .labelsHidden()
                    .fixedSize()
            }
            HStack {
                Text(aspectsCategory.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(aspectsBadgeColor(aspectsCategory).opacity(0.18))
                    .foregroundStyle(aspectsBadgeColor(aspectsCategory))
                    .clipShape(Capsule())
                Spacer()
                Button("Reset to 10") {
                    store.mutateDecisions { $0.aspectsScore = 10 }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled((state.aspectsScore ?? 10) == 10)
            }
            Text("Anterior-circulation MCA score (10 = normal). Use pc-ASPECTS for vertebrobasilar / PCA.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Divider().padding(.vertical, 2)

            HStack(spacing: 10) {
                Text("pc-ASPECTS")
                    .font(.subheadline)
                Spacer()
                Text("\(state.pcAspectsScore ?? 10) / 10")
                    .font(.subheadline.monospacedDigit().bold())
                    .frame(minWidth: 70, alignment: .trailing)
                Stepper("pc-ASPECTS", value: pcAspectsBinding, in: 0...10, step: 1)
                    .labelsHidden()
                    .fixedSize()
            }
            HStack {
                Text(pcCategory.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(pcAspectsBadgeColor(pcCategory).opacity(0.18))
                    .foregroundStyle(pcAspectsBadgeColor(pcCategory))
                    .clipShape(Capsule())
                Spacer()
                Button("Reset to 10") {
                    store.mutateDecisions { $0.pcAspectsScore = 10 }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled((state.pcAspectsScore ?? 10) == 10)
            }
            Text("Posterior-circulation score (thalami, cerebellum, PCA cortex, midbrain, pons). Used for basilar / PCA EVT.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func severityColor(nihss: Int) -> Color {
        switch nihss {
        case ...5: return .green
        case 6..<16: return .blue
        case 16..<21: return .orange
        default: return .red
        }
    }

    // MARK: - Mild stroke / disabling classification

    private var mildStrokeDisablingCard: some View {
        let status = state.deficitDisabling ?? .unknown
        let nihssLabel = state.nihssTotal.map { "NIHSS \($0)" } ?? "NIHSS not yet captured"
        return card(title: "Mild stroke — disabling vs non-disabling", systemImage: "figure.walk") {
            Text("AHA/ASA: NIHSS 0–5 is the mild band. IV alteplase is recommended for mild disabling symptoms (Class I) and is not recommended for mild non-disabling symptoms (Class III: No Benefit, PRISMS). NIHSS of 5 is still mild — there is no treat-if-≥6 cutoff.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text(nihssLabel)
                    .font(.caption.monospacedDigit().bold())
                Spacer()
                Picker("Deficit", selection: deficitDisablingBinding) {
                    ForEach(DeficitDisablingStatus.allCases, id: \.self) { s in
                        Text(s.label).tag(s)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Typically disabling (treat if otherwise eligible)")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                ForEach([
                    "Aphasia that impairs communication",
                    "Complete hemianopia or dense visual-field cut",
                    "Neglect / extinction",
                    "Weakness that limits unassisted walking",
                    "Weakness that limits use of the affected hand (especially dominant)",
                    "Any deficit that would prevent return to work or basic ADLs"
                ], id: \.self) { item in
                    Text("• \(item)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text("Typically non-disabling (do not treat with IVT)")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                ForEach([
                    "Isolated facial droop",
                    "Isolated mild dysarthria (still intelligible)",
                    "Isolated sensory symptoms without neglect",
                    "Isolated mild ataxia that does not affect gait",
                    "Very mild drift that does not limit walking or hand function"
                ], id: \.self) { item in
                    Text("• \(item)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(state.ivtDisablingAssessment().detail)
                .font(.caption2)
                .foregroundStyle(status == .nonDisabling ? .orange : .secondary)

            Text("Judgment is clinical, not score-only. Training reference: Powers WJ et al. Stroke. 2019; Khatri P et al. PRISMS, JAMA 2018.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var deficitDisablingBinding: Binding<DeficitDisablingStatus> {
        Binding(
            get: { state.deficitDisabling ?? .unknown },
            set: { newValue in
                store.mutateDecisions {
                    $0.deficitDisabling = newValue
                    $0.applyIVTDisablingFromCapturedDeficit(overwrite: true)
                }
            }
        )
    }

    // MARK: - Medical management (no IVT / no EVT)

    private var medicalManagementCard: some View {
        let interim = isMedicalManagementInterim
        let title = interim
            ? "Medical management — interim guidance"
            : "Medical management (no IVT / EVT)"
        let subtitle = interim
            ? "Suggested bundle while you work through the IVT / EVT branches. Commit to one of those branches above to refine this guidance."
            : "Training guidance when a (presumed) ischemic stroke patient is not proceeding to IV thrombolysis or EVT."

        return card(title: title, systemImage: "cross.case") {
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            ahaAsa2026RemindersBanner

            if let hint = antiplateletNihssHint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            mgmtSection(
                title: "Antiplatelet — when (no TNK / no EVT)",
                bullets: [
                    "Hemorrhage excluded and reperfusion not given: start antiplatelet promptly. Antiplatelets are not a substitute for IVT or EVT when those are indicated (Class III).",
                    "SAPT (Class I): aspirin 160–325 mg within 48 h of onset (IST / CAST), then 81 mg daily (or clopidogrel 75 mg if aspirin-intolerant). Use SAPT when DAPT criteria below are not met.",
                    "DAPT Class I (CHANCE / POINT): NIHSS ≤ 3 non-cardioembolic stroke OR high-risk TIA (ABCD² ≥ 4), no IVT, start within 24 h of onset. Aspirin + clopidogrel for 21 days, then SAPT. This is the default 2026 regimen for that population.",
                    "DAPT Class IIa, new 2026 (INSPIRES): NIHSS ≤ 5 or TIA ABCD² ≥ 4 at 24–72 h from onset, or NIHSS 4–5 within 24 h, no IVT, presumed large-artery atherosclerosis (≥50% intra- or extracranial stenosis that explains the event, or acute infarcts of LAA origin). Clopidogrel + aspirin × 21 days, then SAPT.",
                    "DAPT Class IIb (THALES): NIHSS ≤ 5, or TIA ABCD² ≥ 6, or symptomatic ≥50% stenosis; no IVT; <24 h. Ticagrelor + aspirin for 30 days may be considered (higher severe-bleeding risk).",
                    "CYP2C19 loss-of-function (CHANCE-2, Class IIb): NIHSS ≤ 3 or TIA ABCD² ≥ 4, no IVT, <24 h — ticagrelor + aspirin × 21 days then ticagrelor monotherapy may be preferred over clopidogrel DAPT.",
                    "Do not use DAPT for cardioembolic stroke (use anticoagulation). Do not add an antiplatelet to OAC in AF without active CAD or a recent stent (Class III: Harm). Triple antiplatelet therapy is not recommended (Class III: Harm). Ticagrelor monotherapy is not recommended over aspirin (SOCRATES, Class III: No Benefit)."
                ]
            )

            mgmtSection(
                title: "Antiplatelet — loading and maintenance doses",
                bullets: [
                    "Class I DAPT load: aspirin 162–325 mg once + clopidogrel 300 mg (CHANCE) or 600 mg (POINT). Then aspirin 81 mg daily + clopidogrel 75 mg daily for 21 days, then SAPT (aspirin 81 mg or clopidogrel 75 mg).",
                    "Limit this DAPT to 21 days even though POINT continued to 90 days — ischemic benefit concentrates in the first 3 weeks and bleeding continues thereafter.",
                    "INSPIRES load: clopidogrel 300 mg + aspirin 100–300 mg, then clopidogrel 75 mg + aspirin 81–100 mg × 21 days, then SAPT.",
                    "THALES: ticagrelor 180 mg load then 90 mg BID + aspirin 300–325 mg on day 1 then 75–100 mg daily, for 30 days.",
                    "CHANCE-2: ticagrelor 180 mg load then 90 mg BID + aspirin 75–300 mg load then 75 mg daily × 21 days, then ticagrelor monotherapy.",
                    "If IVT was given: do not give IV aspirin with or within 90 minutes of thrombolysis (Class III: Harm). Antiplatelet in the first 24 h after IVT is uncertain (Class IIb); usual training practice is to wait ~24 h and start after repeat imaging excludes hemorrhage."
                ]
            )

            mgmtSection(
                title: "Blood pressure",
                bullets: [
                    "If no IV thrombolysis: permissive HTN for the first 24–48 h. Treat only if BP > 220/120 mmHg or end-organ injury (lower ≈ 15% in the first 24 h).",
                    "If thrombolytic given: keep BP ≤ 180/105 mmHg for 24 h.",
                    "After 48–72 h or once stable: long-term target < 130/80 mmHg, individualize (AHA/ASA secondary-prevention)."
                ]
            )

            mgmtSection(
                title: "Lipids / statin (2026 update)",
                bullets: [
                    "Start high-intensity statin (atorvastatin 40–80 mg or rosuvastatin 20–40 mg) unless contraindicated.",
                    "LDL-C goal < 70 mg/dL for atherosclerotic stroke (AHA/ASA secondary prevention).",
                    "If LDL-C above goal on max statin: add ezetimibe; consider a PCSK9 inhibitor for very-high-risk patients."
                ]
            )

            mgmtSection(
                title: "Glycemic management",
                bullets: [
                    "Target glucose 140–180 mg/dL during hospitalization.",
                    "Treat hypoglycemia (< 60 mg/dL) promptly.",
                    "If T2DM with established ASCVD: consider an SGLT2 inhibitor or GLP-1 RA for cardiovascular risk reduction (outpatient)."
                ]
            )

            mgmtSection(
                title: "DVT prophylaxis",
                bullets: [
                    "Intermittent pneumatic compression on admission for non-ambulatory patients (CLOTS-3).",
                    "Add prophylactic-dose subcutaneous heparin / LMWH after 24 h if stable (and ≥ 24 h after thrombolysis)."
                ]
            )

            mgmtSection(
                title: "Bedside care",
                bullets: [
                    "Dysphagia screen before any oral intake (food, fluids, or medications).",
                    "Telemetry / continuous cardiac monitoring for ≥ 24 h (longer if cryptogenic and AF suspected).",
                    "Head-of-bed flat vs. 30°: individualize (HeadPoST showed no benefit either way); flat may be considered short-term for LVO awaiting EVT.",
                    "Early mobilization within 24–48 h once stable; PT / OT / speech consults."
                ]
            )

            mgmtSection(
                title: "Etiologic workup",
                bullets: [
                    "Vessel imaging (carotid US / CTA / MRA) if not yet done.",
                    "Echocardiogram (TTE; consider TEE / bubble study for cardioembolic source or suspected PFO).",
                    "≥ 24 h inpatient cardiac monitoring; prolonged outpatient monitoring (implantable loop recorder) if cryptogenic (CRYSTAL-AF / STROKE-AF / PER-DIEM).",
                    "Fasting lipid panel and HbA1c.",
                    "PFO closure: consider in cryptogenic embolic stroke, age < 60, after stroke / cardiology review (RESPECT, CLOSE, REDUCE)."
                ]
            )

            mgmtSection(
                title: "Secondary prevention",
                bullets: [
                    "Atrial fibrillation: start anticoagulation per protocol — typical timing is 1-3-6-12 days based on infarct size; avoid for 24 h after thrombolysis.",
                    "Smoking cessation; lifestyle counseling (Mediterranean / DASH diet, regular aerobic activity, weight management).",
                    "Symptomatic carotid stenosis 70–99%: CEA or CAS within 2 weeks if appropriate."
                ]
            )

            mgmtSection(
                title: "Post-stroke screening (often missed)",
                bullets: [
                    "Post-stroke depression screen (PHQ-9 or equivalent) before discharge and at follow-up.",
                    "Cognitive screen (MoCA) once medically stable.",
                    "Sleep-disordered breathing screen (STOP-BANG / formal sleep study if indicated).",
                    "Stroke / rehab planning before discharge; provide stroke-education materials and a written secondary-prevention plan."
                ]
            )

            Text("Education only. Follow your institution's protocol and the current AHA/ASA stroke guidelines.")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
                .padding(.top, 4)
        }
    }

    /// Training hint that maps a captured NIHSS to the 2026 DAPT vs SAPT branch
    /// when IVT / EVT are not being given.
    private var antiplateletNihssHint: String? {
        guard let n = state.nihssTotal else { return nil }
        if n <= 3 {
            return "Captured NIHSS \(n) (≤3): if non-cardioembolic, no IVT, and within 24 h of onset, 2026 Class I DAPT is aspirin + clopidogrel with a clopidogrel load for 21 days, then SAPT — not aspirin alone."
        }
        if n <= 5 {
            return "Captured NIHSS \(n) (4–5): CHANCE/POINT Class I DAPT does not apply (that cutoff is NIHSS ≤ 3). If no IVT and presumed large-artery atherosclerosis, INSPIRES Class IIa DAPT (clopidogrel + aspirin × 21 days) is reasonable; otherwise SAPT. Ticagrelor DAPT (THALES) is Class IIb."
        }
        return "Captured NIHSS \(n) (>5): short-course DAPT is not supported by CHANCE, POINT, or INSPIRES. Use SAPT (aspirin 160–325 mg, then 81 mg) unless another indication exists (e.g., stent)."
    }

    /// Quick "what's emphasized in 2026" reminders banner.
    private var ahaAsa2026RemindersBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("AHA/ASA 2026 emphasis", systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(.purple)
            ForEach([
                "LDL-C goal < 70 mg/dL for atherosclerotic stroke; add ezetimibe / PCSK9i if not met.",
                "Consider SGLT2i / GLP-1 RA in T2DM with ASCVD for outpatient cardiovascular risk reduction.",
                "Screen for post-stroke depression, cognitive impairment, and sleep-disordered breathing before discharge.",
                "For cryptogenic stroke: prolonged rhythm monitoring (ILR) and consider PFO closure if age < 60.",
                "No TNK / no EVT: NIHSS ≤ 3 (or high-risk TIA) within 24 h → Class I DAPT with clopidogrel load × 21 days; NIHSS 4–5 or 24–72 h with LAA → INSPIRES Class IIa DAPT; otherwise aspirin SAPT."
            ], id: \.self) { item in
                Text("• \(item)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func mgmtSection(title: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .padding(.top, 4)
            ForEach(bullets, id: \.self) { b in
                Text("• \(b)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Dosing card

    private var dosingCard: some View {
        let drug = state.thrombolyticChosen
        let weight = state.weightKg ?? 0
        let dose = computeThrombolyticDose(drug: drug, weightKg: weight)
        return card(title: "Dosing & administration", systemImage: "syringe.fill") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(drug == .tenecteplase ? "Tenecteplase (TNK)" : "Alteplase (rt-PA)")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(drug == .tenecteplase ? "0.25 mg/kg, max 25 mg" : "0.9 mg/kg, max 90 mg")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Text("Patient weight")
                    Spacer()
                    weightInputField
                    Stepper("Patient weight",
                            value: displayedWeightBinding,
                            in: weightUnit.range,
                            step: 1)
                        .labelsHidden()
                        .fixedSize()
                }

                if state.weightKg == nil {
                    Text("Set weight to compute dose.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else if let dose {
                    doseDisplay(dose)
                    administrationSteps(for: dose)
                }

                monitoringBlock
                    .padding(.top, 4)

                Text("Education only. Not for clinical dosing. Verify drug, dose, and contraindications against your institution's stroke protocol and the prescribing information.")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
        }
    }

    private func doseDisplay(_ dose: ThrombolyticDose) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Computed total")
                Spacer()
                Text(String(format: "%.1f mg", dose.totalMg))
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(.red)
            }
            if dose.cappedAtMax {
                Text("Capped at maximum dose.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            if let bolus = dose.bolusMg, let infusion = dose.infusionMg {
                HStack {
                    doseChip(label: "Bolus", value: String(format: "%.1f mg", bolus), tint: .blue)
                    doseChip(label: "Infusion (60 min)", value: String(format: "%.1f mg", infusion), tint: .purple)
                }
            } else {
                doseChip(label: "Single IV bolus (~5 s)", value: String(format: "%.1f mg", dose.totalMg), tint: .blue)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func doseChip(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(tint)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func administrationSteps(for dose: ThrombolyticDose) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Administration")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(dose.administrationSummary)
                .font(.caption)
            if dose.drug == .tenecteplase {
                Text("• Total: \(String(format: "%.1f", dose.totalMg)) mg single IV bolus over ~5 seconds.")
                    .font(.caption2)
            } else if let bolus = dose.bolusMg, let infusion = dose.infusionMg {
                Text("• Bolus \(String(format: "%.1f", bolus)) mg IV over 1 min.")
                    .font(.caption2)
                Text("• Then infuse \(String(format: "%.1f", infusion)) mg IV over 60 min.")
                    .font(.caption2)
            }
        }
    }

    private var monitoringBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Post-treatment monitoring")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(ThrombolyticDose.postTreatmentBullets, id: \.self) { b in
                Text("• \(b)")
                    .font(.caption2)
            }
        }
    }

    /// Canonical kg binding — stores directly to the active session.
    private var weightBinding: Binding<Int> {
        Binding(
            get: { state.weightKg ?? 75 },
            set: { newValue in
                // Permissive while typing (0–999 kg) so multi-digit entry
                // works naturally; commit clamp to 30–250 kg on focus loss.
                let v = max(0, min(999, newValue))
                store.mutateDecisions { $0.weightKg = v }
            }
        )
    }

    /// Binding shown in the user's preferred unit. Reads/writes via the
    /// canonical kg binding above, converting on every get/set.
    private var displayedWeightBinding: Binding<Int> {
        Binding(
            get: {
                let kg = state.weightKg ?? 75
                return weightUnit.displayedValue(forKg: kg)
            },
            set: { displayedValue in
                let clampedDisplay = max(0, min(999, displayedValue))
                let kg = weightUnit.kgValue(fromDisplayed: clampedDisplay)
                store.mutateDecisions { $0.weightKg = kg }
            }
        )
    }

    /// Reusable inline weight input: editable numeric text field, a kg/lb
    /// unit pill, and a "kg-equivalent" badge when entering in lb.
    private var weightInputField: some View {
        HStack(spacing: 6) {
            TextField(weightUnit.label, value: displayedWeightBinding, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.subheadline.monospacedDigit().bold())
                .frame(minWidth: 52, maxWidth: 72)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 0.5)
                )
                .onSubmit { clampWeightOnCommit() }

            Menu {
                Picker("Unit", selection: Binding(
                    get: { weightUnit },
                    set: { preferredWeightUnitRaw = $0.rawValue }
                )) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.verbose).tag(unit)
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    Text(weightUnit.label)
                        .font(.subheadline.bold())
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .accessibilityLabel("Weight unit (\(weightUnit.verbose))")
        }
    }

    /// Clamp weight to 30–250 kg on commit (focus loss / submit). Operates
    /// on the canonical kg storage.
    private func clampWeightOnCommit() {
        guard let w = store.active?.decisions?.weightKg else { return }
        let clamped = max(30, min(250, w))
        if clamped != w {
            store.mutateDecisions { $0.weightKg = clamped }
        }
    }

    // MARK: - ASPECTS "how to calculate" card

    /// Explains how the ASPECTS score is computed on a non-contrast head CT
    /// for anterior-circulation strokes. Training reference only.
    private var aspectsHowToCalculateCard: some View {
        card(title: "ASPECTS — How to calculate", systemImage: "list.number") {
            Text("ASPECTS (Alberta Stroke Program Early CT Score) is a 10-point topographic score that quantifies early ischemic changes (EIC) on a non-contrast head CT in the middle cerebral artery (MCA) territory.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Method")
                    .font(.subheadline.bold())
                aspectsStepBullet(num: "1", text: "Start at 10 points (normal CT).")
                aspectsStepBullet(num: "2", text: "Review two standardized axial NCCT slices in the MCA territory.")
                aspectsStepBullet(num: "3", text: "Subtract 1 point for each of the 10 MCA regions showing early ischemic change (focal hypoattenuation or loss of gray-white differentiation).")
                aspectsStepBullet(num: "4", text: "Compare with the contralateral hemisphere to detect subtle changes (insular ribbon sign, sulcal effacement).")
                aspectsStepBullet(num: "5", text: "Final score = 10 − number of affected regions. Range 0 (entire MCA infarcted) to 10 (normal).")
            }

            Divider().padding(.vertical, 2)

            aspectsDiagram

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Region names")
                    .font(.subheadline.bold())

                aspectsRegionGroupHeading("Ganglionic slice (basal-ganglia level) — 7 regions")
                aspectsRegionRow("C", "Caudate")
                aspectsRegionRow("L", "Lentiform nucleus")
                aspectsRegionRow("IC", "Internal capsule")
                aspectsRegionRow("I", "Insular ribbon (insular cortex)")
                aspectsRegionRow("M1", "Anterior MCA cortex (frontal operculum)")
                aspectsRegionRow("M2", "MCA cortex lateral to insular ribbon (anterior temporal)")
                aspectsRegionRow("M3", "Posterior MCA cortex (posterior temporal)")

                aspectsRegionGroupHeading("Supraganglionic slice (above basal ganglia) — 3 regions")
                aspectsRegionRow("M4", "Anterior MCA, superior to M1")
                aspectsRegionRow("M5", "Lateral MCA, superior to M2")
                aspectsRegionRow("M6", "Posterior MCA, superior to M3")
            }

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Interpretation (training)")
                    .font(.subheadline.bold())
                Text("• 8–10 = favorable; standard EVT candidacy (HERMES).")
                Text("• 6–7 = borderline; verify with neuroradiology.")
                Text("• 3–5 = large core; EVT may be considered in selected patients (SELECT2 / RESCUE-Japan LIMIT / ANGEL-ASPECT).")
                Text("• 0–2 = extensive infarct; EVT generally not recommended outside trials.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tips")
                    .font(.subheadline.bold())
                    .padding(.top, 4)
                Text("• ASPECTS is for anterior circulation only — use pc-ASPECTS (below) for the basilar/PCA territory.")
                Text("• Inter-rater variability is moderate; collaborate with neuroradiology when borderline.")
                Text("• DWI-ASPECTS (on MRI diffusion) is used in extended-window selection.")
                Text("• Subcortical and cortical regions are weighted equally — each affected region subtracts 1 point regardless of size.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("Source: Barber PA, Demchuk AM, Zhang J, Buchan AM. Validity and reliability of a quantitative computed tomography score in predicting outcome of hyperacute stroke before thrombolytic therapy. Lancet. 2000;355(9216):1670-1674.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    private func aspectsStepBullet(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.caption2.bold())
                .frame(width: 18, height: 18)
                .background(Color.blue.opacity(0.18))
                .foregroundStyle(.blue)
                .clipShape(Circle())
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func aspectsRegionGroupHeading(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.purple)
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func aspectsRegionRow(_ code: String, _ name: String) -> some View {
        HStack(spacing: 8) {
            Text(code)
                .font(.caption2.monospaced().bold())
                .frame(minWidth: 36, alignment: .center)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.14))
                .foregroundStyle(.purple)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - ASPECTS visual diagram

    /// Standard ASPECTS template (ganglionic + supraganglionic slices, all 10
    /// regions labeled). Image: Schröder & Thomalla, Front Neurol 2017,
    /// Figure 2 (CC BY 4.0); template originally from Barber et al., Lancet 2000.
    private static let aspectsDiagramPMCURL = URL(string: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5226934/")!

    private var aspectsDiagram: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MCA territory — region map")
                .font(.subheadline.bold())

            Text("Ganglionic slice (left): C, L, IC, I, M1, M2, M3. Supraganglionic slice (right): M4, M5, M6. Subtract 1 point per region with early ischemic change.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Image("AspectsTemplate")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                )
                .accessibilityLabel("ASPECTS template showing ganglionic and supraganglionic axial slices with regions C, L, IC, I, M1 through M6 labeled")

            Link(destination: Self.aspectsDiagramPMCURL) {
                Text("Diagram source: Schröder & Thomalla, Front Neurol 2017 (CC BY 4.0) — PMC5226934, Figure 2")
            }
            .font(.caption2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - ASPECTS training-notes card

    /// Detailed training notes for ASPECTS. The numeric score is set in the
    /// Patient details card above; this card only renders the category badge
    /// and the IVT/EVT training notes.
    private var aspectsCard: some View {
        let score = state.aspectsScore ?? 10
        let category = AspectsCategory(score: score)
        return card(title: "ASPECTS — Decision notes", systemImage: "viewfinder.circle") {
            Text("ASPECTS (Alberta Stroke Program Early CT Score) quantifies early ischemic changes on non-contrast CT for anterior-circulation strokes (10 = normal). Set the score in Patient details above.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text("Current")
                Spacer()
                Text("\(score) / 10")
                    .font(.subheadline.monospacedDigit().bold())
                Text(category.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(aspectsBadgeColor(category).opacity(0.18))
                    .foregroundStyle(aspectsBadgeColor(category))
                    .clipShape(Capsule())
            }

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("EVT / IVT notes")
                    .font(.subheadline.bold())
                Text(category.evtTrainingNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(category.ivtTrainingNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Full EVT candidacy summary is on the EVT eligibility card when LVO is present.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func aspectsBadgeColor(_ c: AspectsCategory) -> Color {
        switch c {
        case .notAssessed:      return .secondary
        case .favorable:        return .green
        case .borderline:       return .blue
        case .largeCore:        return .orange
        case .extensiveInfarct: return .red
        }
    }

    private var aspectsBinding: Binding<Int> {
        Binding<Int>(
            get: { state.aspectsScore ?? 10 },
            set: { newValue in
                store.mutateDecisions { $0.aspectsScore = max(0, min(10, newValue)) }
                store.applyExtendedWindowEVTHintsIfApplicable()
            }
        )
    }

    private var pcAspectsBinding: Binding<Int> {
        Binding<Int>(
            get: { state.pcAspectsScore ?? 10 },
            set: { newValue in
                store.mutateDecisions { $0.pcAspectsScore = max(0, min(10, newValue)) }
            }
        )
    }

    private func pcAspectsBadgeColor(_ c: PcAspectsCategory) -> Color {
        switch c {
        case .notAssessed: return .secondary
        case .favorable:   return .green
        case .borderline:  return .blue
        case .extensive:   return .red
        }
    }

    // MARK: - pc-ASPECTS how to calculate

    private var pcAspectsHowToCalculateCard: some View {
        card(title: "pc-ASPECTS — How to calculate", systemImage: "list.number") {
            Text("pc-ASPECTS (posterior-circulation Alberta Stroke Program Early CT Score) is a 10-point topographic score of early ischemic change in the vertebrobasilar territory on NCCT or CTA source images.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Method")
                    .font(.subheadline.bold())
                aspectsStepBullet(num: "1", text: "Start at 10 points (normal scan).")
                aspectsStepBullet(num: "2", text: "Review brainstem, cerebellar, thalamic, and occipital slices.")
                aspectsStepBullet(num: "3", text: "Subtract the points listed below for each region with early ischemic change (hypoattenuation or loss of gray-white differentiation). Midbrain and pons are worth 2 points each.")
                aspectsStepBullet(num: "4", text: "Final score = 10 − points deducted. Range 0 (extensive posterior infarct) to 10 (normal).")
            }

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Typical slices to review")
                    .font(.subheadline.bold())
                Text("Pons and cerebellar hemispheres; midbrain; thalami and occipital / PCA cortex.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Regions (10 points)")
                    .font(.subheadline.bold())
                aspectsRegionGroupHeading("1 point each")
                aspectsRegionRow("Th L", "Left thalamus")
                aspectsRegionRow("Th R", "Right thalamus")
                aspectsRegionRow("Cbl L", "Left cerebellum")
                aspectsRegionRow("Cbl R", "Right cerebellum")
                aspectsRegionRow("PCA L", "Left occipital / PCA cortex")
                aspectsRegionRow("PCA R", "Right occipital / PCA cortex")
                aspectsRegionGroupHeading("2 points each")
                aspectsRegionRow("MB", "Midbrain")
                aspectsRegionRow("Pons", "Pons")
            }

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Interpretation (training)")
                    .font(.subheadline.bold())
                Text("• 8–10 = favorable posterior-circulation core.")
                Text("• 6–7 = borderline; within BAOCHE / ATTENTION enrollment (pc-ASPECTS ≥ 6).")
                Text("• 0–5 = extensive; EVT generally not recommended.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("Scoring method: Puetz V et al. Stroke. 2008;39(9):2485-2490.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    private var pcAspectsCard: some View {
        let score = state.pcAspectsScore ?? 10
        let category = PcAspectsCategory(score: score)
        return card(title: "pc-ASPECTS — Decision notes", systemImage: "hexagon") {
            Text("Use pc-ASPECTS instead of (or in addition to) anterior ASPECTS when the suspected or confirmed occlusion is basilar, vertebral, or PCA. Set the score in Patient details.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text("Current")
                Spacer()
                Text("\(score) / 10")
                    .font(.subheadline.monospacedDigit().bold())
                Text(category.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(pcAspectsBadgeColor(category).opacity(0.18))
                    .foregroundStyle(pcAspectsBadgeColor(category))
                    .clipShape(Capsule())
            }

            Divider().padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("EVT / IVT notes")
                    .font(.subheadline.bold())
                Text(category.evtTrainingNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(category.ivtTrainingNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("When LVO site is basilar, PCA, or VA, the EVT card uses pc-ASPECTS as the infarct-core row.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 3–4.5 h IV thrombolysis card

    /// Show the 3–4.5 h extended-early-window IVT card when the patient is
    /// (or has been) within that window since LKW.
    private var shouldShowExtendedEarlyIvt: Bool {
        guard !isLKWUnknown, let mins = minutesSinceLKW else { return false }
        return mins >= 180.0 && mins <= 540.0   // surface from 3 h through 9 h
    }

    private var extendedEarlyIvtCard: some View {
        let lkw = store.active?.lastKnownWell
        let minutesSinceLKW = lkw.map { Date().timeIntervalSince($0) / 60.0 }
        let inWindow = (minutesSinceLKW ?? 0) >= 180.0 && (minutesSinceLKW ?? 0) <= 270.0
        let ee = state.extendedEarlyIvt ?? .empty
        let verdict = ee.verdict(minutesSinceLKW: minutesSinceLKW)

        return card(title: "3–4.5 h IV thrombolysis (extended early window)",
                    systemImage: "clock.arrow.circlepath") {

            if let mins = minutesSinceLKW {
                HStack {
                    Text("Time since LKW")
                    Spacer()
                    Text(formatMinutes(mins))
                        .font(.subheadline.monospacedDigit().bold())
                }
                Text(inWindow
                     ? "Currently in the 3–4.5 h IV thrombolysis window. ECASS-3 historically added the criteria below; 2018/2019 AHA/ASA (reaffirmed) relaxed most of them."
                     : "Outside the 3–4.5 h window. Criteria shown for training reference.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Capture Last known well on the Timeline tab to surface 3–4.5 h training notes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.vertical, 2)

            // Relative cautions (relaxed in 2018/2019 AHA/ASA)
            VStack(alignment: .leading, spacing: 6) {
                Text("Historical exclusions — now relative cautions (Class IIb)")
                    .font(.subheadline.bold())
                Toggle(isOn: earlyIvtBinding(\.ageOver80)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Age > 80").font(.caption)
                        Text("IV alteplase is reasonable in patients > 80 (Class IIb).")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Toggle(isOn: earlyIvtBinding(\.nihssOver25)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NIHSS > 25").font(.caption)
                        Text("Severity is not a strict cutoff; alteplase may be considered (Class IIb). Weigh ICH risk.")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Toggle(isOn: earlyIvtBinding(\.priorStrokeAndDiabetes)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prior stroke + diabetes mellitus").font(.caption)
                        Text("Combined exclusion was relaxed; alteplase is reasonable (Class IIb).")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }

            // Hard contraindications (still excluded in 3–4.5 h)
            VStack(alignment: .leading, spacing: 6) {
                Text("Still hard contraindications")
                    .font(.subheadline.bold())
                Toggle(isOn: earlyIvtBinding(\.anticoagNOACwithin48h)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DOAC / NOAC within last 48 h").font(.caption)
                        Text("Apixaban, rivaroxaban, edoxaban, dabigatran. IVT contraindicated unless reliable lab evidence of non-therapeutic effect.")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Toggle(isOn: earlyIvtBinding(\.anticoagWarfarinINRover1_7)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Warfarin with INR > 1.7").font(.caption)
                        Text("IVT contraindicated; INR > 1.7 (or PT > 15 s) is an absolute exclusion.")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.top, 2)

            Divider().padding(.vertical, 2)

            HStack {
                Text("Verdict")
                Spacer()
                Text(verdict.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(earlyIvtBadgeColor(verdict).opacity(0.18))
                    .foregroundStyle(earlyIvtBadgeColor(verdict))
                    .clipShape(Capsule())
            }

            switch verdict {
            case .relativeCautions(let reasons),
                 .hardContraindication(let reasons):
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(reasons, id: \.self) { r in
                        Text("• \(r)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            case .notInWindow, .noAdditionalConcerns:
                EmptyView()
            }

            Text("TNK note: in 3–4.5 h, IV tenecteplase 0.25 mg/kg (max 25 mg) is supported by 2024–2026 RCT evidence (AcT, TASTE-A, TIMELESS) and adopted by many centers; some institutions still prefer alteplase. Follow local protocol.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)

            Text("Educational only. Source: ECASS-3 (NEJM 2008) and AHA/ASA 2018/2019 IV alteplase recommendations; not a clinical decision tool.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func earlyIvtBadgeColor(_ v: ExtendedEarlyIvtVerdict) -> Color {
        switch v {
        case .notInWindow:           return .secondary
        case .noAdditionalConcerns:  return .green
        case .relativeCautions:      return .orange
        case .hardContraindication:  return .red
        }
    }

    private func earlyIvtBinding(_ keyPath: WritableKeyPath<ExtendedEarlyIvtState, Bool>) -> Binding<Bool> {
        Binding<Bool>(
            get: { (state.extendedEarlyIvt ?? .empty)[keyPath: keyPath] },
            set: { newValue in
                store.mutateDecisions { d in
                    var ee = d.extendedEarlyIvt ?? .empty
                    ee[keyPath: keyPath] = newValue
                    d.extendedEarlyIvt = ee
                }
            }
        )
    }

    // MARK: - Extended window card

    private var extendedWindowCard: some View {
        let minutes = minutesSinceLKW
        let ew = state.extendedWindow ?? .empty
        let verdict = ew.verdict(minutesSinceLKW: minutes, lkwUnknown: isLKWUnknown)

        return card(title: "Extended window (late presentation / wake-up)",
                    systemImage: "clock.badge.exclamationmark") {

            if isLKWUnknown {
                HStack {
                    Text("Time since LKW")
                    Spacer()
                    Text("Unknown")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }
                Text("Unknown LKW (found down / no historian). Use DWI-FLAIR or perfusion mismatch for IVT (WAKE-UP / EXTEND) and DAWN / DEFUSE-3 / large-core criteria for EVT.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let mins = minutes {
                HStack {
                    Text("Time since LKW")
                    Spacer()
                    Text(formatMinutes(mins))
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(.primary)
                }
                Text(windowDescriptor(mins: mins))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Capture Last known well on the Timeline tab, or mark LKW unknown, to evaluate extended-window eligibility.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.vertical, 2)

            // Advanced imaging anchor
            Toggle(isOn: extendedBinding(\.advancedImagingDone)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Advanced imaging performed")
                        .font(.subheadline)
                    Text("MRI DWI/FLAIR, or CT / MR perfusion.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // IVT extended (4.5–9h / wake-up)
            VStack(alignment: .leading, spacing: 6) {
                Text("IVT extended window (4.5–9 h or wake-up)")
                    .font(.subheadline.bold())
                Toggle(isOn: extendedBinding(\.dwiFlairMismatch)) {
                    Text("DWI-FLAIR mismatch present (WAKE-UP)")
                        .font(.caption)
                }
                .disabled(!ew.advancedImagingDone)
                Toggle(isOn: extendedBinding(\.perfusionMismatchIvt)) {
                    Text("CTP/MRP mismatch with small core (EXTEND / EPITHET)")
                        .font(.caption)
                }
                .disabled(!ew.advancedImagingDone)
            }
            .padding(.top, 2)

            // EVT extended (6–24h)
            VStack(alignment: .leading, spacing: 6) {
                Text("EVT extended window (6–24 h)")
                    .font(.subheadline.bold())
                Toggle(isOn: extendedBinding(\.dawnMismatch)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DAWN clinical-core mismatch met")
                            .font(.caption)
                        Text("Age ≥80: NIHSS ≥10 & core <21 mL · Age <80: NIHSS ≥10 & core <31 mL, or NIHSS ≥20 & core <51 mL.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(!ew.advancedImagingDone)
                Toggle(isOn: extendedBinding(\.defuse3Mismatch)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DEFUSE-3 imaging mismatch met")
                            .font(.caption)
                        Text("Core <70 mL, mismatch ratio ≥1.8, mismatch volume ≥15 mL.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(!ew.advancedImagingDone)
                Toggle(isOn: extendedBinding(\.largeCoreEvtCandidate)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Large-core EVT candidate (ASPECTS 3–5)")
                            .font(.caption)
                        Text("SELECT2 / RESCUE-Japan LIMIT / ANGEL-ASPECT — selected patients.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(!ew.advancedImagingDone)
            }
            .padding(.top, 2)

            Divider().padding(.vertical, 2)

            HStack {
                Text("Verdict")
                Spacer()
                Text(verdict.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(extendedBadgeColor(verdict).opacity(0.18))
                    .foregroundStyle(extendedBadgeColor(verdict))
                    .clipShape(Capsule())
            }

            if verdict.suggestsEVTDiscussion {
                extendedWindowEvtLinkedBanner(minutesSinceLKW: minutes, lkwUnknown: isLKWUnknown, emphasizeNextSteps: true)
            }

            Text("Educational summary of WAKE-UP, EXTEND, EPITHET (IVT extended), DAWN, DEFUSE-3 (EVT 6–24 h), and SELECT2 / RESCUE-Japan LIMIT / ANGEL-ASPECT (large-core EVT). Not a clinical decision tool.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }

    /// Training banner linking late-window imaging criteria to EVT workflow.
    private func extendedWindowEvtLinkedBanner(minutesSinceLKW: Double?,
                                               lkwUnknown: Bool = false,
                                               emphasizeNextSteps: Bool = false) -> some View {
        let ew = state.extendedWindow ?? .empty
        let trials = ew.evtTrialLabelsMet
        let trialText = trials.isEmpty
            ? "Late-window EVT criteria selected"
            : "Criteria met: " + trials.joined(separator: ", ")
        let timingText: String = {
            if lkwUnknown { return "unknown LKW with imaging selection" }
            if let mins = minutesSinceLKW { return "\(formatMinutes(mins)) since LKW" }
            return "timing not captured"
        }()

        return VStack(alignment: .leading, spacing: 6) {
            Label("Consider EVT discussion (training)", systemImage: "person.2.wave.2.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
            Text("Based on specialized imaging (\(timingText)), this profile supports considering endovascular thrombectomy with your stroke team and neuro-interventional radiology. This is not a treatment order.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(trialText)
                .font(.caption.bold())
                .foregroundStyle(.blue)
            if emphasizeNextSteps {
                Text("Next: set LVO on the vascular imaging card, then open EVT eligibility for the captured summary and any remaining confirm items.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Shown when extended-window EVT criteria are met but LVO is not yet set.
    private var extendedWindowEvtBridgeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Extended-window EVT — next step", systemImage: "arrow.down.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)
            extendedWindowEvtLinkedBanner(minutesSinceLKW: minutesSinceLKW, lkwUnknown: isLKWUnknown, emphasizeNextSteps: true)
            Text("Set LVO to “LVO present” on the vascular imaging card above to open the full EVT eligibility checklist and training plan.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func extendedBadgeColor(_ v: ExtendedWindowVerdict) -> Color {
        switch v {
        case .notApplicable:  return .secondary
        case .ivtCandidate:   return .blue
        case .evtCandidate:   return .blue
        case .bothCandidate:  return .green
        case .noCriteriaMet:  return .orange
        }
    }

    private func extendedBinding(_ keyPath: WritableKeyPath<ExtendedWindowState, Bool>) -> Binding<Bool> {
        Binding<Bool>(
            get: { (state.extendedWindow ?? .empty)[keyPath: keyPath] },
            set: { newValue in
                store.mutateDecisions { d in
                    var ew = d.extendedWindow ?? .empty
                    ew[keyPath: keyPath] = newValue
                    d.extendedWindow = ew
                }
                store.applyExtendedWindowEVTHintsIfApplicable()
                store.applyIVTTimeWindowHintsIfApplicable()
            }
        )
    }

    private func windowDescriptor(mins: Double) -> String {
        switch mins {
        case ..<270:    return "Within standard IVT window (≤ 4.5 h). Extended-window criteria not required."
        case 270..<360: return "Within IVT extended window (4.5–6 h). Within standard EVT window."
        case 360..<540: return "IVT extended window (up to 9 h with mismatch). EVT extended window (DAWN / DEFUSE-3 selection)."
        case 540..<1440: return "Past IVT windows. EVT extended window (6–24 h) by mismatch selection."
        default:        return "Past 24 h — outside conventional reperfusion windows. Focus on medical management and secondary prevention."
        }
    }

    private func formatMinutes(_ totalMins: Double) -> String {
        let m = max(0, Int(totalMins.rounded()))
        let h = m / 60
        let r = m % 60
        return h > 0 ? String(format: "%dh %02dm", h, r) : String(format: "%d min", r)
    }

    // MARK: - Consent / family-explanation card

    /// Plain-language consent script for IV thrombolysis (training only).
    /// Shown when the trainee has chosen alteplase or tenecteplase. Each
    /// section can be played aloud via TTS in the selected patient language.
    private var consentCard: some View {
        let sections = ConsentScriptCatalog.script(for: state.thrombolyticChosen)
        let language = languageStore.selectedLanguage

        return card(title: "Consent script (training)", systemImage: "text.bubble.fill") {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Practice reading this to the patient or family")
                        .font(.subheadline.bold())
                    Text("Plain-language explanation for IV thrombolysis. Training aid only — your institution's informed-consent form and process still apply, and a qualified medical interpreter should be used for non-English speakers.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .background(Color.orange.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Text("Language: \(language.displayName)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    if spanishSpeech.isSpeaking {
                        spanishSpeech.stop()
                    } else {
                        // Play all sections sequentially as a single utterance.
                        let combined = sections
                            .map { $0.text(for: language) }
                            .joined(separator: " ")
                        spanishSpeech.speak(combined, language: language)
                    }
                } label: {
                    Label(spanishSpeech.isSpeaking ? "Stop" : "Read all aloud",
                          systemImage: spanishSpeech.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.orange)
            }

            ForEach(sections) { section in
                consentSectionRow(section, language: language)
            }

            ivtConsentPatientResponseSection(language: language)

            Text("Document consent per your institution's protocol. This script does NOT replace your hospital's consent form.")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
                .padding(.top, 4)
        }
    }

    /// Record the patient's yes/no/uncertain answer after the consent script (Spanish / Creole / English).
    private func ivtConsentPatientResponseSection(language: AppLanguage) -> some View {
        let response = patientResponse.responseForIvtConsent()
        let isRecording = patientResponse.isRecordingIvtConsent()
        let languageLabel = language == .haitianCreole ? "Creole" : language.displayName

        return VStack(alignment: .leading, spacing: 8) {
            Text("Record patient's answer to consent")
                .font(.subheadline.bold())
            Text("After reading the script, record whether the patient agrees to IV thrombolysis (\(languageLabel) → English). Training aid only.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                if isRecording {
                    patientResponse.stopRecording()
                } else {
                    patientResponse.requestAuthorization { granted in
                        if granted {
                            patientResponse.startRecording(key: "ivt-consent", language: language)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title3)
                    Text(isRecording ? "Stop recording" : "Record consent answer")
                        .font(.caption.bold())
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(isRecording ? Color.red.opacity(0.2) : Color.green.opacity(0.12))
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(patientResponse.authorizationStatus == .denied
                      || (patientResponse.isRecording && !isRecording))

            if !response.transcribed.isEmpty || !response.translated.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    if !response.transcribed.isEmpty {
                        Text("Patient said: \(response.transcribed)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !response.translated.isEmpty {
                        Text(response.translated)
                            .font(.caption.bold())
                    }
                    consentInterpretationBadge(patientResponse.ivtConsentInterpretation)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func consentInterpretationBadge(_ interpretation: IvtConsentInterpretation) -> some View {
        let (text, color): (String, Color) = {
            switch interpretation {
            case .agrees: return ("Agrees", .green)
            case .refuses: return ("Declines", .red)
            case .uncertain: return ("Uncertain", .orange)
            case .unclear: return ("Review manually", .secondary)
            }
        }()
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func consentSectionRow(_ section: ConsentSection, language: AppLanguage) -> some View {
        let text = section.text(for: language)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: section.systemImage)
                    .foregroundStyle(.orange)
                Text(section.heading)
                    .font(.subheadline.bold())
                Spacer()
                Button {
                    if spanishSpeech.isSpeaking {
                        spanishSpeech.stop()
                    } else {
                        spanishSpeech.speak(text, language: language)
                    }
                } label: {
                    Image(systemName: spanishSpeech.isSpeaking
                          ? "stop.circle.fill"
                          : "speaker.wave.2.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Read \(section.heading) aloud")
            }
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 22)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - References card

    /// Curated list of trials, guidelines, and content sources used to build
    /// the decision support, dosing, and patient-facing content throughout
    /// the app. Each section is collapsed by default to keep the card
    /// compact. Training reference only.
    private var appReferencesCard: some View {
        card(title: "References & sources", systemImage: "book.closed") {
            Text("Trials, guidelines, and content sources that informed the decision support, dosing notes, and patient-facing materials in this app. Tap a group to expand.")
                .font(.caption)
                .foregroundStyle(.secondary)

            referenceGroup(title: "NIH Stroke Scale (NIHSS)") {
                referenceItem(
                    title: "NIH Stroke Scale (March 2025)",
                    citation: "NINDS / NIH Stroke Scale, March 2025 edition. National Institute of Neurological Disorders and Stroke.",
                    url: "https://www.ninds.nih.gov/health-information/public-education/know-stroke/health-professionals/nih-stroke-scale"
                )
                referenceItem(
                    title: "Spanish NIHSS Item 9 figures",
                    citation: "Mayo Clinic Proceedings. 2006;81(4):476-480.",
                    url: nil
                )
                referenceItem(
                    title: "Original NIHSS",
                    citation: "Brott T et al. Measurements of acute cerebral infarction: a clinical examination scale. Stroke. 1989;20(7):864-870.",
                    url: nil
                )
            }

            referenceGroup(title: "IV thrombolysis") {
                referenceItem(
                    title: "Alteplase 0–3 h (NINDS)",
                    citation: "The NINDS rt-PA Stroke Study Group. Tissue plasminogen activator for acute ischemic stroke. NEJM. 1995;333(24):1581-1587.",
                    url: nil
                )
                referenceItem(
                    title: "Alteplase 3–4.5 h (ECASS-3)",
                    citation: "Hacke W et al. NEJM. 2008;359(13):1317-1329.",
                    url: nil
                )
                referenceItem(
                    title: "Tenecteplase 0–4.5 h (AcT)",
                    citation: "Menon BK et al. Lancet. 2022;400(10347):161-169.",
                    url: nil
                )
                referenceItem(
                    title: "Tenecteplase (TASTE-A)",
                    citation: "Bivard A et al. Lancet Neurology. 2022;21(6):520-527.",
                    url: nil
                )
                referenceItem(
                    title: "Tenecteplase late window (TIMELESS)",
                    citation: "Albers GW et al. NEJM. 2024;390(8):701-711.",
                    url: nil
                )
                referenceItem(
                    title: "Mild non-disabling stroke (PRISMS)",
                    citation: "Khatri P et al. Effect of alteplase vs aspirin on functional outcome for patients with acute ischemic stroke and minor nondisabling neurologic deficits: the PRISMS randomized clinical trial. JAMA. 2018;320(2):156-166. Informs the AHA/ASA Class III: No Benefit recommendation for NIHSS 0–5 non-disabling stroke.",
                    url: nil
                )
            }

            referenceGroup(title: "Endovascular therapy (EVT, 0–6 h)") {
                referenceItem(
                    title: "HERMES meta-analysis",
                    citation: "Goyal M et al. Lancet. 2016;387(10029):1723-1731.",
                    url: nil
                )
                referenceItem(
                    title: "MR CLEAN",
                    citation: "Berkhemer OA et al. NEJM. 2015;372(1):11-20.",
                    url: nil
                )
                referenceItem(
                    title: "ESCAPE",
                    citation: "Goyal M et al. NEJM. 2015;372(11):1019-1030.",
                    url: nil
                )
                referenceItem(
                    title: "SWIFT PRIME",
                    citation: "Saver JL et al. NEJM. 2015;372(24):2285-2295.",
                    url: nil
                )
                referenceItem(
                    title: "EXTEND-IA",
                    citation: "Campbell BCV et al. NEJM. 2015;372(11):1009-1018.",
                    url: nil
                )
                referenceItem(
                    title: "REVASCAT",
                    citation: "Jovin TG et al. NEJM. 2015;372(24):2296-2306.",
                    url: nil
                )
                referenceItem(
                    title: "IVT before EVT (DIRECT-MT)",
                    citation: "Yang P et al. NEJM. 2020;382(21):1981-1993.",
                    url: nil
                )
                referenceItem(
                    title: "IVT before EVT (SKIP)",
                    citation: "Suzuki K et al. JAMA. 2021;325(3):244-253.",
                    url: nil
                )
            }

            referenceGroup(title: "Extended / wake-up window") {
                referenceItem(
                    title: "WAKE-UP (DWI-FLAIR mismatch, IVT)",
                    citation: "Thomalla G et al. NEJM. 2018;379(7):611-622.",
                    url: nil
                )
                referenceItem(
                    title: "EXTEND (perfusion mismatch IVT 4.5–9 h)",
                    citation: "Ma H et al. NEJM. 2019;380(19):1795-1803.",
                    url: nil
                )
                referenceItem(
                    title: "EPITHET",
                    citation: "Davis SM et al. Lancet Neurology. 2008;7(4):299-309.",
                    url: nil
                )
                referenceItem(
                    title: "DAWN (EVT 6–24 h, clinical-core mismatch)",
                    citation: "Nogueira RG et al. NEJM. 2018;378(1):11-21.",
                    url: nil
                )
                referenceItem(
                    title: "DEFUSE-3 (EVT 6–16 h, perfusion mismatch)",
                    citation: "Albers GW et al. NEJM. 2018;378(8):708-718.",
                    url: nil
                )
            }

            referenceGroup(title: "Large-core EVT (2022–2023)") {
                referenceItem(
                    title: "SELECT2",
                    citation: "Sarraj A et al. NEJM. 2023;388(14):1259-1271.",
                    url: nil
                )
                referenceItem(
                    title: "RESCUE-Japan LIMIT",
                    citation: "Yoshimura S et al. NEJM. 2022;386(14):1303-1313.",
                    url: nil
                )
                referenceItem(
                    title: "ANGEL-ASPECT",
                    citation: "Huo X et al. NEJM. 2023;388(14):1272-1283.",
                    url: nil
                )
            }

            referenceGroup(title: "ASPECTS") {
                referenceItem(
                    title: "Original ASPECTS",
                    citation: "Barber PA, Demchuk AM, Zhang J, Buchan AM. Lancet. 2000;355(9216):1670-1674.",
                    url: nil
                )
                referenceItem(
                    title: "ASPECTS region diagram (in-app)",
                    citation: "Schröder J, Thomalla G. Front Neurol. 2017;7:245. Figure 2 (CC BY 4.0). PMC5226934.",
                    url: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5226934/"
                )
                referenceItem(
                    title: "pc-ASPECTS (posterior circulation)",
                    citation: "Puetz V et al. Extent of hypoattenuation on CT angiography source images predicts functional outcome in patients with basilar artery occlusion. Stroke. 2008;39(9):2485-2490.",
                    url: nil
                )
                referenceItem(
                    title: "Basilar EVT (ATTENTION)",
                    citation: "Jovin TG et al. Trial of endovascular treatment of acute basilar-artery occlusion. NEJM. 2022;387:1361-1372. Enrollment typically pc-ASPECTS ≥ 6.",
                    url: nil
                )
                referenceItem(
                    title: "Basilar EVT (BAOCHE)",
                    citation: "Tao C et al. Trial of endovascular treatment of acute basilar-artery occlusion. NEJM. 2022;387:1373-1384.",
                    url: nil
                )
            }

            referenceGroup(title: "Anesthesia for EVT") {
                referenceItem(
                    title: "SIESTA",
                    citation: "Schönenberger S et al. JAMA. 2016;316(19):1986-1996.",
                    url: nil
                )
                referenceItem(
                    title: "GOLIATH",
                    citation: "Simonsen CZ et al. JAMA Neurology. 2018;75(4):470-477.",
                    url: nil
                )
                referenceItem(
                    title: "AnStroke",
                    citation: "Löwhagen Hendén P et al. Stroke. 2017;48(6):1601-1607.",
                    url: nil
                )
            }

            referenceGroup(title: "Antiplatelet / DAPT") {
                referenceItem(
                    title: "CHANCE",
                    citation: "Wang Y et al. Clopidogrel with aspirin in acute minor stroke or high-risk TIA. NEJM. 2013;369(1):11-19. Clopidogrel 300 mg load then 75 mg + aspirin × 21 days.",
                    url: nil
                )
                referenceItem(
                    title: "POINT",
                    citation: "Johnston SC et al. Clopidogrel and aspirin in acute ischemic stroke and high-risk TIA. NEJM. 2018;379(3):215-225. Clopidogrel 600 mg load; 2026 guidance still limits DAPT to 21 days.",
                    url: nil
                )
                referenceItem(
                    title: "INSPIRES (2026 Class IIa expansion)",
                    citation: "Gao Y et al. Dual antiplatelet treatment up to 72 hours after ischemic stroke. NEJM. 2023;389:2413-2424. NIHSS ≤ 5 / 24–72 h or NIHSS 4–5 within 24 h, presumed atherosclerosis; clopidogrel 300 mg load + aspirin × 21 days.",
                    url: nil
                )
                referenceItem(
                    title: "THALES (ticagrelor)",
                    citation: "Johnston SC et al. Ticagrelor and aspirin or aspirin alone in acute ischemic stroke or TIA. NEJM. 2020;383(3):207-217. Ticagrelor 180 mg load then 90 mg BID + aspirin × 30 days.",
                    url: nil
                )
                referenceItem(
                    title: "CHANCE-2 (CYP2C19)",
                    citation: "Wang Y et al. Ticagrelor versus clopidogrel in CYP2C19 loss-of-function carriers with stroke or TIA. NEJM. 2021;385:2520-2530.",
                    url: nil
                )
                referenceItem(
                    title: "AHA/ASA 2026 AIS guideline §4.8",
                    citation: "Prabhakaran S et al. 2026 Guideline for the Early Management of Patients With Acute Ischemic Stroke. Stroke. 2026. Recommendations 1, 12–15 (DAPT vs SAPT when IVT not given).",
                    url: "https://www.ahajournals.org/doi/10.1161/STR.0000000000000513"
                )
            }

            referenceGroup(title: "Secondary prevention / monitoring") {
                referenceItem(
                    title: "CLOTS-3 (intermittent pneumatic compression)",
                    citation: "CLOTS Trials Collaboration. Lancet. 2013;382(9891):516-524.",
                    url: nil
                )
                referenceItem(
                    title: "HeadPoST (head positioning)",
                    citation: "Anderson CS et al. NEJM. 2017;376(25):2437-2447.",
                    url: nil
                )
                referenceItem(
                    title: "CRYSTAL-AF (implantable loop recorder)",
                    citation: "Sanna T et al. NEJM. 2014;370(26):2478-2486.",
                    url: nil
                )
                referenceItem(
                    title: "STROKE-AF",
                    citation: "Bernstein RA et al. JAMA. 2021;325(21):2169-2177.",
                    url: nil
                )
                referenceItem(
                    title: "PER-DIEM",
                    citation: "Buck BH et al. JAMA. 2021;325(21):2160-2168.",
                    url: nil
                )
                referenceItem(
                    title: "PFO closure — RESPECT",
                    citation: "Saver JL et al. NEJM. 2017;377(11):1022-1032.",
                    url: nil
                )
                referenceItem(
                    title: "PFO closure — CLOSE",
                    citation: "Mas JL et al. NEJM. 2017;377(11):1011-1021.",
                    url: nil
                )
                referenceItem(
                    title: "PFO closure — REDUCE",
                    citation: "Søndergaard L et al. NEJM. 2017;377(11):1033-1042.",
                    url: nil
                )
            }

            referenceGroup(title: "Guidelines") {
                referenceItem(
                    title: "AHA/ASA 2019 acute ischemic stroke",
                    citation: "Powers WJ et al. Stroke. 2019;50(12):e344-e418.",
                    url: nil
                )
                referenceItem(
                    title: "AHA/ASA 2026 update (emphasis cited in app)",
                    citation: "AHA/ASA. Guideline for the Early Management of Patients with Acute Ischemic Stroke (2026 update).",
                    url: nil
                )
            }

            Text("All references are summarized for training and education. Verify against current guidelines and your institution's protocol before any clinical use.")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
                .padding(.top, 4)
        }
    }

    /// Collapsible group of related references; collapsed by default for
    /// compactness in the long decision-support scroll.
    private func referenceGroup<Content: View>(title: String,
                                               @ViewBuilder content: @escaping () -> Content) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }

    /// Single reference row with a short title and full citation. Linked when
    /// a URL is provided.
    private func referenceItem(title: String, citation: String, url: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if let urlString = url, let linkURL = URL(string: urlString) {
                Link(citation, destination: linkURL)
                    .font(.caption2)
            } else {
                Text(citation)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Final decisions card

    private var finalDecisionsCard: some View {
        card(title: "Captured decisions", systemImage: "checkmark.seal") {
            HStack {
                Label("Thrombolytic", systemImage: "syringe")
                Spacer()
                Text(state.thrombolyticChosen.label)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("EVT", systemImage: "scissors")
                Spacer()
                Text(state.evtChosen.label)
                    .foregroundStyle(.secondary)
            }
            Text("These choices are training-only labels. Capture exact times on the Timeline tab (Needle, Puncture, Reperfusion).")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    // MARK: - Reusable pieces

    private func card<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func hint(_ text: String, color: Color = .secondary) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func criterionRow(criterion: DecisionCriterion,
                              answer: DecisionAnswer,
                              onChange: @escaping (DecisionAnswer) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(criterion.label)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("", selection: Binding(get: { answer }, set: { onChange($0) })) {
                    Text("?").tag(DecisionAnswer.unknown)
                    Text("Yes").tag(DecisionAnswer.yes)
                    Text("No").tag(DecisionAnswer.no)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            Text(criterion.helpText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            answerBadge(criterion: criterion, answer: answer)
        }
        .padding(.vertical, 4)
    }

    private func answerBadge(criterion: DecisionCriterion, answer: DecisionAnswer) -> some View {
        let isFavorable: Bool? = {
            switch (criterion.polarity, answer) {
            case (_, .unknown): return nil
            case (.mustBeYes, .yes), (.mustBeNo, .no): return true
            case (.mustBeYes, .no), (.mustBeNo, .yes): return false
            }
        }()
        let text: String = {
            switch isFavorable {
            case .some(true): return criterion.polarity == .mustBeYes ? "Required: met" : "Exclusion: not present"
            case .some(false): return criterion.polarity == .mustBeYes ? "Required: not met" : "Exclusion: PRESENT"
            case .none: return "Unknown"
            }
        }()
        let color: Color = {
            switch isFavorable {
            case .some(true): return .green
            case .some(false): return .orange
            case .none: return .secondary
            }
        }()
        return Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func verdictBadge(_ verdict: CandidacyVerdict) -> some View {
        let (text, color): (String, Color) = {
            switch verdict {
            case .incomplete: return (verdict.headline, .secondary)
            case .eligible: return (verdict.headline, .green)
            case .ineligibleRequired: return (verdict.headline, .orange)
            case .ineligibleExclusion: return (verdict.headline, .red)
            }
        }()
        return HStack(spacing: 8) {
            Image(systemName: iconForVerdict(verdict))
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(8)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func iconForVerdict(_ v: CandidacyVerdict) -> String {
        switch v {
        case .incomplete: return "questionmark.circle"
        case .eligible: return "checkmark.seal.fill"
        case .ineligibleRequired: return "exclamationmark.triangle"
        case .ineligibleExclusion: return "xmark.octagon.fill"
        }
    }

    @ViewBuilder
    private func failedList(_ verdict: CandidacyVerdict) -> some View {
        let labels = verdict.failedLabels
        if !labels.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(verdict.headline.contains("exclusion") ? "Exclusions present:" : "Required criteria not met:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                ForEach(labels, id: \.self) { l in
                    Text("• \(l)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Bindings

    private var imagingBinding: Binding<ImagingResult> {
        Binding(
            get: { state.imagingResult },
            set: { newValue in
                store.mutateDecisions { $0.imagingResult = newValue }
                // Reading non-contrast head CT IS the "CT interpreted" event.
                if newValue != .pending {
                    store.captureIfAbsent(milestoneId: "ctRead",
                                          note: "Auto: imaging set to \(newValue.label)")
                }
            }
        )
    }

    private var lvoBinding: Binding<LvoStatus> {
        Binding(
            get: { state.lvoStatus },
            set: { newValue in
                store.mutateDecisions { $0.lvoStatus = newValue }
                // Setting LVO status presumes vessel imaging was reviewed.
                if newValue != .unknown {
                    store.captureIfAbsent(milestoneId: "cta",
                                          note: "Auto: LVO status set to \(newValue.label)")
                }
                if newValue == .present {
                    store.applyExtendedWindowEVTHintsIfApplicable()
                }
            }
        )
    }

    private var thrombolyticBinding: Binding<ThrombolyticChoice> {
        Binding(
            get: { state.thrombolyticChosen },
            set: { newValue in
                store.mutateDecisions { $0.thrombolyticChosen = newValue }
                // Any committed choice (give / decline / defer) IS the
                // thrombolytic-decision milestone.
                if newValue != .undecided {
                    store.captureIfAbsent(milestoneId: "thrombolyticDecision",
                                          note: "Auto: thrombolytic decision — \(newValue.label)")
                }
            }
        )
    }

    private var lvoSiteBinding: Binding<LvoSite> {
        Binding(
            get: { state.lvoSite ?? .unknown },
            set: { newValue in store.mutateDecisions { $0.lvoSite = newValue } }
        )
    }

    private var baselineMrsBinding: Binding<BaselineMRS> {
        Binding(
            get: { state.baselineMRS ?? .unknown },
            set: { newValue in store.mutateDecisions { $0.baselineMRS = newValue } }
        )
    }

    private var evtBinding: Binding<EvtChoice> {
        Binding(
            get: { state.evtChosen },
            set: { newValue in
                store.mutateDecisions { $0.evtChosen = newValue }
                // Any committed EVT plan (planned / declined / deferred)
                // IS the EVT-decision milestone.
                if newValue != .undecided {
                    store.captureIfAbsent(milestoneId: "evtDecision",
                                          note: "Auto: EVT decision — \(newValue.label)")
                }
            }
        )
    }
}

#Preview {
    let store = StrokeCodeStore()
    store.startNew()
    return ScrollView {
        StrokeCodeDecisionView()
            .environmentObject(store)
            .environmentObject(LanguageStore())
            .environmentObject(SpanishSpeechService())
            .environmentObject(PatientResponseService())
            .padding()
    }
}
