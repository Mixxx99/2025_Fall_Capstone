import SwiftUI

struct DailyEventsView: View {
    @EnvironmentObject var store: EventStore
    @State private var selectedDate = Date()
    @State private var showAdd = false

    private var eventsForDay: [EventEntity] {
        store.events.filter { evt in
            guard let d = evt.date else { return false }
            return Calendar.current.isDate(d, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        ZStack {
            SWFAppBackground()

            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(.horizontal)

                List {
                    ForEach(eventsForDay) { event in
                        NavigationLink(destination: EventDetailView(event: event)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title ?? "")
                                    .font(.headline)
                                HStack {
                                    Text(event.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                                    if let notes = event.notes, !notes.isEmpty {
                                        Text("• \(notes)").lineLimit(1)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let toDelete = eventsForDay[index]
                            store.deleteEvent(toDelete)
                        }
                    }
                }
                .environment(\.editMode, .constant(.active))
            }
        }
        .navigationTitle(selectedDate.formatted(.dateTime.month().day().year()))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
                    .foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showAdd) {
            EditEventView(selectedDate: selectedDate)
                .environmentObject(store)
        }
    }
}
