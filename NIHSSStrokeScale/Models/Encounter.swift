//
//  Encounter.swift
//  NIHSS Stroke Scale — Encounter history (up to 50).
//

import Foundation

/// One completed assessment encounter.
struct Encounter: Identifiable, Codable {
    let id: UUID
    let completedAt: Date
    let totalScore: Int
    let scores: [String: Int]

    init(id: UUID = UUID(), completedAt: Date, totalScore: Int, scores: [String: Int]) {
        self.id = id
        self.completedAt = completedAt
        self.totalScore = totalScore
        self.scores = scores
    }
}

private let maxEncounters = 50
private let userDefaultsKey = "NIHSSEncounterHistory"

/// Stores up to 50 encounters with persistence.
final class EncounterStore: ObservableObject {
    @Published var encounters: [Encounter] = []

    init() {
        load()
    }

    func addEncounter(from state: AssessmentState) {
        let encounter = Encounter(
            completedAt: Date(),
            totalScore: state.totalScore,
            scores: state.scores
        )
        encounters.insert(encounter, at: 0)
        if encounters.count > maxEncounters {
            encounters = Array(encounters.prefix(maxEncounters))
        }
        save()
    }

    func score(for stepId: String, in encounter: Encounter) -> Int? {
        encounter.scores[stepId]
    }

    private func load() {
        guard let stored = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        let dataToDecode = LocalEncryptedStorage.decrypt(stored) ?? stored
        if let decoded = try? JSONDecoder().decode([Encounter].self, from: dataToDecode) {
            encounters = decoded
        }
    }

    private func save() {
        guard let plain = try? JSONEncoder().encode(encounters),
              let encrypted = LocalEncryptedStorage.encrypt(plain) else { return }
        UserDefaults.standard.set(encrypted, forKey: userDefaultsKey)
    }
}
