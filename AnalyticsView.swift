import SwiftUI
import Charts

/// Time range options for analytics
enum AnalyticsTimeRange: String, CaseIterable, Identifiable {
    case month = "Month"
    case year = "Year"
    
    var id: String { rawValue }
}

/// Data point for charts
struct AnalyticsDataPoint: Identifiable {
    let id = UUID()
    let xValue: Int          // Day of month (1-31) or Month (1-12)
    let count: Int           // Number of events
    let category: String     // Tag/category name
}

/// Main Analytics View
struct AnalyticsView: View {
    @StateObject private var eventStore = EventStore.shared
    @StateObject private var timerStore = TimerStore.shared
    
    // Time range selection
    @State private var timeRange: AnalyticsTimeRange = .month
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    // Tag filtering
    @State private var availableTags: [String] = []
    @State private var selectedTags: Set<String> = []
    @State private var showTagPicker = false
    
    // Chart type
    @State private var showBarChart = true
    
    // Computed chart data
    private var chartData: [AnalyticsDataPoint] {
        computeChartData()
    }
    
    // Summary statistics
    private var totalEvents: Int {
        chartData.reduce(0) { $0 + $1.count }
    }
    
    private var averagePerPeriod: Double {
        let periods = timeRange == .month ? daysInSelectedMonth : 12
        return periods > 0 ? Double(totalEvents) / Double(periods) : 0
    }
    
    private var daysInSelectedMonth: Int {
        let components = DateComponents(year: selectedYear, month: selectedMonth)
        let date = Calendar.current.date(from: components) ?? Date()
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 30
    }
    
    private let monthNames = Calendar.current.monthSymbols
    private let shortMonthNames = Calendar.current.shortMonthSymbols
    
