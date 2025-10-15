//
//  MonthYearPickerSheet.swift
//  TheSturgeWeberFoundation
//
//  Created by Anannya Reddy Gade on 10/11/25.
//

import SwiftUI

/// Reusable Month/Year picker presented as a sheet.
/// - Shows month names + a reasonable year range
/// - Calls `onSelect` with a date set to the *first day of the selected month* at 12:00
struct MonthYearPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initial: Date
    let yearRange: ClosedRange<Int>
    let onSelect: (Date) -> Void

    @State private var selectedMonth: Int = 1   // 1...12
    @State private var selectedYear: Int = 2025

    private let months = Calendar.current.monthSymbols

    init(
        initial: Date,
        yearRange: ClosedRange<Int> = {
            // default range = (currentYear - 30) ... (currentYear + 10)
            let y = Calendar.current.component(.year, from: Date())
            return (y - 30)...(y + 10)
        }(),
        onSelect: @escaping (Date) -> Void
    ) {
        self.initial = initial
        self.yearRange = yearRange
        self.onSelect = onSelect
        // _selectedMonth / _selectedYear will be set in .onAppear to avoid @State init warnings
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // Month
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { m in
                            Text(months[m-1]).tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    // Year
                    Picker("Year", selection: $selectedYear) {
                        ForEach(Array(yearRange), id: \.self) { y in
                            Text("\(y)").tag(y)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 180)

                HStack(spacing: 12) {
                    Button("Today") {
                        let today = Date()
                        selectedMonth = Calendar.current.component(.month, from: today)
                        selectedYear  = Calendar.current.component(.year, from: today)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Jump") {
                        onSelect(makeFirstOfMonth(year: selectedYear, month: selectedMonth))
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Go to Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .onAppear {
                let comps = Calendar.current.dateComponents([.year, .month], from: initial)
                selectedMonth = comps.month ?? 1
                selectedYear  = comps.year  ?? Calendar.current.component(.year, from: Date())
            }
        }
    }

    // First day of target month at noon (avoids DST edge cases)
    private func makeFirstOfMonth(year: Int, month: Int) -> Date {
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = 1
        dc.hour = 12
        return Calendar.current.date(from: dc) ?? Date()
    }
}
