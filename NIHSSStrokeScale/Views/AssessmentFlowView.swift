//
//  AssessmentFlowView.swift
//  NIHSS Stroke Scale — Step-by-step with Spanish prompts.
//

import SwiftUI

struct AssessmentFlowView: View {
    @ObservedObject var state: AssessmentState
    @EnvironmentObject var encounterStore: EncounterStore
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var showSummary = false

    private var currentStep: AssessmentStep? { state.step(at: currentIndex) }
    private var isLastStep: Bool { currentIndex >= state.totalSteps - 1 }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            if let step = currentStep {
                ItemCardView(
                    step: step,
                    selectedScore: state.score(for: step.id),
                    onSelectScore: { state.setScore(step.id, $0) }
                )
                .frame(minHeight: 0, maxHeight: .infinity)
            }
            navButtons
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSummary) {
            SummaryView(state: state)
                .onDisappear { dismiss() }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Zysquy")
                    .font(.headline)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Text("Total: \(state.totalScore)")
                    .font(.subheadline.monospacedDigit().bold())
            }
        }
    }

    private var progressBar: some View {
        let progress = state.totalSteps > 0 ? Double(currentIndex + 1) / Double(state.totalSteps) : 0
        return GeometryReader { g in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                Rectangle()
                    .fill(Color.red)
                    .frame(width: g.size.width * progress)
            }
        }
        .frame(height: 4)
    }

    private var navButtons: some View {
        HStack(spacing: 16) {
            if currentIndex > 0 {
                Button("Previous") {
                    currentIndex -= 1
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            if isLastStep {
                Button("Finish") {
                    encounterStore.addEncounter(from: state)
                    showSummary = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button("Next") {
                    currentIndex += 1
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 4)
    }
}

#Preview {
    NavigationStack {
        AssessmentFlowView(state: AssessmentState())
            .environmentObject(EncounterStore())
            .environmentObject(SpanishSpeechService())
            .environmentObject(LanguageStore())
            .environmentObject(PatientResponseService())
    }
}
