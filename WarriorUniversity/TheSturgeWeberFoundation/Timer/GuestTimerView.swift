import SwiftUI
import Combine

struct GuestTimerView: View {
    @State private var isRunning = false
    @State private var hasEverRun = false
    @State private var intervals: [TimerIntervalMs] = []
    @State private var actionLog: [String] = []
    @State private var tickNow: Int64 = TimeUtils.nowMs
    private let ticker = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    private var elapsedMs: Int64 {
        let open = intervals.first { $0.end == nil }
        let running = open.map { tickNow - $0.start } ?? 0
        let closed = intervals.reduce(0) { acc, pair in
            acc + max(0, (pair.end ?? pair.start) - pair.start)
        }
        return closed + running
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Guest Timer").font(.title2.bold())
            Text(TimeUtils.msToHMS(elapsedMs))
                .font(.system(size: 56, weight: .bold, design: .rounded))
            HStack(spacing: 12) {
                Button(isRunning ? "Pause" : (hasEverRun ? "Resume" : "Start")) { toggle() }
                    .buttonStyle(.borderedProminent)
                Button("Add +1 min") { addTime(ms: 60_000) }
                    .buttonStyle(.bordered)
                    .disabled(!hasEverRun && !isRunning)
                Button("Reset") { reset() }
                    .buttonStyle(.bordered)
                    .disabled(!hasEverRun && !isRunning)
            }
            List {
                Section("Actions") {
                    if actionLog.isEmpty { Text("No actions yet").foregroundStyle(.secondary) }
                    ForEach(actionLog.indices, id: \.self) { i in Text(actionLog[i]).font(.callout) }
                }
            }
        }
        .padding()
        .onReceive(ticker) { _ in tickNow = TimeUtils.nowMs }
        .navigationTitle("Guest Timer")
    }

    private func toggle() {
        if isRunning {
            endInterval(); isRunning = false; actionLog.append("Paused at \(TimeUtils.msToHMS(elapsedMs))")
        } else {
            beginInterval(); isRunning = true; hasEverRun = true; actionLog.append(hasEverRun ? "Resumed" : "Started")
        }
    }
    private func reset() {
        isRunning = false; hasEverRun = false; intervals.removeAll(); actionLog.append("Reset")
    }
    private func addTime(ms: Int64) {
        if isRunning {
            if let idx = intervals.lastIndex(where: { $0.end == nil }) { intervals[idx].start -= ms }
        } else if hasEverRun {
            let end = TimeUtils.nowMs; intervals.append((start: end - ms, end: end))
        }
        actionLog.append("Added \(Int(ms/1000)) seconds")
    }
    private func beginInterval() { intervals.append((start: TimeUtils.nowMs, end: nil)) }
    private func endInterval() {
        if let idx = intervals.lastIndex(where: { $0.end == nil }) {
            intervals[idx].end = TimeUtils.nowMs
        }
    }
}
