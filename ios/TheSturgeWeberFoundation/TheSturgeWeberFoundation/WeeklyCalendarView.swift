import SwiftUI

struct WeeklyCalendarView: View {
    @EnvironmentObject var store: EventStore
    @State private var anchorDate = Date()
    @State private var showAdd = false
    @State private var selectedDate = Date()
    @State private var showMonthPicker = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        ZStack {
            SWFAppBackground() // from BrandKit.swift

            VStack(spacing: 12) {
                // Week navigation
                HStack {
                    Button { shiftWeek(-1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(weekTitle(for: anchorDate))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button { shiftWeek(1) } label: { Image(systemName: "chevron.right") }
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

                // Week grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(daysOfWeek(containing: anchorDate), id: \.self) { day in
                        VStack(spacing: 6) {
                            Button {
                                selectedDate = day
                                showAdd = true
                            } label: {
                                VStack(spacing: 4) {
                                    Text(day.formatted(.dateTime.weekday(.abbreviated)))
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.8))

                                    Text("\(Calendar.current.component(.day, from: day))")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(width: 28, height: 28)
                                        .background(isToday(day) ? Color.swfPortWine.opacity(0.15) : .clear)
                                        .clipShape(Circle())
                                        .foregroundStyle(.white)
                                }
                            }
                            .buttonStyle(.plain)

                            // Event chips
                            VStack(spacing: 4) {
                                ForEach(events(on: day).prefix(3)) { evt in
                                    NavigationLink(destination: EventDetailView(event: evt)) {
                                        Text(evt.title ?? "")
                                            .font(.caption2)
                                            .lineLimit(1)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 4)
                                            .background(Color.swfPortWine.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }

                                let extra = max(0, events(on: day).count - 3)
                                if extra > 0 {
                                    Text("+\(extra) more")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 100)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.swfPortWine.opacity(0.12), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showAdd) {
            EditEventView(selectedDate: selectedDate).environmentObject(store)
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
            MonthYearPickerSheet(initial: anchorDate) { picked in
                anchorDate = picked
            }
        }
    }

    // MARK: - Helpers

    private func shiftWeek(_ delta: Int) {
        anchorDate = Calendar.current.date(byAdding: .weekOfYear, value: delta, to: anchorDate) ?? anchorDate
    }

    private func weekTitle(for date: Date) -> String {
        let days = daysOfWeek(containing: date)
        guard let first = days.first, let last = days.last else { return "" }
        let fmt: Date.FormatStyle = .dateTime.month(.abbreviated).day()
        if Calendar.current.component(.month, from: first) != Calendar.current.component(.month, from: last) {
            return "\(first.formatted(fmt)) – \(last.formatted(fmt))"
        } else {
            return "\(first.formatted(.dateTime.month(.abbreviated))) \(first.formatted(.dateTime.day()))–\(last.formatted(.dateTime.day()))"
        }
    }

    private func daysOfWeek(containing date: Date) -> [Date] {
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, end: date)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func events(on date: Date) -> [EventEntity] {
        store.events.filter { evt in
            guard let d = evt.date else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }
}
