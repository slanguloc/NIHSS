//
//  ContentView.swift
//  NIHSS Stroke Scale — Spanish Patient Support
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var languageStore: LanguageStore
    @StateObject private var state = AssessmentState()
    @StateObject private var encounterStore = EncounterStore()
    @State private var showingAssessment = false
    @State private var showingHistory = false
    var onChangeLanguage: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    header
                    startButton
                    if state.scores.count > 0 {
                        resumeOrNewSection(state: state, showingAssessment: $showingAssessment)
                    }
                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 2)
                .padding(.bottom, 4)
            }
            .scrollIndicators(.visible)
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onChangeLanguage()
                    } label: {
                        Label(languageStore.selectedLanguage.displayName, systemImage: "globe")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red.gradient)
            Text("NIH Stroke Scale")
                .font(.title.bold())
            Text("\(languageStore.selectedLanguage.displayName) patient support")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("For English-speaking providers during stroke code")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 0)
    }

    private var startButton: some View {
        Button {
            if state.scores.isEmpty {
                showingAssessment = true
            } else {
                showingAssessment = true
            }
        } label: {
            Label(state.scores.isEmpty ? "Start assessment" : "Continue assessment", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .padding(.horizontal, 24)
        .padding(.top, 2)
    }

    private func resumeOrNewSection(state: AssessmentState, showingAssessment: Binding<Bool>) -> some View {
        VStack(spacing: 12) {
            Text("Current total: \(state.totalScore)")
                .font(.title2.monospacedDigit().bold())
            HStack(spacing: 16) {
                Button("New assessment") {
                    state.reset()
                    showingAssessment.wrappedValue = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(LanguageStore())
}
