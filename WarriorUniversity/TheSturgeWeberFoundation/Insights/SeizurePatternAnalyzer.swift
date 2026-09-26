import Foundation

/// Prototype for AI idea #1: seizure pattern summarizer.
///
/// This file is plain Swift with no AI in it. It turns Timer history into
/// simple, checkable facts (counts, lengths, time of day). The optional AI
/// layer (InsightNarrator) only rewrites these facts into a paragraph, so the
/// numbers a caregiver sees always come from here, never from a model.

/// One logged seizure, normalized from a TimerEvent.
struct SeizureEpisode: Identifiable {
    let id: UUID
    /// When the seizure started. Taken from the first timer interval,
    /// because TimerEvent.createdAt is when the user tapped Save
    /// (for manual entries that can be days later).
    let start: Date
    let durationSeconds: Double
    let name: String

    init?(event: TimerEvent) {
        let ms = event.totalActiveMs
        guard ms > 0 else { return nil }
        id = event.id
        if let firstStart = event.intervals.map({ $0.start }).min(), firstStart > 0 {
            start = Date(timeIntervalSince1970: Double(firstStart) / 1000)
        } else {
            start = event.createdAt
        }
        durationSeconds = Double(ms) / 1000
        name = event.eventName
    }
}

enum InsightRange: String, CaseIterable, Identifiable {
    case days30 = "30 days"
    case days90 = "90 days"
    case year = "1 year"

    var id: String { rawValue }

    /// For sentences: "the last 90 days", "the last year".
    var phrase: String { self == .year ? "year" : rawValue }

    var days: Int {
        switch self {
        case .days30: return 30
        case .days90: return 90
        case .year: return 365
        }
    }
}

enum TimeOfDay: String, CaseIterable, Identifiable {
    case night = "Night (12–6 AM)"
    case morning = "Morning (6 AM–12 PM)"
    case afternoon = "Afternoon (12–6 PM)"
    case evening = "Evening (6 PM–12 AM)"

    var id: String { rawValue }

    /// Lowercase phrase for sentences, e.g. "night (12–6 AM)".
    var label: String {
        switch self {
        case .night: return "night (12–6 AM)"
        case .morning: return "morning (6 AM–12 PM)"
        case .afternoon: return "afternoon (12–6 PM)"
        case .evening: return "evening (6 PM–12 AM)"
        }
    }

    static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 0..<6: return .night
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        default: return .evening
        }
    }
}

struct TimeOfDayCount: Identifiable {
    let bucket: TimeOfDay
    let count: Int
    var id: TimeOfDay { bucket }
}

struct SeizureSummary {
    let range: InsightRange
    let episodes: [SeizureEpisode]          // inside the range, newest first
    let previousPeriodCount: Int            // same-length period just before
    let averageSeconds: Double
    let longest: SeizureEpisode?
    let fiveMinutesOrLonger: Int
    let timeOfDayCounts: [TimeOfDayCount]
    let busiestWeekday: String?
    let daysSinceLast: Int?
    let longestGapDays: Int?
    let weeklyCounts: [(weekStart: Date, count: Int)]

    var count: Int { episodes.count }
    var isEmpty: Bool { episodes.isEmpty }

    var perWeek: Double {
        Double(count) / (Double(range.days) / 7.0)
    }

    /// Short factual sentences. Shown in the app and shared with doctors,
    /// and the only input the AI narrator is allowed to see.
    var facts: [String] {
        guard !isEmpty else {
            return ["No seizures were logged in the last \(range.phrase)."]
        }
        var out: [String] = []
        out.append("\(count) seizure\(count == 1 ? "" : "s") logged in the last \(range.phrase) (about \(String(format: "%.1f", perWeek)) per week).")

        if previousPeriodCount == 0 {
            out.append("None were logged in the \(range.phrase) before that.")
        } else if previousPeriodCount == count {
            out.append("That is the same as the \(range.phrase) before (\(previousPeriodCount)).")
        } else {
            let word = count > previousPeriodCount ? "up" : "down"
            out.append("That is \(word) from \(previousPeriodCount) in the \(range.phrase) before.")
        }

        out.append("Average length: \(Self.format(seconds: averageSeconds)).")
        if let longest {
            out.append("Longest: \(Self.format(seconds: longest.durationSeconds)) on \(longest.start.formatted(date: .abbreviated, time: .shortened)).")
        }
        out.append("\(fiveMinutesOrLonger) lasted 5 minutes or longer.")

        let ranked = timeOfDayCounts.sorted { $0.count > $1.count }
        if let top = ranked.first, top.count > 0,
           ranked.count < 2 || top.count > ranked[1].count {
            let share = Int((Double(top.count) / Double(count) * 100).rounded())
            out.append("Most happened at \(top.bucket.label) (\(top.count) of \(count), \(share)%).")
        }
        if let busiestWeekday {
            out.append("The most common day was \(busiestWeekday).")
        }
        if let daysSinceLast {
            out.append(daysSinceLast == 0 ? "The most recent one was today."
                                          : "The most recent one was \(daysSinceLast) day\(daysSinceLast == 1 ? "" : "s") ago.")
        }
        if let longestGapDays, count > 1 {
            out.append("Longest stretch without a logged seizure: \(longestGapDays) day\(longestGapDays == 1 ? "" : "s").")
        }
        return out
    }

