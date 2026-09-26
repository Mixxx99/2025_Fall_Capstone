import SwiftUI
import Charts

/// Prototype for AI idea #1: seizure pattern summarizer.
/// Reads the Timer history (already scoped to the logged-in user by TimerStore).
struct SeizureInsightsView: View {
    @ObservedObject private var timerStore = TimerStore.shared
    @StateObject private var narrator = InsightNarrator()
    @State private var range: InsightRange = .days90

    private var summary: SeizureSummary {
        SeizurePatternAnalyzer.summarize(events: timerStore.events, range: range)
    }

    var body: some View {
        let s = summary
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Range", selection: $range) {
                    ForEach(InsightRange.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if s.isEmpty {
                    emptyState
                } else {
                    statCards(s)
                    weeklyChart(s)
                    timeOfDay(s)
                    factsCard(s)
                    aiCard(s)
                }

                Text("Based only on seizures logged with the Timer. This is not a medical assessment. Talk with your care team about any changes you notice.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Seizure Insights")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.swfGreen, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if !s.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText(s)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .onChange(of: range) { _, _ in narrator.reset() }
        .onAppear { timerStore.reloadForCurrentUserIfNeeded() }
    }

    // MARK: - Sections

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No seizures logged in the last \(range.phrase)")
                .font(.headline)
            Text("Use the Timer during a seizure, or add one manually, and patterns will show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func statCards(_ s: SeizureSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Seizures", value: "\(s.count)",
                     detail: String(format: "%.1f per week", s.perWeek))
            StatCard(title: "vs. previous \(s.range.phrase)", value: changeText(s),
                     detail: "\(s.previousPeriodCount) before")
            StatCard(title: "Average length", value: SeizureSummary.format(seconds: s.averageSeconds),
                     detail: s.longest.map { "Longest " + SeizureSummary.format(seconds: $0.durationSeconds) } ?? "")
            StatCard(title: "5 min or longer", value: "\(s.fiveMinutesOrLonger)",
                     detail: s.daysSinceLast.map { "Last one \($0 == 0 ? "today" : "\($0)d ago")" } ?? "")
        }
    }

    private func weeklyChart(_ s: SeizureSummary) -> some View {
        card(title: "Per week") {
            Chart(Array(s.weeklyCounts.enumerated()), id: \.offset) { item in
                BarMark(
                    x: .value("Week", item.element.weekStart, unit: .weekOfYear),
                    y: .value("Seizures", item.element.count)
                )
                .foregroundStyle(Color.swfPortWine)
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 180)
        }
    }

    private func timeOfDay(_ s: SeizureSummary) -> some View {
        card(title: "Time of day") {
            VStack(spacing: 10) {
                ForEach(s.timeOfDayCounts) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.bucket.rawValue).font(.subheadline)
                            Spacer()
                            Text("\(item.count)").font(.subheadline.monospacedDigit())
                        }
                        ProgressView(value: Double(item.count), total: Double(max(s.count, 1)))
                            .tint(Color.swfGreen)
                    }
                }
            }
        }
    }

    private func factsCard(_ s: SeizureSummary) -> some View {
        card(title: "Summary") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(s.facts, id: \.self) { fact in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(fact)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private func aiCard(_ s: SeizureSummary) -> some View {
        card(title: "Written summary (Beta, on-device)") {
            if let reason = narrator.unavailableReason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                switch narrator.status {
                case .idle:
                    Button {
                        Task { await narrator.summarize(facts: s.facts) }
                    } label: {
                        Label("Write a plain-language summary", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.swfPortWine)
                case .working:
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Writing…").foregroundStyle(.secondary)
                    }
                case .done(let text):
                    VStack(alignment: .leading, spacing: 8) {
                        Text(text).font(.subheadline)
                        Text("Written by Apple's on-device model from the facts above. It may word things imperfectly, so rely on the numbers.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                case .failed(let message):
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func changeText(_ s: SeizureSummary) -> String {
        let diff = s.count - s.previousPeriodCount
        if diff == 0 { return "Same" }
        return diff > 0 ? "+\(diff)" : "\(diff)"
    }

    private func shareText(_ s: SeizureSummary) -> String {
        var lines = ["Seizure summary — last \(s.range.phrase)",
                     "Generated \(Date().formatted(date: .abbreviated, time: .omitted)) from Warrior University",
                     ""]
        lines += s.facts.map { "• \($0)" }
        lines += ["", "Recent seizures:"]
        lines += s.episodes.prefix(10).map {
            "• \($0.start.formatted(date: .abbreviated, time: .shortened)) — \(SeizureSummary.format(seconds: $0.durationSeconds))"
        }
        return lines.joined(separator: "\n")
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.swfPortWine)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack { SeizureInsightsView() }
}
