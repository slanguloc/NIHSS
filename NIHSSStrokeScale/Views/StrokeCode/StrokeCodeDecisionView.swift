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
            patientDetailsCard
            anchorsCard
            imagingCard
            if state.imagingResult != .hemorrhagic {
                aspectsCard
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
            lvoCard
            if state.lvoStatus == .present {
                evtCard
            }
            if state.imagingResult != .hemorrhagic {
                extendedWindowCard
            }
            if shouldShowMedicalManagement {
                medicalManagementCard
            }
            finalDecisionsCard
            educationalFooter
                .padding(.top, 8)
        }
    }

    /// Shows medical-management guidance when an ischemic stroke is not
    /// proceeding with IV thrombolysis or EVT.
    private var shouldShowMedicalManagement: Bool {
        guard state.imagingResult == .ischemic else { return false }
        let ivtDeclined = state.thrombolyticChosen == .declined ||
                          state.thrombolyticChosen == .deferred
        let evtDeclined = state.evtChosen == .declined ||
                          state.evtChosen == .deferred ||
                          state.lvoStatus == .absent
        return ivtDeclined && evtDeclined
    }

    // MARK: - Banner / footer

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
            VStack(alignment: .leading, spacing: 6) {
                Text("Anchors")
                    .font(.headline)
                HStack(spacing: 12) {
                    anchorTile(title: "LKW", time: lkw, now: now,
                               subtitle: lkw == nil ? "Set on Timeline tab" : windowHint(lkw: lkw, now: now),
                               color: .blue)
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

    private func anchorTile(title: String, time: Date?, now: Date, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(time.map { StrokeCodeStore.format(elapsed: now.timeIntervalSince($0)) } ?? "—")
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(time == nil ? Color.secondary : color)
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
        let verdict = state.ivtVerdict()
        return card(title: "IV thrombolysis eligibility", systemImage: "syringe") {
            verdictBadge(verdict)

            ForEach(groupedIvt(), id: \.0) { group, items in
                Text(group)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                ForEach(items) { c in
                    criterionRow(
                        criterion: c,
                        answer: state.ivtCriteria[c.id] ?? .unknown,
                        onChange: { newValue in
                            store.mutateDecisions { $0.ivtCriteria[c.id] = newValue }
                        }
                    )
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
                hint("LVO present — proceed to EVT eligibility checklist below.", color: .blue)
            case .absent:
                hint("No LVO — EVT not indicated. Continue medical management per protocol.")
            }
        }
    }

    // MARK: - EVT card

    private var evtCard: some View {
        let verdict = state.evtVerdict()
        return card(title: "EVT eligibility", systemImage: "scissors") {
            verdictBadge(verdict)

            ForEach(StrokeCodeDecisionCatalog.evt) { c in
                criterionRow(
                    criterion: c,
                    answer: state.evtCriteria[c.id] ?? .unknown,
                    onChange: { newValue in
                        store.mutateDecisions { $0.evtCriteria[c.id] = newValue }
                    }
                )
            }

            failedList(verdict)

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

    // MARK: - Patient details card

    private var patientDetailsCard: some View {
        let aspectsCategory = AspectsCategory(score: state.aspectsScore ?? 10)

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
            Text("ASPECTS quantifies early ischemic changes on non-contrast CT (10 = normal). Full EVT/IVT training notes in the ASPECTS card below.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func severityColor(nihss: Int) -> Color {
        switch nihss {
        case ..<5: return .green
        case 5..<15: return .blue
        case 15..<21: return .orange
        default: return .red
        }
    }

    // MARK: - Medical management (no IVT / no EVT)

    private var medicalManagementCard: some View {
        card(title: "Medical management (no IVT / EVT)", systemImage: "cross.case") {
            Text("Training guidance when an ischemic stroke patient is not proceeding to IV thrombolysis or EVT.")
                .font(.caption)
                .foregroundStyle(.secondary)

            mgmtSection(
                title: "Antiplatelet therapy",
                bullets: [
                    "Aspirin 162–325 mg within 24–48 h once hemorrhage is excluded.",
                    "Minor non-cardioembolic stroke (NIHSS ≤ 3 or high-risk TIA with ABCD² ≥ 4): DAPT — aspirin + clopidogrel for 21 days, then single agent.",
                    "If IV thrombolysis was given: hold antiplatelets/anticoagulants for 24 h, then start once repeat imaging is clear."
                ]
            )

            mgmtSection(
                title: "Blood pressure",
                bullets: [
                    "If no IV thrombolysis: permissive HTN for first 24–48 h. Treat only if BP > 220/120 mmHg or evidence of end-organ injury (lower ~15% in first 24 h).",
                    "After 48–72 h or if treated: target < 130/80 mmHg long-term (individualize).",
                    "If thrombolytic given: keep BP ≤ 180/105 mmHg for 24 h."
                ]
            )

            mgmtSection(
                title: "Statin",
                bullets: [
                    "Start high-intensity statin (atorvastatin 40–80 mg or rosuvastatin 20–40 mg) unless contraindicated."
                ]
            )

            mgmtSection(
                title: "Glycemic management",
                bullets: [
                    "Target glucose 140–180 mg/dL during hospitalization.",
                    "Treat hypoglycemia (< 60 mg/dL) promptly."
                ]
            )

            mgmtSection(
                title: "DVT prophylaxis",
                bullets: [
                    "Intermittent pneumatic compression on admission for non-ambulatory patients.",
                    "Add prophylactic-dose subcutaneous heparin/LMWH after 24 h if stable (and ≥ 24 h after thrombolysis)."
                ]
            )

            mgmtSection(
                title: "Bedside care",
                bullets: [
                    "Dysphagia screen before any oral intake (food, fluids, or medications).",
                    "Telemetry / continuous cardiac monitoring for ≥ 24 h.",
                    "Early mobilization and PT/OT/speech consults once stable."
                ]
            )

            mgmtSection(
                title: "Etiologic workup",
                bullets: [
                    "Vessel imaging (carotid US/CTA/MRA) if not yet done.",
                    "Echocardiogram (TTE; consider TEE for cardioembolic source).",
                    "≥ 24 h cardiac monitoring; prolonged outpatient monitoring if cryptogenic.",
                    "Fasting lipid panel and HbA1c."
                ]
            )

            mgmtSection(
                title: "Secondary prevention",
                bullets: [
                    "Anticoagulation if atrial fibrillation or other indication (timing per protocol; avoid for 24 h after thrombolysis).",
                    "Smoking cessation, glycemic and lipid control, lifestyle counseling.",
                    "Stroke / rehab planning before discharge."
                ]
            )

            Text("Education only. Follow your institution's protocol and the current AHA/ASA stroke guidelines.")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
                .padding(.top, 4)
        }
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
                Text("EVT training note")
                    .font(.subheadline.bold())
                Text(category.evtTrainingNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("IVT training note")
                    .font(.subheadline.bold())
                Text(category.ivtTrainingNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Educational summary of HERMES (ASPECTS ≥ 6, 0–6 h) and the 2023 large-core EVT trials (SELECT2 / RESCUE-Japan LIMIT / ANGEL-ASPECT). Not a clinical decision tool.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
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
            }
        )
    }

    // MARK: - 3–4.5 h IV thrombolysis card

    /// Show the 3–4.5 h extended-early-window IVT card when the patient is
    /// (or has been) within that window since LKW.
    private var shouldShowExtendedEarlyIvt: Bool {
        guard let lkw = store.active?.lastKnownWell else { return false }
        let mins = Date().timeIntervalSince(lkw) / 60.0
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
        let lkw = store.active?.lastKnownWell
        let minutesSinceLKW = lkw.map { Date().timeIntervalSince($0) / 60.0 }
        let ew = state.extendedWindow ?? .empty
        let verdict = ew.verdict(minutesSinceLKW: minutesSinceLKW)

        return card(title: "Extended window (late presentation / wake-up)",
                    systemImage: "clock.badge.exclamationmark") {

            if let mins = minutesSinceLKW {
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
                Text("Capture Last known well on the Timeline tab to evaluate extended-window eligibility.")
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

            Text("Educational summary of WAKE-UP, EXTEND, EPITHET (IVT extended), DAWN, DEFUSE-3 (EVT 6–24 h), and SELECT2 / RESCUE-Japan LIMIT / ANGEL-ASPECT (large-core EVT). Not a clinical decision tool.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
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

            Text("Document consent per your institution's protocol. This script does NOT replace your hospital's consent form.")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
                .padding(.top, 4)
        }
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
            set: { newValue in store.mutateDecisions { $0.imagingResult = newValue } }
        )
    }

    private var lvoBinding: Binding<LvoStatus> {
        Binding(
            get: { state.lvoStatus },
            set: { newValue in store.mutateDecisions { $0.lvoStatus = newValue } }
        )
    }

    private var thrombolyticBinding: Binding<ThrombolyticChoice> {
        Binding(
            get: { state.thrombolyticChosen },
            set: { newValue in store.mutateDecisions { $0.thrombolyticChosen = newValue } }
        )
    }

    private var evtBinding: Binding<EvtChoice> {
        Binding(
            get: { state.evtChosen },
            set: { newValue in store.mutateDecisions { $0.evtChosen = newValue } }
        )
    }
}

#Preview {
    let store = StrokeCodeStore()
    store.startNew()
    return ScrollView {
        StrokeCodeDecisionView()
            .environmentObject(store)
            .padding()
    }
}
