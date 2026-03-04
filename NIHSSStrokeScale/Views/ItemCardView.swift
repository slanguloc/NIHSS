//
//  ItemCardView.swift
//  NIHSS Stroke Scale — One item: Spanish prompt for patient, English instructions, score buttons.
//

import SwiftUI
import UIKit

private struct Item9Expanded: Identifiable {
    let index: Int
    var id: Int { index }
}

struct ItemCardView: View {
    @EnvironmentObject var spanishSpeech: SpanishSpeechService
    @EnvironmentObject var languageStore: LanguageStore
    @EnvironmentObject var patientResponse: PatientResponseService
    @State private var item9Expanded: Item9Expanded? = nil
    let step: AssessmentStep
    let selectedScore: Int?
    let onSelectScore: (Int) -> Void
    /// Optional nav bar: when set, a fixed bottom bar (Previous/Next or Finish) is shown below the scrolling content.
    var onPrevious: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    var onFinish: (() -> Void)? = nil
    var showPrevious: Bool = false
    var isLastStep: Bool = false

    var body: some View {
        VStack(spacing: 0) {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 8) {
                // Provider: item label and instructions (English)
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.providerLabel)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(step.item.providerInstructions)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Item 1b: Organized flow — prompt 1 + record + translation, prompt 2 + record + translation
                if step.item.id == "1b" {
                    PatientResponseCaptureView(
                        responseService: patientResponse,
                        spanishSpeech: spanishSpeech,
                        phrases: step.patientPhrasesToSpeak(language: languageStore.selectedLanguage)
                    )
                }

                // What to say to patient — English instruction for provider; Spanish phrases with Play (skip for 1b, shown in capture view)
                if step.item.id != "1b" {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Say or show to patient", systemImage: "person.wave.2.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    Text(step.item.providerPromptEnglish)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    if !step.patientPhrasesToSpeak(language: languageStore.selectedLanguage).isEmpty {
                        Text("In \(languageStore.selectedLanguage.displayName) (tap to play)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(step.patientPhrasesToSpeak(language: languageStore.selectedLanguage).enumerated()), id: \.offset) { index, phrase in
                        let hasImage = step.item.id == "9",
                            imageNames = step.item.spanishPhraseImageNames,
                            imageName = (imageNames != nil && index < imageNames!.count && !imageNames![index].isEmpty) ? imageNames![index] : nil
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 6) {
                                if step.patientPhrasesToSpeak(language: languageStore.selectedLanguage).count > 1 {
                                    Text("\(index + 1).")
                                        .font(.subheadline.bold().monospacedDigit())
                                        .foregroundStyle(.orange)
                                        .frame(width: 20, alignment: .leading)
                                }
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
                                        .foregroundStyle(.orange)
                                }
                                .buttonStyle(.plain)
                            }
                            // Item 9: show figure image below each prompt (Figure 2, 3, 4 from Mayo PDF)
                            if let assetName = imageName {
                                ZStack {
                                    Color.gray.opacity(0.08)
                                    Image(assetName)
                                        .resizable()
                                        .scaledToFit()
                                    if UIImage(named: assetName) == nil {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 32))
                                                .foregroundStyle(.secondary)
                                            Text("Add \(assetName) to Assets")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding()
                                    }
                                }
                                .frame(minHeight: 140, maxHeight: 220)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .overlay(alignment: .topTrailing) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    item9Expanded = Item9Expanded(index: index)
                                }
                            }
                            // Item 9 subsections 1 and 3: speech-to-text capture
                            if step.item.id == "9", (index == 0 || index == 2) {
                                let key = index == 0 ? "9-0" : "9-2"
                                let response = patientResponse.responseForItem9(subsectionIndex: index)
                                let isRecordingThis = patientResponse.isRecordingItem9(subsectionIndex: index)
                                VStack(alignment: .leading, spacing: 8) {
                                    Button {
                                        if isRecordingThis {
                                            patientResponse.stopRecording()
                                        } else {
                                                    patientResponse.requestAuthorization { granted in
                                                        if granted {
                                                            patientResponse.startRecording(key: key, language: languageStore.selectedLanguage)
                                                        }
                                                    }
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: isRecordingThis ? "stop.circle.fill" : "mic.circle.fill")
                                                .font(.title3)
                                            Text(isRecordingThis ? "Stop recording" : "Record patient response")
                                                .font(.caption.bold())
                                        }
                                        .padding(6)
                                        .frame(maxWidth: .infinity)
                                        .background(isRecordingThis ? Color.red.opacity(0.2) : Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(patientResponse.authorizationStatus == .denied || (patientResponse.isRecording && !isRecordingThis))
                                    if !response.transcribed.isEmpty || !response.translated.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            if !response.transcribed.isEmpty {
                                                Text("Patient said: \(response.transcribed)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            if !response.translated.isEmpty {
                                                Text("Translation (English): \(response.translated)")
                                                    .font(.caption.bold())
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            // Item 8 (Sensory): speech-to-text capture (one button after last phrase)
                            if step.item.id == "8", index == 2 {
                                let response = patientResponse.responseForItem8()
                                let isRecordingThis = patientResponse.isRecordingItem8()
                                VStack(alignment: .leading, spacing: 8) {
                                    Button {
                                        if isRecordingThis {
                                            patientResponse.stopRecording()
                                        } else {
                                            patientResponse.requestAuthorization { granted in
                                                if granted {
                                                    patientResponse.startRecording(key: "8", language: languageStore.selectedLanguage)
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: isRecordingThis ? "stop.circle.fill" : "mic.circle.fill")
                                                .font(.title3)
                                            Text(isRecordingThis ? "Stop recording" : "Record patient response")
                                                .font(.caption.bold())
                                        }
                                        .padding(6)
                                        .frame(maxWidth: .infinity)
                                        .background(isRecordingThis ? Color.red.opacity(0.2) : Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(patientResponse.authorizationStatus == .denied || (patientResponse.isRecording && !isRecordingThis))
                                    if !response.transcribed.isEmpty || !response.translated.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            if !response.transcribed.isEmpty {
                                                Text("Patient said: \(response.transcribed)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            if !response.translated.isEmpty {
                                                Text("Translation (English): \(response.translated)")
                                                    .font(.caption.bold())
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            // Item 11 (Extinction/Inattention): speech-to-text capture (after both sensory + visual prompts)
                            if step.item.id == "11", index == 1 {
                                let response = patientResponse.responseForItem11()
                                let isRecordingThis = patientResponse.isRecordingItem11()
                                VStack(alignment: .leading, spacing: 8) {
                                    Button {
                                        if isRecordingThis {
                                            patientResponse.stopRecording()
                                        } else {
                                            patientResponse.requestAuthorization { granted in
                                                if granted {
                                                    patientResponse.startRecording(key: "11", language: languageStore.selectedLanguage)
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: isRecordingThis ? "stop.circle.fill" : "mic.circle.fill")
                                                .font(.title3)
                                            Text(isRecordingThis ? "Stop recording" : "Record patient response")
                                                .font(.caption.bold())
                                        }
                                        .padding(6)
                                        .frame(maxWidth: .infinity)
                                        .background(isRecordingThis ? Color.red.opacity(0.2) : Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(patientResponse.authorizationStatus == .denied || (patientResponse.isRecording && !isRecordingThis))
                                    if !response.transcribed.isEmpty || !response.translated.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            if !response.transcribed.isEmpty {
                                                Text("Patient said: \(response.transcribed)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            if !response.translated.isEmpty {
                                                Text("Translation (English): \(response.translated)")
                                                    .font(.caption.bold())
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                }

                // Score options
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score")
                        .font(.subheadline.bold())
                    FlowLayout(spacing: 8) {
                        ForEach(step.item.options) { opt in
                            ScoreButton(
                                score: opt.score,
                                label: opt.englishText,
                                isSelected: selectedScore == opt.score,
                                action: { onSelectScore(opt.score) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

            if onNext != nil || onFinish != nil {
                Divider()
                HStack(spacing: 16) {
                    if showPrevious, let onPrevious = onPrevious {
                        Button("Previous", action: onPrevious)
                            .buttonStyle(.bordered)
                    }
                    Spacer()
                    if isLastStep, let onFinish = onFinish {
                        Button("Finish", action: onFinish)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                    } else if let onNext = onNext {
                        Button("Next", action: onNext)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(item: $item9Expanded) { expanded in
            let idx = expanded.index
            let patientPhrases = step.patientPhrasesToSpeak(language: languageStore.selectedLanguage)
            if idx < patientPhrases.count,
               let imageNames = step.item.spanishPhraseImageNames,
               idx < imageNames.count,
               !imageNames[idx].isEmpty {
                Item9FullScreenView(
                    phrase: patientPhrases[idx],
                    imageName: imageNames[idx],
                    subsectionIndex: idx,
                    onDismiss: { item9Expanded = nil }
                )
                .environmentObject(spanishSpeech)
                .environmentObject(languageStore)
                .environmentObject(patientResponse)
            }
        }
    }
}

/// Full-screen overlay for item 9 subset: Patient prompt + large image. Subsections 1 and 3 (index 0, 2) show record button at bottom.
private struct Item9FullScreenView: View {
    @EnvironmentObject var spanishSpeech: SpanishSpeechService
    @EnvironmentObject var languageStore: LanguageStore
    @EnvironmentObject var patientResponse: PatientResponseService
    let phrase: String
    let imageName: String
    /// Item 9 phrase index: 0 = 9.1, 1 = 9.2, 2 = 9.3. Only 0 and 2 show record UI.
    let subsectionIndex: Int
    let onDismiss: () -> Void

    private var showRecordButton: Bool { subsectionIndex == 0 || subsectionIndex == 2 }
    private var recordKey: String { subsectionIndex == 0 ? "9-0" : "9-2" }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
                    .padding(.bottom, 0)
                }
                ScrollView {
                    VStack(spacing: 12) {
                        Text(phrase)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        HStack {
                            Button {
                                if spanishSpeech.isSpeaking {
                                    spanishSpeech.stop()
                                } else {
                                    spanishSpeech.speak(phrase, language: languageStore.selectedLanguage)
                                }
                            } label: {
                                Label(spanishSpeech.isSpeaking ? "Stop" : "Play", systemImage: spanishSpeech.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .padding(.horizontal)
                        ZStack {
                            Color.gray.opacity(0.15)
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        Text("Source: Mayo Clinic Proc 2006;81:476-480")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.bottom, showRecordButton ? 8 : 16)
                }
                // Record patient response for subsections 9.1 and 9.3 — always visible at bottom when full screen
                if showRecordButton {
                    let response = patientResponse.responseForItem9(subsectionIndex: subsectionIndex)
                    let isRecordingThis = patientResponse.isRecordingItem9(subsectionIndex: subsectionIndex)
                    VStack(alignment: .leading, spacing: 6) {
                        Button {
                            if isRecordingThis {
                                patientResponse.stopRecording()
                            } else {
                                    patientResponse.requestAuthorization { granted in
                                        if granted {
                                            patientResponse.startRecording(key: recordKey, language: languageStore.selectedLanguage)
                                        }
                                    }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isRecordingThis ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.title3)
                                Text(isRecordingThis ? "Stop recording" : "Record patient response")
                                    .font(.caption.bold())
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(isRecordingThis ? Color.red.opacity(0.3) : Color.blue.opacity(0.25))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(patientResponse.authorizationStatus == .denied || (patientResponse.isRecording && !isRecordingThis))
                        if !response.transcribed.isEmpty || !response.translated.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                if !response.transcribed.isEmpty {
                                    Text("Patient said: \(response.transcribed)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                if !response.translated.isEmpty {
                                    Text("Translation (English): \(response.translated)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                }
            }
        }
    }
}

private struct ScoreButton: View {
    let score: Int
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(score)")
                    .font(.title2.bold().monospacedDigit())
                Text(label)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.red.opacity(0.25) : Color.gray.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

/// Simple flow layout for score buttons.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, pos) in result.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    let step = NIHSSData.assessmentSteps().first!
    return ScrollView {
        ItemCardView(step: step, selectedScore: 0, onSelectScore: { _ in })
            .environmentObject(SpanishSpeechService())
            .environmentObject(LanguageStore())
            .environmentObject(PatientResponseService())
    }
}