    static func format(seconds: Double) -> String {
        let s = Int(seconds.rounded())
        if s < 60 { return "\(s) sec" }
        let m = s / 60, r = s % 60
        return r == 0 ? "\(m) min" : "\(m) min \(r) sec"
    }
}

enum SeizurePatternAnalyzer {
    static func summarize(events: [TimerEvent],
                          range: InsightRange,
                          now: Date = Date(),
                          calendar: Calendar = .current) -> SeizureSummary {
        let all = events.compactMap { SeizureEpisode(event: $0 ) }
        let periodStart = calendar.date(byAdding: .day, value: -range.days, to: now) ?? now
        let previousStart = calendar.date(byAdding: .day, value: -range.days, to: periodStart) ?? periodStart

        let inRange = all
            .filter { $0.start >= periodStart && $0.start <= now }
            .sorted { $0.start > $1.start }
        let previousCount = all.filter { $0.start >= previousStart && $0.start < periodStart }.count

        let average = inRange.isEmpty ? 0 : inRange.map(\.durationSeconds).reduce(0, +) / Double(inRange.count)
        let longest = inRange.max { $0.durationSeconds < $1.durationSeconds }
        let fivePlus = inRange.filter { $0.durationSeconds >= 300 }.count

        var todCounts: [TimeOfDay: Int] = [:]
        var weekdayCounts: [Int: Int] = [:]
        for e in inRange {
            todCounts[TimeOfDay.from(hour: calendar.component(.hour, from: e.start)), default: 0] += 1
            weekdayCounts[calendar.component(.weekday, from: e.start), default: 0] += 1
        }
        let tod = TimeOfDay.allCases.map { TimeOfDayCount(bucket: $0, count: todCounts[$0] ?? 0) }

        // Only name a busiest weekday if it clearly stands out.
        var busiest: String?
        let sortedDays = weekdayCounts.sorted { $0.value > $1.value }
        if inRange.count >= 3, let first = sortedDays.first,
           first.value >= 2, (sortedDays.count < 2 || first.value > sortedDays[1].value) {
            busiest = calendar.weekdaySymbols[first.key - 1]
        }

        let daysSinceLast = inRange.first.map {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.start),
                                    to: calendar.startOfDay(for: now)).day ?? 0
        }

        var longestGap: Int?
        if inRange.count > 1 {
            let chronological = inRange.reversed().map { calendar.startOfDay(for: $0.start) }
            var gap = 0
            for (a, b) in zip(chronological, chronological.dropFirst()) {
                gap = max(gap, calendar.dateComponents([.day], from: a, to: b).day ?? 0)
            }
            longestGap = gap
        }

        return SeizureSummary(range: range,
                              episodes: inRange,
                              previousPeriodCount: previousCount,
                              averageSeconds: average,
                              longest: longest,
                              fiveMinutesOrLonger: fivePlus,
                              timeOfDayCounts: tod,
                              busiestWeekday: busiest,
                              daysSinceLast: daysSinceLast,
                              longestGapDays: longestGap,
                              weeklyCounts: weekly(inRange, from: periodStart, to: now, calendar: calendar))
    }

    private static func weekly(_ episodes: [SeizureEpisode], from start: Date, to end: Date,
                               calendar: Calendar) -> [(weekStart: Date, count: Int)] {
        guard var cursor = calendar.dateInterval(of: .weekOfYear, for: start)?.start else { return [] }
        var buckets: [(Date, Int)] = []
        while cursor <= end {
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else { break }
            let c = episodes.filter { $0.start >= cursor && $0.start < next }.count
            buckets.append((cursor, c))
            cursor = next
        }
        return buckets.map { (weekStart: $0.0, count: $0.1) }
    }
}
