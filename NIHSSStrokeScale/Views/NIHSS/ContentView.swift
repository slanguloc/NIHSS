//
//  ContentView.swift
//  Zysquy — NIHSS Assessment module hub.
//
//  Module-level landing for the NIH Stroke Scale assessment. Pushed from
//  HomeView; uses the parent NavigationStack for back navigation.
//  Education and training only.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var languageStore: LanguageStore
    @StateObject private var state = AssessmentState()
    @StateObject private var encounterStore = EncounterStore()
    @State private var showingAssessment = false
    @State private var showingHistory = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    header
                    if state.scores.count > 0 {
                        resumeOrNewSection
                    }
                    disclaimerBanner
                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollIndicators(.visible)

            Divider()
            startButton
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("NIHSS Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                PatientLanguagePicker(style: .toolbarIcon)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingHistory = true
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .navigationDestination(isPresented: $showingAssessment) {
            AssessmentFlowView(state: state)
                .environmentObject(encounterStore)
        }
        .sheet(isPresented: $showingHistory) {
            NavigationStack {
                EncounterHistoryView()
                    .environmentObject(encounterStore)
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain")
                .font(.system(size: 56))
                .foregroundStyle(.red.gradient)
            Text("NIH Stroke Scale")
                .font(.title2.bold())
            Text("Stepwise NIHSS with English provider instructions and \(languageStore.selectedLanguage.displayName) patient prompts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    private var startButton: some View {
        Button {
            showingAssessment = true
        } label: {
            Label(state.scores.isEmpty ? "Start assessment" : "Continue assessment",
                  systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .padding(.horizontal, 24)
    }

    private var resumeOrNewSection: some View {
        VStack(spacing: 8) {
            Text("Current total: \(state.totalScore)")
                .font(.title3.monospacedDigit().bold())
            Button("New assessment") {
                state.reset()
                showingAssessment = true
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }

    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Education and training only")
                    .font(.subheadline.bold())
                Text("Not a medical device. Not for clinical use. Does not replace formal NIHSS certification.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environmentObject(LanguageStore())
    }
}
