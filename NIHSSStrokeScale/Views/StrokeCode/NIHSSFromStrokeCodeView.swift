//
//  NIHSSFromStrokeCodeView.swift
//  Zysquy — Launches the NIHSS assessment from inside the Stroke Code
//  Timer, with a callback so the captured total flows back into the
//  active stroke-code session.
//
//  Education and training only.
//

import SwiftUI

/// Hosts an in-context NIHSS run with its own assessment state and encounter
/// store. When the trainee finishes, `onCompleted` is invoked with the
/// total NIHSS score; the parent Stroke Code Timer uses it to capture the
/// NIHSS milestone and store the total on the active session.
struct NIHSSFromStrokeCodeView: View {
    @StateObject private var state = AssessmentState()
    @StateObject private var encounterStore = EncounterStore()
    @Environment(\.dismiss) private var dismiss

    var onCompleted: (Int) -> Void

    var body: some View {
        NavigationStack {
            AssessmentFlowView(
                state: state,
                onComplete: { total in
                    onCompleted(total)
                }
            )
            .environmentObject(encounterStore)
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(.thinMaterial, in: Circle())
                }
                .padding(.top, 44)
                .padding(.trailing, 12)
                .accessibilityLabel("Close NIHSS")
            }
        }
    }
}

#Preview {
    NIHSSFromStrokeCodeView(onCompleted: { _ in })
        .environmentObject(LanguageStore())
        .environmentObject(SpanishSpeechService())
        .environmentObject(PatientResponseService())
}
