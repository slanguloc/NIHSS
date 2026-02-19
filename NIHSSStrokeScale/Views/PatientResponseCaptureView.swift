//
//  PatientResponseCaptureView.swift
//  NIHSS Stroke Scale — Capture patient response with mic (item 1b).
//

import SwiftUI

struct PatientResponseCaptureView: View {
    @ObservedObject var responseService: PatientResponseService
    @ObservedObject var spanishSpeech: SpanishSpeechService
    @EnvironmentObject var languageStore: LanguageStore
    let phrases: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Capture patient response", systemImage: "mic.fill")
                .font(.caption.bold())
                .foregroundStyle(.blue)

            if let error = responseService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            ForEach(Array(phrases.enumerated()), id: \.offset) { index, phrase in
                VStack(alignment: .leading, spacing: 6) {
                    // 1. Prompt in Spanish (with Play)
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(.blue)
                        Text(phrase)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            if spanishSpeech.isSpeaking {
                                spanishSpeech.stop()
                            } else {
                                spanishSpeech.speak(phrase, language: languageStore.selectedLanguage)
                            }
                        } label: {
                            Image(systemName: spanishSpeech.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // 2. Record button
                    Button {
                        if responseService.isRecording && responseService.recordingQuestionIndex == index {
                            responseService.stopRecording()
                        } else if !responseService.isRecording {
                            responseService.requestAuthorization { granted in
                                if granted {
                                    responseService.startRecording(questionIndex: index)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: (responseService.isRecording && responseService.recordingQuestionIndex == index) ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                            Text((responseService.isRecording && responseService.recordingQuestionIndex == index) ? "Stop recording" : "Record response")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background((responseService.isRecording && responseService.recordingQuestionIndex == index) ? Color.red.opacity(0.2) : Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(responseService.authorizationStatus == .denied || (responseService.isRecording && responseService.recordingQuestionIndex != index))

                    // 3. Translation
                    let (transcribed, translated) = index == 0
                        ? (responseService.response1Transcribed, responseService.response1Translated)
                        : (responseService.response2Transcribed, responseService.response2Translated)
                    if !transcribed.isEmpty || !translated.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            if !transcribed.isEmpty {
                                Text("Patient said: \(transcribed)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if !translated.isEmpty {
                                Text("Translation (English): \(translated)")
                                    .font(.subheadline.bold())
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(6)
        .background(Color.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
