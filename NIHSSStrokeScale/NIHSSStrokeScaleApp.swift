//
//  NIHSSStrokeScaleApp.swift
//  NIHSS Stroke Scale — Multi-language patient support
//

import SwiftUI

@main
struct NIHSSStrokeScaleApp: App {
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var spanishSpeech = SpanishSpeechService()
    @StateObject private var patientResponse = PatientResponseService()

    var body: some Scene {
        WindowGroup {
            RootView(languageStore: languageStore)
                .environmentObject(languageStore)
                .environmentObject(spanishSpeech)
                .environmentObject(patientResponse)
        }
    }
}

/// Shows language selection on first launch, then main app.
private struct RootView: View {
    @ObservedObject var languageStore: LanguageStore
    @State private var showLanguageSelection: Bool

    init(languageStore: LanguageStore) {
        self.languageStore = languageStore
        _showLanguageSelection = State(initialValue: !languageStore.hasCompletedLanguageSelection)
    }

    var body: some View {
        Group {
            if showLanguageSelection {
                LanguageSelectionView(languageStore: languageStore) {
                    showLanguageSelection = false
                }
            } else {
                ContentView(onChangeLanguage: { showLanguageSelection = true })
            }
        }
    }
}
