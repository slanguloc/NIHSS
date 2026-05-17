//
//  StrokeCodeTimerView.swift
//  Zysquy — Stroke Code Timer UI (education/training only).
//
//  Live timer that captures milestones aligned with AHA/ASA Target: Stroke
//  goals. Each milestone shows: target window, captured timestamp, and
//  elapsed time from its reference (Door or Last Known Well). Intended for
//  training and simulation drills, not for clinical care.
//

import SwiftUI

struct StrokeCodeTimerView: View {
    @EnvironmentObject var store: StrokeCodeStore
    @AppStorage("preferredWeightUnit") private var preferredWeightUnitRaw: String = WeightUnit.kilograms.rawValue

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: preferredWeightUnitRaw) ?? .kilograms
    }

    @State private var showHistory = false
    @State private var showScenarioPicker = false
    @State private var showFinishConfirm = false
    @State private var showAbortConfirm = false
    @State private var manualMilestone: StrokeCodeMilestone?
    @State private var manualDate: Date = Date()
    @State private var draftNotes: String = ""
    @State private var completedSession: StrokeCodeSession?
    @State private var activeTab: ActiveTab = .timeline
    @State private var revealedFindings: Set<String> = []
    @State private var showNIHSSLauncher = false

    /// Scenario loaded into the active session, if any.
    private var loadedScenario: StrokeCodeScenario? {
        guard let id = store.active?.scenarioId else { return nil }
        return StrokeCodeScenarioBank.scenario(id: id)
    }

    private let milestones = StrokeCodeMilestone.defaultMilestones

    enum ActiveTab: String, CaseIterable, Identifiable {
        case timeline
        case decisions
        var id: String { rawValue }
        var label: String {
            switch self {
            case .timeline: return "Timeline"
            case .decisions: return "Decisions"
            }
        }
    }

    var body: some View {
        Group {
            if let _ = store.active {
                activeSession
            } else {
                landing
            }
        }
        .navigationTitle("Stroke Code Timer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                PatientLanguagePicker(style: .toolbarIcon)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showHistory = true
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                StrokeCodeHistoryView()
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showScenarioPicker) {
            NavigationStack {
                StrokeCodeScenarioPickerView(onLoaded: {
                    revealedFindings.removeAll()
                    draftNotes = ""
                    activeTab = .timeline
                })
                .environmentObject(store)
            }
        }
        .sheet(item: $manualMilestone) { milestone in
            manualTimeSheet(for: milestone)
        }
        .sheet(item: $completedSession) { session in
            NavigationStack {
                StrokeCodeSessionSummaryView(session: session)
            }
        }
        .fullScreenCover(isPresented: $showNIHSSLauncher) {
            NIHSSFromStrokeCodeView { total in
                store.capture(milestoneId: "nihssDone")
                store.mutateDecisions { $0.nihssTotal = total }
            }
        }
    }

    // MARK: - Landing (no active session)

    private var landing: some View {
        ScrollView {
            VStack(spacing: 16) {
                disclaimerBanner

                VStack(spacing: 8) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 56))
                        .foregroundStyle(.red.gradient)
                    Text("Stroke Code Timer")
                        .font(.title2.bold())
                    Text("Practice running a stroke code with timestamped milestones aligned to AHA/ASA Target: Stroke time goals.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 8)

                Button {
                    store.startNew()
                    draftNotes = ""
                    activeTab = .timeline
                    revealedFindings.removeAll()
                } label: {
                    Label("Start stroke code (training)", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button {
                    showScenarioPicker = true
                } label: {
                    Label("Load scenario (educator)", systemImage: "books.vertical")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                Button {
                    showHistory = true
                } label: {
                    Label("Review past sessions", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                educationalFooter
                    .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Active session

    private var activeSession: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $activeTab) {
                ForEach(ActiveTab.allCases) { tab in
                    Text(tab.label).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(Color(.systemBackground))

            ScrollView {
                VStack(spacing: 12) {
                    if store.isEditingExisting {
                        editingIndicator
                    }
                    switch activeTab {
                    case .timeline:
                        disclaimerBanner
                        patientStripCard
                        if let scenario = loadedScenario {
                            caseBriefingCard(scenario)
                        }
                        liveClockCard
                        milestonesList
                        notesCard
                        educationalFooter
                            .padding(.top, 12)
                    case .decisions:
                        StrokeCodeDecisionView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        // Clamp the weight on commit (numeric pad has no Return).
                        if let w = store.active?.decisions?.weightKg {
                            let clamped = max(30, min(250, w))
                            if clamped != w {
                                store.mutateDecisions { $0.weightKg = clamped }
                            }
                        }
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                    .font(.body.bold())
                }
            }

            Divider()
            HStack(spacing: 12) {
                Button(role: .destructive) {
                    showAbortConfirm = true
                } label: {
                    Label("Abort", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                Button {
                    store.updateNotes(draftNotes)
                    showFinishConfirm = true
                } label: {
                    Label(store.isEditingExisting ? "Save edits" : "Finish & save",
                          systemImage: "checkmark.seal")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .confirmationDialog(
            store.isEditingExisting ? "Save these edits?" : "Finish this stroke code session?",
            isPresented: $showFinishConfirm,
            titleVisibility: .visible
        ) {
            Button(store.isEditingExisting ? "Save edits" : "Finish & save") {
                if let s = store.active {
                    var snapshot = s
                    snapshot.notes = draftNotes
                    store.updateNotes(draftNotes)
                    snapshot.completedAt = Date()
                    completedSession = snapshot
                    store.completeAndSaveActive()
                }
            }
            Button("Keep running", role: .cancel) { }
        } message: {
            Text(store.isEditingExisting
                 ? "Replaces the saved session with your edits (encrypted, on-device)."
                 : "Saves the timeline locally on this device (encrypted). For training review only.")
        }
        .confirmationDialog(
            store.isEditingExisting ? "Discard edits and keep the saved version?" : "Abort and discard this session?",
            isPresented: $showAbortConfirm,
            titleVisibility: .visible
        ) {
            Button(store.isEditingExisting ? "Discard edits" : "Discard", role: .destructive) {
                store.cancelActive()
                draftNotes = ""
            }
            Button("Keep running", role: .cancel) { }
        } message: {
            Text(store.isEditingExisting
                 ? "Your in-flight changes will be discarded; the previously saved session is restored."
                 : "All captured timestamps in this session will be lost.")
        }
        .onAppear {
            if draftNotes.isEmpty, let n = store.active?.notes {
                draftNotes = n
            }
        }
    }

    // MARK: - Live clock card

    private var liveClockCard: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let now = context.date
            let session = store.active
            let door = session?.doorTime
            let lkw = session?.lastKnownWell

            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "stopwatch")
                    Text("Live timer")
                        .font(.headline)
                    Spacer()
                    Text(timeOfDay(now))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    clockTile(
                        title: "From Door",
                        value: door.map { StrokeCodeStore.format(elapsed: now.timeIntervalSince($0)) } ?? "—",
                        subtitle: door == nil ? "Tap Door to start t=0" : "t = 0 anchor",
                        color: door == nil ? .secondary : .red
                    )
                    clockTile(
                        title: "From LKW",
                        value: lkw.map { StrokeCodeStore.format(elapsed: now.timeIntervalSince($0)) } ?? "—",
                        subtitle: lkw == nil ? "Tap LKW to set anchor" : treatmentWindowHint(elapsed: now.timeIntervalSince(lkw ?? now)),
                        color: lkw == nil ? .secondary : .blue
                    )
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func clockTile(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
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

    private func treatmentWindowHint(elapsed: TimeInterval) -> String {
        let minutes = elapsed / 60.0
        if minutes < 0 { return "LKW in the future" }
        if minutes <= 270 { return "Within 4.5h IV window" }
        if minutes <= 540 { return "Within 9h extended IV (select)" }
        if minutes <= 1440 { return "Within 24h EVT window (select)" }
        return "Beyond standard windows"
    }

    // MARK: - Milestones list

    private var milestonesList: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Milestones")
                    .font(.headline)
                Spacer()
            }
            ForEach(milestones) { milestone in
                milestoneRow(milestone)
            }
        }
    }

    private func milestoneRow(_ milestone: StrokeCodeMilestone) -> some View {
        let session = store.active
        let captured = session?.timestamp(for: milestone.id)
        let status = session?.status(for: milestone) ?? .notCaptured
        let referenceTime = session?.referenceTime(for: milestone)
        let elapsedText: String? = {
            if let captured, let referenceTime {
                return StrokeCodeStore.format(elapsed: captured.timeIntervalSince(referenceTime))
            }
            return nil
        }()

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if milestone.isAnchor {
                            Image(systemName: "flag.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        Text(milestone.label)
                            .font(.body.weight(.semibold))
                    }
                    targetSubtitle(for: milestone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(status, milestone: milestone)
            }

            Text(milestone.helpText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                if let captured {
                    Label(timeOfDay(captured), systemImage: "clock")
                        .font(.subheadline.monospacedDigit())
                    if let elapsedText, !milestone.isAnchor {
                        Text(elapsedText)
                            .font(.subheadline.monospacedDigit().bold())
                            .foregroundStyle(color(for: status))
                    }
                    Spacer()
                    Button {
                        manualDate = captured
                        manualMilestone = milestone
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Button(role: .destructive) {
                        store.clear(milestoneId: milestone.id)
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button {
                        store.capture(milestoneId: milestone.id)
                    } label: {
                        Label("Now", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(milestone.isAnchor ? .blue : .red)
                    .controlSize(.small)

                    Button {
                        manualDate = Date()
                        manualMilestone = milestone
                    } label: {
                        Label("Set time…", systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Spacer()
                }
            }

            if milestone.id == "nihssDone" {
                nihssLauncherRow
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Inline launcher row shown under the NIHSS milestone. Opens the NIHSS
    /// assessment flow and, on finish, auto-captures the milestone and
    /// records the total back to the active session.
    private var nihssLauncherRow: some View {
        let total = store.active?.decisions?.nihssTotal
        return HStack(spacing: 8) {
            Image(systemName: "brain")
                .foregroundStyle(.red)
            if let total {
                Text("Captured NIHSS total: \(total)")
                    .font(.caption.monospacedDigit().bold())
                Spacer()
                Button {
                    showNIHSSLauncher = true
                } label: {
                    Label("Re-run", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Text("Run the NIH Stroke Scale assessment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showNIHSSLauncher = true
                } label: {
                    Label("Run NIHSS", systemImage: "play.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func targetSubtitle(for m: StrokeCodeMilestone) -> Text {
        if m.isAnchor {
            switch m.measuredFrom {
            case .anchor:
                return Text(m.id == "doorTime" ? "Anchors t=0 for in-hospital metrics" : "Anchors treatment windows")
            default:
                return Text("Anchor")
            }
        }
        guard let t = m.target else { return Text(" ") }
        let reference: String = {
            switch m.measuredFrom {
            case .door: return "Door"
            case .lastKnownWell: return "LKW"
            case .anchor: return ""
            }
        }()
        if let stretch = t.stretchMinutes {
            return Text("\(reference) + ≤\(t.targetMinutes) min (stretch ≤\(stretch) min)")
        }
        return Text("\(reference) + ≤\(t.targetMinutes) min")
    }

    private func statusBadge(_ status: StrokeCodeTargetStatus, milestone: StrokeCodeMilestone) -> some View {
        let (text, fg, bg): (String, Color, Color) = {
            switch status {
            case .notCaptured:
                return (milestone.isAnchor ? "Anchor" : "Pending", .secondary, Color(.tertiarySystemFill))
            case .onTrackStretch:
                return ("Stretch met", .white, .green)
            case .onTrackTarget:
                return ("Target met", .white, .blue)
            case .missed:
                return ("Target missed", .white, .orange)
            }
        }()
        return Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(fg)
            .background(bg)
            .clipShape(Capsule())
    }

    private func color(for status: StrokeCodeTargetStatus) -> Color {
        switch status {
        case .onTrackStretch: return .green
        case .onTrackTarget: return .blue
        case .missed: return .orange
        case .notCaptured: return .secondary
        }
    }

    // MARK: - Notes card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes (training)")
                .font(.headline)
            TextEditor(text: $draftNotes)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onChange(of: draftNotes) { newValue in
                    store.updateNotes(newValue)
                }
            Text("Use a simulated case. Do not enter real patient identifiers.")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    // MARK: - Manual time sheet

    private func manualTimeSheet(for milestone: StrokeCodeMilestone) -> some View {
        NavigationStack {
            Form {
                Section(milestone.label) {
                    DatePicker("Time", selection: $manualDate, displayedComponents: [.date, .hourAndMinute])
                }
                Section {
                    Text(milestone.helpText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Set time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { manualMilestone = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        store.capture(milestoneId: milestone.id, at: manualDate)
                        manualMilestone = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var editingIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil.circle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Editing a saved session")
                    .font(.subheadline.bold())
                Text("Tap “Save edits” to replace the saved copy, or “Discard edits” to restore the previous version.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.yellow.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Patient strip (Timeline tab)

    /// Compact, always-visible patient details on the Timeline tab so the
    /// trainee can capture weight without switching to the Decisions tab.
    private var patientStripCard: some View {
        let decisions = store.active?.decisions
        let weight = decisions?.weightKg
        let nihss = decisions?.nihssTotal
        let aspects = decisions?.aspectsScore ?? 10

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "person.text.rectangle")
                    .foregroundStyle(.blue)
                Text("Patient details")
                    .font(.subheadline.bold())
                Spacer(minLength: 0)
                if let n = nihss {
                    Label("NIHSS \(n)", systemImage: "brain")
                        .font(.caption.monospacedDigit().bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                }
                Label("ASPECTS \(aspects)", systemImage: "viewfinder.circle")
                    .font(.caption.monospacedDigit().bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                Text("Weight")
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 6) {
                    TextField(weightUnit.label,
                              value: displayedWeightStripBinding,
                              format: .number)
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
                        .onSubmit { clampStripWeight() }

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
                }
                Stepper("Weight",
                        value: displayedWeightStripBinding,
                        in: weightUnit.range,
                        step: 1)
                    .labelsHidden()
                    .fixedSize()
            }

            if weightUnit == .pounds, let kg = weight {
                Text("≈ \(kg) kg (used for dose calculation).")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Tap the value to type directly, use ± for ±1, or tap the unit to switch kg ↔ lb.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Binding in the user's preferred display unit, backed by kg storage.
    private var displayedWeightStripBinding: Binding<Int> {
        Binding<Int>(
            get: {
                let kg = store.active?.decisions?.weightKg ?? 75
                return weightUnit.displayedValue(forKg: kg)
            },
            set: { displayedValue in
                let v = max(0, min(999, displayedValue))
                let kg = weightUnit.kgValue(fromDisplayed: v)
                store.mutateDecisions { $0.weightKg = kg }
            }
        )
    }

    private func clampStripWeight() {
        guard let w = store.active?.decisions?.weightKg else { return }
        let clamped = max(30, min(250, w))
        if clamped != w {
            store.mutateDecisions { $0.weightKg = clamped }
        }
    }

    // MARK: - Disclaimer / education banner

    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Education and training only")
                    .font(.subheadline.bold())
                Text("Not a medical device. Not for clinical decisions or documentation. Follow your institution's stroke protocol for real patient care.")
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
            Text("Time targets reflect AHA/ASA Target: Stroke goals (e.g., door-to-CT ≤25 min, door-to-needle ≤60 min with ≤45 min stretch, door-to-puncture ≤90 min, door-to-reperfusion ≤120 min). See SOURCES.md.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Education only. Not for clinical use.")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Case briefing (scenario mode)

    private func caseBriefingCard(_ s: StrokeCodeScenario) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "books.vertical")
                    .foregroundStyle(.blue)
                Text("Case briefing")
                    .font(.headline)
                Spacer()
                difficultyChip(s.difficulty)
            }

            Text(s.title)
                .font(.subheadline.bold())
            Text(s.vignette)
                .font(.subheadline)

            patientLine(s)
            vitalsLine(s)
            if !s.history.isEmpty {
                Text("History / meds: " + s.history.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let n = s.presentingNihss {
                Text("Presenting NIHSS: \(n)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.vertical, 2)

            revealBlock(
                key: "ct",
                title: "Reveal CT (non-contrast)",
                systemImage: "brain.head.profile",
                body: s.findings.ctNonContrast
            )
            revealBlock(
                key: "cta",
                title: "Reveal CTA / vessel imaging",
                systemImage: "waveform.path.ecg",
                body: s.findings.cta
            )
            revealBlock(
                key: "labs",
                title: "Reveal labs",
                systemImage: "drop",
                body: s.findings.labs
            )

            HStack(spacing: 12) {
                Button {
                    revealedFindings = ["ct", "cta", "labs"]
                } label: {
                    Label("Reveal all", systemImage: "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    revealedFindings.removeAll()
                } label: {
                    Label("Hide all", systemImage: "eye.slash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Text("Simulated case — training only")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func patientLine(_ s: StrokeCodeScenario) -> some View {
        let weight = s.demographics.weightKg.map { ", \($0) kg" } ?? ""
        return Text("Patient: \(s.demographics.ageYears) y/o \(s.demographics.sex)\(weight)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func vitalsLine(_ s: StrokeCodeScenario) -> some View {
        Text("Vitals: BP \(s.vitals.bp) · HR \(s.vitals.hr) · Glucose \(s.vitals.glucoseMgDl) mg/dL · SpO₂ \(s.vitals.oxygenSat)%")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
    }

    private func difficultyChip(_ d: StrokeCodeScenario.Difficulty) -> some View {
        let color: Color = {
            switch d {
            case .easy: return .green
            case .medium: return .blue
            case .hard: return .orange
            }
        }()
        return Text(d.label)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(color)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func revealBlock(key: String, title: String, systemImage: String, body: String) -> some View {
        let revealed = revealedFindings.contains(key)
        VStack(alignment: .leading, spacing: 4) {
            Button {
                if revealed { revealedFindings.remove(key) } else { revealedFindings.insert(key) }
            } label: {
                HStack {
                    Image(systemName: revealed ? "eye.slash" : systemImage)
                    Text(revealed ? "Hide \(title.replacingOccurrences(of: "Reveal ", with: ""))" : title)
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: revealed ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
                .padding(8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            if revealed {
                Text(body)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Helpers

    private func timeOfDay(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f.string(from: d)
    }
}

#Preview {
    StrokeCodeTimerView()
        .environmentObject(StrokeCodeStore())
}
