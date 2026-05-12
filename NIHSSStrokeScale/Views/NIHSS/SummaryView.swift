//
//  SummaryView.swift
//  NIHSS Stroke Scale — Final report: timestamp, total score, item breakdown.
//

import SwiftUI

struct SummaryView: View {
    @ObservedObject var state: AssessmentState
    @Environment(\.dismiss) private var dismiss
    @State private var completedAt: Date?

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Encounter") {
                    HStack {
                        Text("Completed")
                        Spacer()
                        Text(completedAt.map { dateFormatter.string(from: $0) } ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Total score") {
                    HStack {
                        Text("NIHSS total")
                        Spacer()
                        Text("\(state.totalScore)")
                            .font(.title2.bold().monospacedDigit())
                    }
                }
                Section("By item") {
                    ForEach(state.allSteps) { step in
                        HStack {
                            Text(step.providerLabel)
                            Spacer()
                            if let s = state.score(for: step.id) {
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
            .navigationTitle("Assessment summary")
            .onAppear {
                if completedAt == nil { completedAt = Date() }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
