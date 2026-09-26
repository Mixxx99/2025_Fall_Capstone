import SwiftUI

/// Monthly grid view.
///
/// Tap behavior:
/// - Tap on an empty day → opens the "New Event" sheet for that date
/// - Tap on a day that already has events → drills into a small sheet that
///   lists those events; from there the user can tap any one to edit, or
///   hit the "+" to add a new one on that day. This replaces the old
///   behavior where every tap created a new event no matter what was
///   already there — the root cause of the "editing opens new event" bug.
struct MonthlyCalendarView: View {
    @EnvironmentObject var store: EventStore
    @State private var currentMonth = Date()
    @State private var selectedDate = Date()
    @State private var showAddSheet = false
    @State private var showDaySheet = false
    @State private var showMonthPicker = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        ZStack {
            SWFAppBackground()

            VStack {
                // Month header with navigation
                HStack {
                    Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(currentMonth.formatted(.dateTime.month().year()))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
                }
                .padding(.horizontal)

                // Weekday labels
                HStack {
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                        Text(day.prefix(2))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 6)

                // Calendar grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(daysInMonth(currentMonth), id: \.self) { day in
                        Button {
                            handleTap(on: day)
                        } label: {
                            VStack(spacing: 6) {
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .frame(maxWidth: .infinity)
                                    .padding(6)
                                    .background(hasEvent(on: day) ? Color.swfPortWine.opacity(0.15) : .clear)
                                    .clipShape(Circle())
                                    .foregroundStyle(.white)

                                if hasEvent(on: day) {
                                    Circle()
                                        .fill(Color.swfPortWine)
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .frame(height: 48)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        // "New Event" sheet for empty days
        .sheet(isPresented: $showAddSheet) {
            EditEventView(selectedDate: selectedDate)
                .environmentObject(store)
        }
        // "Events for this day" sheet for days that already have events
        .sheet(isPresented: $showDaySheet) {
            DayEventsSheet(date: selectedDate)
                .environmentObject(store)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showMonthPicker = true
                } label: {
                    Image(systemName: "calendar")
                }
                .accessibilityLabel("Pick Month and Year")
                .foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showMonthPicker) {
            MonthYearPickerSheet(initial: currentMonth) { picked in
                currentMonth = picked
            }
        }
    }

    // MARK: - Tap routing

    private func handleTap(on day: Date) {
        selectedDate = day
        if hasEvent(on: day) {
            // Show the event list for that day so the user can edit/delete
            // an existing one instead of accidentally creating a duplicate.
            showDaySheet = true
        } else {
            // Empty day → straight to the create sheet.
            showAddSheet = true
        }
    }

    // MARK: - Helpers

    private func changeMonth(_ delta: Int) {
        currentMonth = Calendar.current.date(byAdding: .month, value: delta, to: currentMonth) ?? currentMonth
    }

    private func hasEvent(on date: Date) -> Bool {
        store.events.contains { evt in
            guard let d = evt.date else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }

    private func daysInMonth(_ date: Date) -> [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: date)) else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
    }
}

// MARK: - Day Events Sheet

/// Small sheet that appears when you tap a day in the monthly grid that
/// already has events on it. Lists those events, lets you tap one to edit,
/// swipe to delete, or hit "+" to add another.
struct DayEventsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: EventStore
    let date: Date

    @State private var showAdd = false
    @State private var editingEvent: EventEntity?

    private var eventsForDay: [EventEntity] {
        store.events.filter { evt in
            guard let d = evt.date else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }

    var body: some View {
        NavigationStack {
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
                        for idx in indexSet {
                            store.deleteEvent(eventsForDay[idx])
                        }
                    }
                }
            }
            .navigationTitle(date.formatted(.dateTime.month().day().year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Event")
                }
            }
            .sheet(isPresented: $showAdd) {
                EditEventView(selectedDate: date)
                    .environmentObject(store)
            }
            .sheet(item: $editingEvent) { event in
                EditEventView(event: event)
                    .environmentObject(store)
            }
        }
    }
}

/// Shared row view for event lists. Shows title, time, tag chip, and a
/// notes preview. Kept out of DailyEventsView so both places render the
/// same way.
struct EventRow: View {
    let event: EventEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.title ?? "")
                    .font(.headline)
                Spacer()
                if let tagTitle = event.tagTitle,
                   !tagTitle.isEmpty {
                    let hex = event.tagColorHex ?? "EBB533"
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: hex) ?? .yellow)
                            .frame(width: 8, height: 8)
                        Text(tagTitle)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
                }
            }
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
