//
//  EncounterDetailView.swift
//  NIHSS Stroke Scale — Read-only view of a past encounter.
//

import SwiftUI

struct EncounterDetailView: View {
    let encounter: Encounter

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    private var steps: [AssessmentStep] {
        NIHSSData.assessmentSteps()
    }

    var body: some View {
        List {
            Section("Encounter") {
                HStack {
                    Text("Completed")
                    Spacer()
                    Text(dateFormatter.string(from: encounter.completedAt))
                        .foregroundStyle(.secondary)
                }
            }
            Section("Total score") {
                HStack {
                    Text("NIHSS total")
                    Spacer()
                    Text("\(encounter.totalScore)")
                        .font(.title2.bold().monospacedDigit())
                }
            }
            Section("By item") {
                ForEach(steps) { step in
                    HStack {
                        Text(step.providerLabel)
                        Spacer()
                        if let s = encounter.scores[step.id] {
                            Text("\(s)")
                                .font(.body.monospacedDigit().bold())
                        } else {
                            Text("—")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Encounter details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
