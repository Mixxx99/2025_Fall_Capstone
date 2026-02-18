import SwiftUI

struct ManualTimerEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var timerStore: TimerStore

    @State private var eventName: String = ""
    @State private var notes: String = ""

    @State private var intervals: [ManualInterval] = [
        ManualInterval()
    ]

    var body: some View {
        Form {
            Section("Event Info") {
                TextField("Event name (e.g., Seizure)", text: $eventName)
                    .textInputAutocapitalization(.words)
                TextField("Notes (symptoms, triggers, etc.)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Manual Time Entry (Start and End)") {
                ForEach($intervals) { $int in
                    VStack(alignment: .leading, spacing: 16) {

                        // ---- START TIME ----
                        Text("Start Time").font(.headline)

                        DatePicker("Date",
                                   selection: $int.startDate,
                                   displayedComponents: .date)

                        HStack {
                            Picker("Hour", selection: $int.startHour) {
                                ForEach(0..<24) { Text(String(format: "%02d", $0)).tag($0) }
                            }
                            .frame(width: 70).clipped()

                            Picker("Min", selection: $int.startMinute) {
                                ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                            }
                            .frame(width: 70).clipped()

                            Picker("Sec", selection: $int.startSecond) {
                                ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                            }
                            .frame(width: 70).clipped()
                        }

                        // ---- END TIME ----
                        Text("End Time").font(.headline)

                        DatePicker("Date",
                                   selection: $int.endDate,
                                   displayedComponents: .date)

                        HStack {
                            Picker("Hour", selection: $int.endHour) {
                                ForEach(0..<24) { Text(String(format: "%02d", $0)).tag($0) }
                            }
                            .frame(width: 70).clipped()

                            Picker("Min", selection: $int.endMinute) {
                                ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                            }
                            .frame(width: 70).clipped()

                            Picker("Sec", selection: $int.endSecond) {
                                ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                            }
                            .frame(width: 70).clipped()
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { idx in intervals.remove(atOffsets: idx) }

                Button {
                    intervals.append(ManualInterval())
                } label: {
                    Label("Add Interval", systemImage: "plus")
                }
            }

            Section {
                Button("Save to History") {
                    saveAsTimerEvent()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Manual Timer Entry")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    // MARK: Save Logic
    private func saveAsTimerEvent() {
        var event = TimerEvent()
        event.eventName = eventName
        event.notes = notes
        event.createdAt = Date()

        event.intervals = intervals.map {
            let start = $0.toStartDateTime()
            let end = $0.toEndDateTime()

            return (
                start: Int64(start.timeIntervalSince1970 * 1000),
                end:   Int64(end.timeIntervalSince1970 * 1000)
            )
        }

        event.actionLog = intervals.enumerated().map { idx, int in
            let dur = int.toEndDateTime().timeIntervalSince(int.toStartDateTime())
            return "Interval #\(idx+1): \(TimeUtils.msToHMS(Int64(dur * 1000)))"
        }

        timerStore.upsert(event)
        dismiss()
    }
}

// MARK: Interval Model
struct ManualInterval: Identifiable {
    let id = UUID()

    // Start date/time
    var startDate: Date = Date()
    var startHour: Int = 0
    var startMinute: Int = 0
    var startSecond: Int = 0

    // End date/time
    var endDate: Date = Date()
    var endHour: Int = 0
    var endMinute: Int = 0
    var endSecond: Int = 0

    func toStartDateTime() -> Date {
        var dc = Calendar.current.dateComponents([.year, .month, .day], from: startDate)
        dc.hour = startHour
        dc.minute = startMinute
        dc.second = startSecond
        return Calendar.current.date(from: dc) ?? startDate
    }

    func toEndDateTime() -> Date {
        var dc = Calendar.current.dateComponents([.year, .month, .day], from: endDate)
        dc.hour = endHour
        dc.minute = endMinute
        dc.second = endSecond
        return Calendar.current.date(from: dc) ?? endDate
    }
}
