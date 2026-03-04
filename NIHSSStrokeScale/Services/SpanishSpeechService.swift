//
//  SpanishSpeechService.swift
//  NIHSS Stroke Scale — Text-to-speech for Spanish patient commands.
//

import AVFoundation
import SwiftUI

/// Speaks patient prompts aloud using the selected language.
final class SpanishSpeechService: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false
    /// When set, the UI should show an alert with instructions to install a voice.
    @Published var noVoiceAvailableMessage: String?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Resolves a voice for the language: preferred locale, then fallbacks, then any installed voice for that language.
    private func voice(for language: AppLanguage) -> AVSpeechSynthesisVoice? {
        let codes = [language.speechLocale] + language.speechFallbacks
        for code in codes {
            if let voice = AVSpeechSynthesisVoice(language: code) {
                return voice
            }
        }
        let prefix = language.voiceLanguagePrefix
        return AVSpeechSynthesisVoice.speechVoices().first { voice in
            voice.language.hasPrefix(prefix)
        }
    }

    /// Speaks the given text using the selected language's voice.
    func speak(_ text: String, language: AppLanguage = .spanish) {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let chosenVoice = voice(for: language) else {
            noVoiceAvailableMessage = noVoiceInstructions(for: language)
            return
        }
        noVoiceAvailableMessage = nil
        configureAudioSessionForPlayback()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = chosenVoice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.volume = 1.0
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    /// Instructions shown when no TTS voice is available for the language.
    private func noVoiceInstructions(for language: AppLanguage) -> String {
        let name = language.displayName
        return "No \(name) voice is installed on this device. To enable speech: Open Settings → Accessibility → Spoken Content → Voices, then download a \(name) voice."
    }

    /// Call when the user dismisses the no-voice alert.
    func clearNoVoiceMessage() {
        noVoiceAvailableMessage = nil
    }

    /// Ensures TTS can play (e.g. when device is on silent or another app had audio).
    private func configureAudioSessionForPlayback() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            // Non-fatal: system may still play; avoids breaking if session is locked
        }
    }

    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

extension SpanishSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }
}
