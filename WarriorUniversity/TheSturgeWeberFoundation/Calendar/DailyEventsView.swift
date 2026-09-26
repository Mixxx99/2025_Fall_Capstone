import SwiftUI

/// Daily view — shows events for the currently-picked date.
/// Tap a row to edit that event. Swipe to delete.
struct DailyEventsView: View {
    @EnvironmentObject var store: EventStore
    @State private var selectedDate = Date()
    @State private var showAdd = false
    @State private var editingEvent: EventEntity?

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
                    if eventsForDay.isEmpty {
                        Text("No events on this day.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(eventsForDay) { event in
                            Button {
                                editingEvent = event
                            } label: {
                                EventRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                store.deleteEvent(eventsForDay[index])
                            }
                        }
                    }
                }
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
        .sheet(item: $editingEvent) { event in
            EditEventView(event: event)
                .environmentObject(store)
        }
    }
}
