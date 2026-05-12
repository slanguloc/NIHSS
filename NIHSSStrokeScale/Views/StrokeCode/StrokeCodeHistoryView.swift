//
//  StrokeCodeHistoryView.swift
//  Zysquy — Review of past stroke-code training sessions.
//
//  Lists previously saved stroke-code sessions and shows a per-session
//  read-only summary with captured milestones, elapsed times, and how each
//  compared against AHA/ASA Target: Stroke time goals. Education only.
//

import SwiftUI

// MARK: - History list

struct StrokeCodeHistoryView: View {
    @EnvironmentObject var store: StrokeCodeStore
    @Environment(\.dismiss) private var dismiss

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    var body: some View {
        Group {
            if store.sessions.isEmpty {
                emptyState
            } else {
                List {
                    Section {
                        Text("Education and training only — review of simulated sessions on this device.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Section("Sessions") {
                        ForEach(store.sessions) { session in
                            NavigationLink {
                                StrokeCodeSessionSummaryView(session: session, allowEdit: true)
                                    .environmentObject(store)
                            } label: {
                                sessionRow(session)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Stroke code history")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onChange(of: store.isEditingExisting) { editing in
            if editing { dismiss() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "stopwatch")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No stroke code sessions yet")
                .font(.headline)
            Text("Completed training sessions will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private func sessionRow(_ session: StrokeCodeSession) -> some View {
        let completedAt = session.completedAt ?? session.startedAt
        let needleElapsed = needleDoorToNeedle(in: session)
        let scenario = session.scenarioId.flatMap(StrokeCodeScenarioBank.scenario(id:))
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateFormatter.string(from: completedAt))
                    .font(.body)
                Text("\(session.events.count) milestone(s) captured")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let scenario {
                    Label(scenario.title, systemImage: "books.vertical")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let needleElapsed {
                VStack(alignment: .trailing) {
                    Text("D2N")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(StrokeCodeStore.format(elapsed: needleElapsed))
                        .font(.body.monospacedDigit().bold())
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func needleDoorToNeedle(in session: StrokeCodeSession) -> TimeInterval? {
        guard let needle = session.timestamp(for: "needle"),
              let door = session.doorTime else { return nil }
        return needle.timeIntervalSince(door)
    }
}

// MARK: - Per-session summary

struct StrokeCodeSessionSummaryView: View {
    let session: StrokeCodeSession
    /// When true, show an "Reopen for edit" button that pulls the saved
    /// session back into the active store for further edits.
    var allowEdit: Bool = false

    @EnvironmentObject var store: StrokeCodeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showReopenConfirm = false

    private let milestones = StrokeCodeMilestone.defaultMilestones

    private var scenario: StrokeCodeScenario? {
        guard let id = session.scenarioId else { return nil }
        return StrokeCodeScenarioBank.scenario(id: id)
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    private var timeOnlyFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }

    var body: some View {
        List {
            Section {
                Text("Education and training only. Do not use for clinical care or documentation.")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            Section("Session") {
                LabeledContent("Started", value: dateFormatter.string(from: session.startedAt))
                if let c = session.completedAt {
                    LabeledContent("Completed", value: dateFormatter.string(from: c))
                }
                if let door = session.doorTime {
                    LabeledContent("Door (t=0)", value: timeOnlyFormatter.string(from: door))
                }
                if let lkw = session.lastKnownWell {
                    LabeledContent("Last Known Well", value: timeOnlyFormatter.string(from: lkw))
                }
            }

            Section("Key intervals") {
                keyIntervalRow(label: "Door → Needle (IV thrombolytic)", milestoneId: "needle")
                keyIntervalRow(label: "Door → CT started", milestoneId: "ctStart")
                keyIntervalRow(label: "Door → CT interpreted", milestoneId: "ctRead")
                keyIntervalRow(label: "Door → Puncture (EVT)", milestoneId: "puncture")
                keyIntervalRow(label: "Door → Reperfusion", milestoneId: "recanalization")
            }

            Section("All milestones") {
                ForEach(milestones) { m in
                    milestoneRow(m)
                }
            }

            if let d = session.decisions {
                decisionsSection(d)
            }

            if let scenario = scenario {
                scenarioDebriefSection(scenario, decisions: session.decisions)
            }

            if !session.notes.isEmpty {
                Section("Notes") {
                    Text(session.notes)
                        .font(.body)
                }
            }

            Section {
                Text("Time targets reflect AHA/ASA Target: Stroke goals (door-to-CT ≤25 min, door-to-needle ≤60 min with ≤45 min stretch, door-to-puncture ≤90 min, door-to-reperfusion ≤120 min). For education only.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Session summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if allowEdit {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if store.active == nil {
                            store.reopen(session)
                            dismiss()
                        } else {
                            showReopenConfirm = true
                        }
                    } label: {
                        Label("Reopen for edit", systemImage: "pencil")
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .confirmationDialog(
            "Discard current active session and reopen this one?",
            isPresented: $showReopenConfirm,
            titleVisibility: .visible
        ) {
            Button("Discard active & reopen", role: .destructive) {
                store.cancelActive()
                store.reopen(session)
                dismiss()
            }
            Button("Keep current", role: .cancel) { }
        } message: {
            Text("Only one stroke code session can be active at a time. The current active session will be discarded.")
        }
    }

    private func keyIntervalRow(label: String, milestoneId: String) -> some View {
        guard let milestone = milestones.first(where: { $0.id == milestoneId }) else {
            return AnyView(EmptyView())
        }
        let elapsed = session.elapsedSeconds(for: milestone)
        let status = session.status(for: milestone)
        return AnyView(
            HStack {
                Text(label)
                Spacer()
                if let elapsed {
                    Text(StrokeCodeStore.format(elapsed: elapsed))
                        .font(.body.monospacedDigit().bold())
                        .foregroundStyle(color(for: status))
                } else {
                    Text("—")
                        .foregroundStyle(.secondary)
                }
            }
        )
    }

    private func milestoneRow(_ milestone: StrokeCodeMilestone) -> some View {
        let captured = session.timestamp(for: milestone.id)
        let elapsed = session.elapsedSeconds(for: milestone)
        let status = session.status(for: milestone)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                if milestone.isAnchor {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                Text(milestone.label)
                    .font(.body.weight(.semibold))
                Spacer()
                if let captured {
                    Text(timeOnlyFormatter.string(from: captured))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("—")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                targetText(for: milestone)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let elapsed, !milestone.isAnchor {
                    Text(StrokeCodeStore.format(elapsed: elapsed))
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(color(for: status))
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func targetText(for m: StrokeCodeMilestone) -> Text {
        if m.isAnchor { return Text("Anchor") }
        guard let t = m.target else { return Text(" ") }
        let ref: String = {
            switch m.measuredFrom {
            case .door: return "Door"
            case .lastKnownWell: return "LKW"
            case .anchor: return ""
            }
        }()
        if let stretch = t.stretchMinutes {
            return Text("Target \(ref) + ≤\(t.targetMinutes) min (stretch ≤\(stretch))")
        }
        return Text("Target \(ref) + ≤\(t.targetMinutes) min")
    }

    private func color(for status: StrokeCodeTargetStatus) -> Color {
        switch status {
        case .onTrackStretch: return .green
        case .onTrackTarget: return .blue
        case .missed: return .orange
        case .notCaptured: return .secondary
        }
    }

    // MARK: - Decisions summary

    @ViewBuilder
    private func decisionsSection(_ d: DecisionState) -> some View {
        Section("Decisions (training)") {
            LabeledContent("Imaging", value: d.imagingResult.label)
            LabeledContent("LVO", value: d.lvoStatus.label)
            LabeledContent("Thrombolytic", value: d.thrombolyticChosen.label)
            LabeledContent("EVT", value: d.evtChosen.label)

            if let w = d.weightKg {
                LabeledContent("Weight", value: "\(w) kg")
            }
            if let n = d.nihssTotal {
                LabeledContent("NIHSS total", value: "\(n)")
            }
            if let a = d.aspectsScore {
                LabeledContent("ASPECTS", value: "\(a) / 10 — \(AspectsCategory(score: a).label)")
            }
            if let ew = d.extendedWindow, ew.advancedImagingDone {
                let lkw = session.lastKnownWell
                let mins = lkw.map { session.completedAt?.timeIntervalSince($0) ?? Date().timeIntervalSince($0) }
                                .map { $0 / 60.0 }
                LabeledContent("Extended window", value: ew.verdict(minutesSinceLKW: mins).label)
            }
            if let ee = d.extendedEarlyIvt {
                let lkw = session.lastKnownWell
                let mins = lkw.map { session.completedAt?.timeIntervalSince($0) ?? Date().timeIntervalSince($0) }
                                .map { $0 / 60.0 }
                let v = ee.verdict(minutesSinceLKW: mins)
                if case .notInWindow = v {
                    // omit when not relevant
                } else {
                    LabeledContent("3–4.5 h IVT", value: v.label)
                }
            }
            if let w = d.weightKg,
               let dose = computeThrombolyticDose(drug: d.thrombolyticChosen, weightKg: w) {
                doseSummaryRow(dose)
            }

            verdictRow(label: "IVT verdict", verdict: d.ivtVerdict())
            if d.lvoStatus == .present {
                verdictRow(label: "EVT verdict", verdict: d.evtVerdict())
            }
        }
    }

    private func doseSummaryRow(_ dose: ThrombolyticDose) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Dose (training)")
                Spacer()
                Text(String(format: "%.1f mg", dose.totalMg))
                    .font(.body.monospacedDigit().bold())
                    .foregroundStyle(.red)
                if dose.cappedAtMax {
                    Text("(max)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            Text(dose.standardDoseLabel + " · " + dose.administrationSummary)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func verdictRow(label: String, verdict: CandidacyVerdict) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(verdict.headline)
                .font(.caption)
                .foregroundStyle(verdictColor(verdict))
                .multilineTextAlignment(.trailing)
        }
    }

    private func verdictColor(_ v: CandidacyVerdict) -> Color {
        switch v {
        case .incomplete: return .secondary
        case .eligible: return .green
        case .ineligibleRequired: return .orange
        case .ineligibleExclusion: return .red
        }
    }

    // MARK: - Scenario debrief

    @ViewBuilder
    private func scenarioDebriefSection(_ s: StrokeCodeScenario, decisions: DecisionState?) -> some View {
        Section("Scenario debrief (training)") {
            VStack(alignment: .leading, spacing: 4) {
                Text(s.title)
                    .font(.body.bold())
                Text(s.oneLiner)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            comparisonRow(
                label: "Thrombolytic",
                expected: s.expected.thrombolytic.label,
                captured: decisions?.thrombolyticChosen.label ?? ThrombolyticChoice.undecided.label,
                match: (decisions?.thrombolyticChosen ?? .undecided) == s.expected.thrombolytic
            )
            comparisonRow(
                label: "EVT",
                expected: s.expected.evt.label,
                captured: decisions?.evtChosen.label ?? EvtChoice.undecided.label,
                match: (decisions?.evtChosen ?? .undecided) == s.expected.evt
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Educator rationale")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(s.expected.rationale)
                    .font(.caption)
            }

            if !s.teachingPoints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Teaching points")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(s.teachingPoints, id: \.self) { p in
                        Text("• \(p)")
                            .font(.caption)
                    }
                }
            }
        }
    }

    private func comparisonRow(label: String, expected: String, captured: String, match: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.bold())
                Text("Expected: \(expected)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Captured: \(captured)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: match ? "checkmark.circle.fill" : "circle.slash")
                .foregroundStyle(match ? .green : .orange)
        }
    }
}

#Preview {
    NavigationStack {
        StrokeCodeHistoryView()
            .environmentObject(StrokeCodeStore())
    }
}
