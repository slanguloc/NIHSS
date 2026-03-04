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
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        HStack {
                            Button {
                                onChangeLanguage()
                            } label: {
                                Label(languageStore.selectedLanguage.displayName, systemImage: "globe")
                            }
                            Spacer()
                            Button {
                                showingHistory = true
                            } label: {
                                Label("History", systemImage: "clock.arrow.circlepath")
                            }
                        }
                        .font(.subheadline)
                        .padding(.top, 8)

                        header
                            .padding(.top, 12)
                        if state.scores.count > 0 {
                            resumeOrNewSection(state: state, showingAssessment: $showingAssessment)
                        }
                        Spacer(minLength: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scrollIndicators(.visible)

                Divider()
                startButton
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .ignoresSafeArea(edges: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: [.top, .bottom])
            .navigationBarTitleDisplayMode(.inline)
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
            .background(Color(.systemBackground))
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain")
                .font(.system(size: 56))
                .foregroundStyle(.red.gradient)
            Text("Zysquy")
                .font(.title.bold())
            Text("NIH Stroke Scale for non-English speaking patients")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("\(languageStore.selectedLanguage.displayName) patient support")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text("For English-speaking providers during stroke code")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Text("For education only. Not for clinical use.")
                .font(.caption2)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
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
