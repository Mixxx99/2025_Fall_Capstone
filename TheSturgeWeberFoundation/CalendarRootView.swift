import SwiftUI

struct CalendarRootView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case month = "Month"
        case week  = "Week"
        case day   = "Day"
        var id: String { rawValue }
    }

    @EnvironmentObject var store: EventStore
    @State private var tab: Tab = .month

    // For the global add button on this screen
    @State private var showAdd = false
    @State private var addDate = Date()

    var body: some View {
        ZStack {
            SWFAppBackground()

            VStack(spacing: 12) {
                // Segmented control for Month / Week / Day
                Picker("View", selection: $tab) {
                    ForEach(Tab.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Active subview
                Group {
                    switch tab {
                    case .month:
                        MonthlyCalendarView()
                    case .week:
                        WeeklyCalendarView()
                    case .day:
                        DailyEventsView() // already filters by Date() inside
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Calendar")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.swfGreen, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            // Top-right add button (always available)
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    addDate = Date()
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(.white)
                .accessibilityLabel("Add Event")
            }
        }
        .sheet(isPresented: $showAdd) {
            EditEventView(selectedDate: addDate)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CalendarRootView()
            .environmentObject(EventStore.shared) // ✅ use singleton
    }
}
