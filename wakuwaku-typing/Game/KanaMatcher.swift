import Foundation

/// Lenient kana matcher for flick input.
///
/// Rules:
/// - When user inputs a kana K:
///   - If K matches the next expected kana → commit, .correct
///   - Else if K is in a modifier cycle that contains expectedNext → mark pending, .pending (no penalty yet)
///   - Else → .wrong (combo break)
/// - When user applies modifier:
///   - Cycle pending; if cycled kana matches expected → commit, .correct
///   - Else → keep cycling, .pending
///   - With no pending → .ignored (no penalty)
struct KanaMatcher {
    let target: String

    private(set) var done: String = ""
    private(set) var pending: Character?

    enum InputResult: Equatable {
        case correct      // committed and matched
        case pending      // awaiting modifier
        case wrong        // doesn't match and can't be modified to match
        case complete     // word finished
        case ignored      // no-op (e.g., modifier with no pending)
    }

    init(target: String) {
        self.target = target
    }

    var expectedNext: Character? {
        target.dropFirst(done.count).first
    }

    var isComplete: Bool {
        done.count >= target.count
    }

    var progress: Double {
        target.isEmpty ? 1 : Double(done.count) / Double(target.count)
    }

    /// Total number of kana the user "spent" so far (for accuracy stats).
    /// Each commit and each rejected wrong input increments this implicitly via correct/wrong tracking.
    /// (Caller is responsible for tallying based on InputResult cases.)
    @discardableResult
    mutating func ingest(_ kana: Character) -> InputResult {
        guard let expected = expectedNext else { return .complete }

        // Abandon any prior pending (lenient: not counted as wrong here — the new input determines correctness).
        pending = nil

        if kana == expected {
            done.append(kana)
            return isComplete ? .complete : .correct
        }

        if let cycle = KanaModifier.cycle(containing: kana), cycle.contains(expected) {
            pending = kana
            return .pending
        }

        return .wrong
    }

    @discardableResult
    mutating func applyModifier() -> InputResult {
        guard let expected = expectedNext else { return .complete }
        guard let p = pending else { return .ignored }

        let next = KanaModifier.cycleNext(p)
        if next == expected {
            done.append(next)
            pending = nil
            return isComplete ? .complete : .correct
        }
        pending = next
        return .pending
    }

    mutating func reset() {
        done = ""
        pending = nil
    }
}
