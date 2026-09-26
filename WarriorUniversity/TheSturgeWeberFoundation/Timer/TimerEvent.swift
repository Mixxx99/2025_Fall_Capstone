import Foundation

struct TimerEvent: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var userId: String = "-1"
    var createdAt: Date = Date()
    var eventName: String = ""
    var notes: String = ""
    var actionLog: [String] = []
    var intervals: [TimerIntervalMs] = []

    var totalActiveMs: Int64 {
        intervals.reduce(0) { acc, pair in
            let end = pair.end ?? Int64(Date().timeIntervalSince1970 * 1000)
            return acc + max(0, end - pair.start)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, userId, createdAt, eventName, notes, actionLog, intervals
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decodeIfPresent(UUID.self,  forKey: .id)        ?? UUID()
        userId    = try c.decodeIfPresent(String.self,forKey: .userId)    ?? "-1"
        createdAt = try c.decodeIfPresent(Date.self,  forKey: .createdAt) ?? Date()
        eventName = try c.decodeIfPresent(String.self,forKey: .eventName) ?? ""
        notes     = try c.decodeIfPresent(String.self,forKey: .notes)     ?? ""
        actionLog = try c.decodeIfPresent([String].self, forKey: .actionLog) ?? []

        let pairs = try c.decodeIfPresent([[Int64?]].self, forKey: .intervals) ?? []
        intervals = pairs.map { arr in
            let startVal: Int64 = (arr.first ?? Int64(0)) ?? Int64(0)
            let endVal: Int64?  = (arr.count > 1) ? arr[1] : nil
            return (start: startVal, end: endVal)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(userId,    forKey: .userId)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(eventName, forKey: .eventName)
        try c.encode(notes,     forKey: .notes)
        try c.encode(actionLog, forKey: .actionLog)

        let pairs: [[Int64?]] = intervals.map { [$0.start, $0.end] }
        try c.encode(pairs, forKey: .intervals)
    }

    // MARK: - Equatable (manual, since Codable is custom)
    static func == (lhs: TimerEvent, rhs: TimerEvent) -> Bool {
        guard lhs.id == rhs.id,
              lhs.userId == rhs.userId,
              lhs.createdAt == rhs.createdAt,
              lhs.eventName == rhs.eventName,
              lhs.notes == rhs.notes,
              lhs.actionLog == rhs.actionLog,
              lhs.intervals.count == rhs.intervals.count else { return false }

        for (a, b) in zip(lhs.intervals, rhs.intervals) {
            if a.start != b.start || a.end != b.end { return false }
        }
        return true
    }
}
