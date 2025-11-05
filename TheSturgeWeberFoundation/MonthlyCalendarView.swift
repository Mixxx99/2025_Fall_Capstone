import SwiftUI

struct MonthlyCalendarView: View {
    @EnvironmentObject var store: EventStore
    @State private var currentMonth = Date()
    @State private var showAdd = false
    @State private var selectedDate = Date()
    @State private var showMonthPicker = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        ZStack {
            SWFAppBackground() // from BrandKit.swift

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

                // Weekday labels (Sun–Sat)
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
                            selectedDate = day
                            showAdd = true
                        } label: {
                            VStack(spacing: 6) {
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .frame(maxWidth: .infinity)
                                    .padding(6)
                                    .background(hasEvent(on: day) ? Color.swfPortWine.opacity(0.15) : .clear)
                                    .clipShape(Circle())
                                    .foregroundStyle(.white)

                                // dot indicator for events
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
        .sheet(isPresented: $showAdd) {
            EditEventView(selectedDate: selectedDate)
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
