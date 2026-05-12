//
//  StrokeCodeScenarioPickerView.swift
//  Zysquy — Scenario picker for the simulated stroke-code case bank.
//
//  Lets an educator pick a scenario, preview its vignette and expected
//  decisions, and "drop it in" to start a training session pre-populated
//  with the scenario's anchor times. Education/training only.
//

import SwiftUI

struct StrokeCodeScenarioPickerView: View {
    @EnvironmentObject var store: StrokeCodeStore
    @Environment(\.dismiss) private var dismiss

    /// Called after a scenario has been loaded into `store.active`.
    var onLoaded: () -> Void = {}

    var body: some View {
        List {
            Section {
                Text("Educator-curated cases. Loading a case starts a training session pre-populated with the scenario's Last Known Well, EMS, and Door times. The trainee then runs the full timeline and decision flow.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Education and training only. Not for clinical use.")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }

            Section("Case bank") {
                ForEach(StrokeCodeScenarioBank.all) { scenario in
                    NavigationLink {
                        StrokeCodeScenarioDetailView(scenario: scenario) {
                            store.startFromScenario(scenario)
                            dismiss()
                            onLoaded()
                        }
                    } label: {
                        scenarioRow(scenario)
                    }
                }
            }
        }
        .navigationTitle("Load scenario")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func scenarioRow(_ s: StrokeCodeScenario) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(s.title)
                    .font(.body.weight(.semibold))
                Spacer()
                difficultyBadge(s.difficulty)
            }
            Text(s.oneLiner)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }

    private func difficultyBadge(_ d: StrokeCodeScenario.Difficulty) -> some View {
        let color: Color = {
            switch d {
            case .easy: return .green
            case .medium: return .blue
            case .hard: return .orange
            }
        }()
        return Text(d.label)
            .font(.caption.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(color)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Detail / preview

struct StrokeCodeScenarioDetailView: View {
    let scenario: StrokeCodeScenario
    var onLoad: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                disclaimer

                vignetteCard

                demographicsCard

                vitalsCard

                timingCard

                educatorCard

                Button {
                    onLoad()
                } label: {
                    Label("Load this case (start training session)", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.top, 4)

                Text("Loading sets LKW, EMS, and Door anchors as if the case is happening now. Findings (CT, CTA, labs) appear in the Case briefing card and are revealed as the trainee progresses.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(16)
        }
        .navigationTitle(scenario.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(.orange)
            Text("Simulated case — for training only. Not a real patient. Not for clinical decisions.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var vignetteCard: some View {
        card(title: "Clinical vignette", systemImage: "text.alignleft") {
            Text(scenario.vignette)
                .font(.body)
        }
    }

    private var demographicsCard: some View {
        card(title: "Patient", systemImage: "person.fill") {
            Text("\(scenario.demographics.ageYears) y/o \(scenario.demographics.sex)" +
                 (scenario.demographics.weightKg.map { ", \($0) kg" } ?? ""))
                .font(.body)
            if !scenario.history.isEmpty {
                Text("History / meds")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                ForEach(scenario.history, id: \.self) { item in
                    Text("• \(item)")
                        .font(.subheadline)
                }
            }
            if let n = scenario.presentingNihss {
                Text("Presenting NIHSS: \(n)")
                    .font(.subheadline.bold())
                    .padding(.top, 4)
            }
        }
    }

    private var vitalsCard: some View {
        card(title: "Initial vitals", systemImage: "waveform.path") {
            HStack {
                vitalCell(label: "BP", value: scenario.vitals.bp)
                vitalCell(label: "HR", value: "\(scenario.vitals.hr)")
                vitalCell(label: "Glucose", value: "\(scenario.vitals.glucoseMgDl)")
                vitalCell(label: "SpO₂", value: "\(scenario.vitals.oxygenSat)%")
            }
        }
    }

    private func vitalCell(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity)
    }

    private var timingCard: some View {
        card(title: "Timing on load", systemImage: "clock") {
            timingRow("Last Known Well", scenario.timing.lkwMinutesAgo)
            timingRow("Symptom discovery", scenario.timing.symptomDiscoveryMinutesAgo)
            timingRow("EMS on scene", scenario.timing.emsArrivalMinutesAgo)
            timingRow("ED arrival (Door)", scenario.timing.doorMinutesAgo)
        }
    }

    private func timingRow(_ label: String, _ minutesAgo: Int?) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(minutesAgo.map { "\($0) min ago" } ?? "Unknown")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var educatorCard: some View {
        card(title: "Educator notes", systemImage: "graduationcap") {
            HStack {
                Text("Expected thrombolytic")
                Spacer()
                Text(scenario.expected.thrombolytic.label)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Expected EVT")
                Spacer()
                Text(scenario.expected.evt.label)
                    .foregroundStyle(.secondary)
            }
            Text(scenario.expected.rationale)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            if !scenario.teachingPoints.isEmpty {
                Text("Teaching points")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                ForEach(scenario.teachingPoints, id: \.self) { p in
                    Text("• \(p)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func card<Content: View>(title: String,
                                     systemImage: String,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        StrokeCodeScenarioPickerView()
            .environmentObject(StrokeCodeStore())
    }
}