    // Colors for different tags
    private let tagColors: [Color] = [
        Color.swfPortWine, Color.swfGreen, Color.swfGoldenYellow, .blue, .purple, .orange, .pink
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Time Range Controls
                timeRangeControls
                
                // MARK: - Tag Filter
                tagFilterSection
                
                // MARK: - Summary Cards
                summaryCards
                
                // MARK: - Chart Type Toggle
                chartTypeToggle
                
                // MARK: - Chart
                chartSection
                
                // MARK: - Data Table
                dataTableSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Analytics")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.swfGreen, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            loadAvailableTags()
        }
        .sheet(isPresented: $showTagPicker) {
            TagPickerSheet(
                availableTags: availableTags,
                selectedTags: $selectedTags
            )
        }
    }
    
    // MARK: - Time Range Controls
    
    private var timeRangeControls: some View {
        VStack(spacing: 12) {
            // Time range picker
            Picker("Time Range", selection: $timeRange) {
                ForEach(AnalyticsTimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            // Month/Year selectors
            HStack(spacing: 12) {
                if timeRange == .month {
                    // Month picker
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthNames[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Year picker
                Picker("Year", selection: $selectedYear) {
                    ForEach((2020...2030), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Spacer()
                
                // Today button
                Button {
                    selectedMonth = Calendar.current.component(.month, from: Date())
                    selectedYear = Calendar.current.component(.year, from: Date())
                } label: {
                    Text("Today")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Tag Filter Section
    
    private var tagFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Filter by Tags")
                    .font(.headline)
                Spacer()
                Button {
                    showTagPicker = true
                } label: {
                    Label("Select", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.subheadline)
                }
            }
            
            if selectedTags.isEmpty {
                Text("All events (no filter)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedTags), id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption.weight(.medium))
                                Button {
                                    selectedTags.remove(tag)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(colorForTag(tag).opacity(0.2))
                            .foregroundStyle(colorForTag(tag))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Total Events",
                value: "\(totalEvents)",
                icon: "calendar",
                color: Color.swfPortWine
            )
            
            SummaryCard(
                title: timeRange == .month ? "Daily Avg" : "Monthly Avg",
                value: String(format: "%.1f", averagePerPeriod),
                icon: "chart.line.uptrend.xyaxis",
                color: Color.swfGreen
            )
            
            SummaryCard(
                title: "Categories",
                value: "\(Set(chartData.map { $0.category }).count)",
                icon: "tag",
                color: Color.swfGoldenYellow
            )
        }
    }
    
    // MARK: - Chart Type Toggle
    
    private var chartTypeToggle: some View {
        HStack {
            Text("Chart Type")
                .font(.headline)
            Spacer()
            Picker("Chart Type", selection: $showBarChart) {
                Label("Bar", systemImage: "chart.bar.fill").tag(true)
                Label("Line", systemImage: "chart.line.uptrend.xyaxis").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(timeRange == .month ? "\(monthNames[selectedMonth - 1]) \(selectedYear)" : "Year \(selectedYear)")
                .font(.headline)
            
            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No data for selected period")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
            } else {
                if showBarChart {
                    barChartView
                } else {
                    lineChartView
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Bar Chart
    
    private var barChartView: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value(timeRange == .month ? "Day" : "Month", point.xValue),
                y: .value("Count", point.count)
            )
            .foregroundStyle(by: .value("Category", point.category))
        }
        .chartForegroundStyleScale(domain: Array(Set(chartData.map { $0.category })), range: tagColors)
        .chartXAxis {
            if timeRange == .month {
                AxisMarks(values: .stride(by: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text("\(day)")
                        }
                    }
                }
            } else {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let month = value.as(Int.self), month >= 1, month <= 12 {
                            Text(shortMonthNames[month - 1])
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartLegend(position: .bottom, alignment: .center)
        .frame(height: 250)
    }
    
    // MARK: - Line Chart
    
    private var lineChartView: some View {
        Chart(chartData) { point in
            LineMark(
                x: .value(timeRange == .month ? "Day" : "Month", point.xValue),
                y: .value("Count", point.count)
            )
            .foregroundStyle(by: .value("Category", point.category))
            .symbol(by: .value("Category", point.category))
            
            PointMark(
                x: .value(timeRange == .month ? "Day" : "Month", point.xValue),
                y: .value("Count", point.count)
            )
            .foregroundStyle(by: .value("Category", point.category))
        }
        .chartForegroundStyleScale(domain: Array(Set(chartData.map { $0.category })), range: tagColors)
        .chartXAxis {
            if timeRange == .month {
                AxisMarks(values: .stride(by: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text("\(day)")
                        }
                    }
                }
            } else {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let month = value.as(Int.self), month >= 1, month <= 12 {
                            Text(shortMonthNames[month - 1])
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartLegend(position: .bottom, alignment: .center)
        .frame(height: 250)
    }
    
    // MARK: - Data Table
    
    private var dataTableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Breakdown")
                .font(.headline)
            
            if chartData.isEmpty {
                Text("No events to display")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Group by category
                let grouped = Dictionary(grouping: chartData, by: { $0.category })
                
                ForEach(grouped.keys.sorted(), id: \.self) { category in
                    let categoryData = grouped[category] ?? []
                    let total = categoryData.reduce(0) { $0 + $1.count }
                    
                    HStack {
                        Circle()
                            .fill(colorForTag(category))
                            .frame(width: 12, height: 12)
                        Text(category)
                            .font(.subheadline)
                        Spacer()
                        Text("\(total) events")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if category != grouped.keys.sorted().last {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    
    private func loadAvailableTags() {
        var tags = Set<String>()
        
        // Get tags from calendar events
        for event in eventStore.events {
            if let tag = event.tagTitle, !tag.isEmpty {
                tags.insert(tag)
            }
        }
        
        // Get event names from timer events as categories
        for timer in timerStore.events {
            if !timer.eventName.isEmpty {
                tags.insert(timer.eventName)
            } else {
                tags.insert("Seizure Timer")
            }
        }
        
        // Add default tags
        tags.insert("Seizure Timer")
        tags.insert("Medication")
        tags.insert("Equipment")
        tags.insert("Appointment")
        
        availableTags = tags.sorted()
    }
    
    private func computeChartData() -> [AnalyticsDataPoint] {
        var dataPoints: [AnalyticsDataPoint] = []
        var countsByTagAndX: [String: [Int: Int]] = [:]
        
        // Process calendar events
        for event in eventStore.events {
            guard let date = event.date else { continue }
            
            let category = event.tagTitle ?? "Other"
            
            // Filter by selected tags
            if !selectedTags.isEmpty && !selectedTags.contains(category) {
                continue
            }
            
            // Check if event fits the selected time range
            if !fitsTimeRange(date: date) {
                continue
            }
            
            let xValue = computeXValue(date: date)
            
            if countsByTagAndX[category] == nil {
                countsByTagAndX[category] = [:]
            }
            countsByTagAndX[category]![xValue, default: 0] += 1
        }
        
        // Process timer events (seizures)
        for timer in timerStore.events {
            let date = timer.createdAt
            let category = timer.eventName.isEmpty ? "Seizure Timer" : timer.eventName
            
            // Filter by selected tags
            if !selectedTags.isEmpty && !selectedTags.contains(category) {
                continue
            }
            
            // Check if event fits the selected time range
            if !fitsTimeRange(date: date) {
                continue
            }
            
            let xValue = computeXValue(date: date)
            
            if countsByTagAndX[category] == nil {
                countsByTagAndX[category] = [:]
            }
            countsByTagAndX[category]![xValue, default: 0] += 1
        }
        
        // Convert to data points
        for (tag, xCounts) in countsByTagAndX {
            for (x, count) in xCounts {
                dataPoints.append(AnalyticsDataPoint(xValue: x, count: count, category: tag))
            }
        }
        
        return dataPoints.sorted { $0.xValue < $1.xValue }
    }
    
    private func fitsTimeRange(date: Date) -> Bool {
        let calendar = Calendar.current
        let eventYear = calendar.component(.year, from: date)
        let eventMonth = calendar.component(.month, from: date)
        
        switch timeRange {
        case .month:
            return eventYear == selectedYear && eventMonth == selectedMonth
        case .year:
            return eventYear == selectedYear
        }
    }
    
    private func computeXValue(date: Date) -> Int {
        let calendar = Calendar.current
        switch timeRange {
        case .month:
            return calendar.component(.day, from: date)
        case .year:
            return calendar.component(.month, from: date)
        }
    }
    
    private func colorForTag(_ tag: String) -> Color {
        let index = abs(tag.hashValue) % tagColors.count
        return tagColors[index]
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.weight(.bold))
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Tag Picker Sheet

struct TagPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let availableTags: [String]
    @Binding var selectedTags: Set<String>
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedTags.removeAll()
                    } label: {
                        HStack {
                            Text("Show All (No Filter)")
                            Spacer()
                            if selectedTags.isEmpty {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.swfPortWine)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                Section("Select Tags to Filter") {
                    ForEach(availableTags, id: \.self) { tag in
                        Button {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        } label: {
                            HStack {
                                Text(tag)
                                Spacer()
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.swfPortWine)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Filter Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnalyticsView()
    }
}
