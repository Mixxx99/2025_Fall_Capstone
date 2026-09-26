import SwiftUI

struct TimerHistoryView: View {
    @EnvironmentObject var timerStore: TimerStore
    @State private var query: String = ""

    var body: some View {
        List {
            Section {
                TextField("Search by name or notes", text: $query)
            }
            Section {
                ForEach(filtered) { event in
                    NavigationLink {
                        TimerDetailView(event: event)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.eventName.isEmpty ? "Untitled Timer" : event.eventName)
                                .font(.headline)
                            Text(TimeUtils.msToHMS(event.totalActiveMs))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) { timerStore.delete(event) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Timer History")
    }

    private var filtered: [TimerEvent] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return timerStore.events }
        return timerStore.events.filter {
            $0.eventName.lowercased().contains(q) || $0.notes.lowercased().contains(q)
        }
    }
}
