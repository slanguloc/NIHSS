//
//  AssessmentState.swift
//  NIHSS Stroke Scale
//

import Foundation
import SwiftUI

/// Holds scores for each assessment step and computes total.
final class AssessmentState: ObservableObject {
    @Published var scores: [String: Int] = [:]
    private let steps = NIHSSData.assessmentSteps()

    func score(for stepId: String) -> Int? { scores[stepId] }

    func setScore(_ stepId: String, _ value: Int) {
        scores[stepId] = value
    }

    var totalScore: Int {
        steps.map { score(for: $0.id) ?? 0 }.reduce(0, +)
    }

    var stepsCompleted: Int {
        steps.filter { score(for: $0.id) != nil }.count
    }

    var totalSteps: Int { steps.count }

    func step(at index: Int) -> AssessmentStep? {
        guard index >= 0, index < steps.count else { return nil }
        return steps[index]
    }

    var allSteps: [AssessmentStep] { steps }

    func reset() {
        scores.removeAll()
    }
}
