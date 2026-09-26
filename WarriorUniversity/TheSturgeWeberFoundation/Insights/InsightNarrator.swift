import Foundation
import Combine
import FoundationModels

/// Optional AI layer for Seizure Insights.
///
/// Uses Apple's on-device Foundation Models framework (iOS 26+), so nothing
/// leaves the device. The model only receives the facts computed by
/// SeizurePatternAnalyzer — never names, notes, or raw timestamps — and is
/// told not to add numbers or give medical advice.
@MainActor
final class InsightNarrator: ObservableObject {
    enum Status: Equatable {
        case idle
        case working
        case done(String)
        case failed(String)
    }

    @Published private(set) var status: Status = .idle

    /// nil when the on-device model is ready, otherwise a caregiver-friendly reason.
    var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "This device doesn't support Apple Intelligence, so the written summary isn't available. The facts above are complete on their own."
            case .appleIntelligenceNotEnabled:
                return "Turn on Apple Intelligence in Settings to get a written summary."
            case .modelNotReady:
                return "The on-device model is still downloading. Try again later."
            @unknown default:
                return "The written summary isn't available on this device right now."
            }
        }
    }

    func reset() { status = .idle }

    func summarize(facts: [String]) async {
        guard unavailableReason == nil, !facts.isEmpty else { return }
        status = .working

        let instructions = """
        You help caregivers of people with Sturge-Weber syndrome read their own seizure log. \
        Rewrite the facts you are given as one calm, plain-language paragraph of 3 to 5 sentences. \
        Use only the facts and numbers provided. Do not add numbers, guess at causes, diagnose, \
        or suggest treatments or medication changes. \
        End by suggesting they go over the log with their care team.
        """
        let prompt = "Facts from the seizure log:\n" + facts.map { "- \($0)" }.joined(separator: "\n")

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            status = .done(response.content.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            status = .failed("Couldn't write a summary this time. The facts above are still accurate.")
        }
    }
}
