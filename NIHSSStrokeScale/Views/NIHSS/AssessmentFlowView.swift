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

    /// Optional callback invoked with the final NIHSS total when the user
    /// finishes the assessment. Used by the Stroke Code Timer to record the
    /// total on the active stroke-code session.
    var onComplete: ((Int) -> Void)? = nil

    private var currentStep: AssessmentStep? { state.step(at: currentIndex) }
    private var isLastStep: Bool { currentIndex >= state.totalSteps - 1 }

    var body: some View {
        VStack(spacing: 0) {
            // Top nav bar. The white background extends edge-to-edge (under the
            // status bar / Dynamic Island via `ignoresSafeArea` on the background
            // ONLY), while the content itself respects the safe area and adds a
            // small buffer so the title is not flush against the Dynamic Island.
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                    }
                    Spacer(minLength: 0)
                    Text("Zysquy")
                        .font(.headline)
                    Spacer(minLength: 0)
                    PatientLanguagePicker(style: .toolbarIcon)
                    Text("Total: \(state.totalScore)")
                        .font(.subheadline.monospacedDigit().bold())
                        .frame(minWidth: 52, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)

                progressBar
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .background(Color(.systemBackground).ignoresSafeArea(edges: .top))

            if let step = currentStep {
                ItemCardView(
                    step: step,
                    selectedScore: state.score(for: step.id),
                    onSelectScore: { state.setScore(step.id, $0) },
                    onPrevious: { currentIndex -= 1 },
                    onNext: { currentIndex += 1 },
                    onFinish: {
                        encounterStore.addEncounter(from: state)
                        onComplete?(state.totalScore)
                        showSummary = true
                    },
                    showPrevious: currentIndex > 0,
                    isLastStep: isLastStep
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showSummary) {
            SummaryView(state: state)
                .onDisappear { dismiss() }
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
