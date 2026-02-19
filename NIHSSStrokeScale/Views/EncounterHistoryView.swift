//
//  EncounterHistoryView.swift
//  NIHSS Stroke Scale — Review past encounters.
//

import SwiftUI

struct EncounterHistoryView: View {
    @EnvironmentObject var encounterStore: EncounterStore
    @Environment(\.dismiss) private var dismiss

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    var body: some View {
        Group {
            if encounterStore.encounters.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No encounters yet")
                        .font(.headline)
                    Text("Completed assessments will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 16)
            } else {
                List {
                    ForEach(encounterStore.encounters) { encounter in
                        NavigationLink {
                            EncounterDetailView(encounter: encounter)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dateFormatter.string(from: encounter.completedAt))
                                        .font(.body)
                                    Text("NIHSS total: \(encounter.totalScore)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(encounter.totalScore)")
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(.red)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Encounter history")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
