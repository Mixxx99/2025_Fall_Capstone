import SwiftUI

struct TimerDetailView: View {
    @EnvironmentObject var timerStore: TimerStore
    @State var event: TimerEvent

    var body: some View {
        Form {
            Section("Summary") {
                TextField("Event name", text: $event.eventName)
                Text("Total: \(TimeUtils.msToHMS(event.totalActiveMs))").font(.headline)
                Text(event.createdAt.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(.secondary)
            }
            Section("Notes") {
                TextEditor(text: $event.notes).frame(minHeight: 120)
            }
            Section("Intervals") {
                if event.intervals.isEmpty {
                    Text("No intervals").foregroundStyle(.secondary)
                } else {
                    ForEach(Array(event.intervals.enumerated()), id: \.offset) { idx, pair in
                        HStack {
                            Text("#\(idx + 1)").monospaced()
                            Spacer()
                            let end = pair.end ?? TimeUtils.nowMs
                            Text("\(TimeUtils.msToHMS(end - pair.start))")
                        }
                    }
                }
            }
            Section("Actions") {
                Button("Save Changes") { timerStore.upsert(event) }
                Button(role: .destructive, action: { timerStore.delete(event) }) {
                    Text("Delete")
                }
            }
        }
        .navigationTitle(event.eventName.isEmpty ? "Timer Detail" : event.eventName)
    }
}
