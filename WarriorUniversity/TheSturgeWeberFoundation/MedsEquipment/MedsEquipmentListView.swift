import SwiftUI

/// Main hub for Meds & Equipment tracking with three sections
struct MedsEquipmentListView: View {
    @StateObject private var store = MedsEquipmentStore.shared
    
    @State private var selectedTab: MedsEquipmentType = .medication
    @State private var search = ""
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab selector
                Picker("Category", selection: $selectedTab) {
                    ForEach(MedsEquipmentType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search \(selectedTab.rawValue.lowercased())…", text: $search)
                        .textInputAutocapitalization(.never)
                    if !search.isEmpty {
                        Button { search = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.15), lineWidth: 1))
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Content based on selected tab
                switch selectedTab {
                case .medication:
                    medicationsList
                case .equipment:
                    equipmentList
                case .supplies:
                    suppliesList
                }
            }
        }
        .navigationTitle("Meds & Equipment")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.swfGreen, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(.white)
                .accessibilityLabel("Add \(selectedTab.rawValue)")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            switch selectedTab {
            case .medication:
                MedicationEditorView(medication: nil)
            case .equipment:
                EquipmentEditorView(equipment: nil)
            case .supplies:
                SupplyEditorView(supply: nil)
            }
        }
        .onChange(of: search) { _, newValue in
            switch selectedTab {
            case .medication:
                store.fetchMedications(search: newValue)
            case .equipment:
                store.fetchEquipment(search: newValue)
            case .supplies:
                store.fetchSupplies(search: newValue)
            }
        }
        .onChange(of: selectedTab) { _, _ in
            search = ""
            store.fetchAll()
        }
    }
    
    // MARK: - Medications List
    
    private var medicationsList: some View {
        Group {
            if store.medications.isEmpty {
                emptyState(for: .medication)
            } else {
                List {
                    ForEach(store.medications, id: \.id) { med in
                        MedicationRowView(medication: med)
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            store.delete(store.medications[idx])
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Equipment List
    
    private var equipmentList: some View {
        Group {
            if store.equipment.isEmpty {
                emptyState(for: .equipment)
            } else {
                List {
                    ForEach(store.equipment, id: \.id) { equip in
                        EquipmentRowView(equipment: equip)
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            store.delete(store.equipment[idx])
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Supplies List
    
    private var suppliesList: some View {
        Group {
            if store.supplies.isEmpty {
                emptyState(for: .supplies)
            } else {
                List {
                    ForEach(store.supplies, id: \.id) { supply in
                        SupplyRowView(supply: supply)
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            store.delete(store.supplies[idx])
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Empty State
    
    private func emptyState(for type: MedsEquipmentType) -> some View {
        VStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: type.color) ?? .secondary)
            Text("No \(type.rawValue)")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tap + to add your first \(type.rawValue.lowercased()).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
    }
}

// MARK: - Medication Row

struct MedicationRowView: View {
    let medication: MedsEquipmentEntity
    @State private var showEditor = false
    
    var body: some View {
        Button {
            showEditor = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.swfPortWine.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "pills.fill")
                            .font(.title3)
                            .foregroundStyle(Color.swfPortWine)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name ?? "Unnamed")
                        .font(.headline)
                    
                    if let dosage = medication.dosage, !dosage.isEmpty {
                        Text("Dosage: \(dosage)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let time = medication.time, !time.isEmpty {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let nextDate = medication.nextDate {
                        Label("Refill: \(nextDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let doctor = medication.prescribingDoctor, !doctor.isEmpty {
                        Label(doctor, systemImage: "stethoscope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if medication.syncToCalendar {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                            Text("Synced to Calendar")
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.swfGreen)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditor) {
            MedicationEditorView(medication: medication)
        }
    }
}

// MARK: - Equipment Row

struct EquipmentRowView: View {
    let equipment: MedsEquipmentEntity
    @State private var showEditor = false
    
    var body: some View {
        Button {
            showEditor = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.swfGreen.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "cross.case.fill")
                            .font(.title3)
                            .foregroundStyle(Color.swfGreen)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(equipment.name ?? "Unnamed")
                        .font(.headline)
                    
                    if let serial = equipment.serialNumber, !serial.isEmpty {
                        Text("S/N: \(serial)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let provider = equipment.equipmentProvider, !provider.isEmpty {
                        Label(provider, systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let nextDate = equipment.nextDate {
                        Label("Maintenance: \(nextDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "wrench.and.screwdriver")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if equipment.syncToCalendar {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                            Text("Synced to Calendar")
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.swfGreen)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditor) {
            EquipmentEditorView(equipment: equipment)
        }
    }
}

// MARK: - Supply Row

struct SupplyRowView: View {
    let supply: MedsEquipmentEntity
    @State private var showEditor = false
    
    var body: some View {
        Button {
            showEditor = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.swfGoldenYellow.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "shippingbox.fill")
                            .font(.title3)
                            .foregroundStyle(Color.swfGoldenYellow)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(supply.name ?? "Unnamed")
                        .font(.headline)
                    
                    if let brand = supply.preferredBrand, !brand.isEmpty {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let company = supply.supplyCompany, !company.isEmpty {
                        Label(company, systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let nextDate = supply.nextDate {
                        Label("Order by: \(nextDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "cart")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let refills = supply.refillsRemaining, !refills.isEmpty {
                        Text("\(refills) refills remaining")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.swfGoldenYellow.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    if supply.syncToCalendar {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                            Text("Synced to Calendar")
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.swfGreen)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditor) {
            SupplyEditorView(supply: supply)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MedsEquipmentListView()
    }
}
