import SwiftUI

/// Editor view for adding or editing medical equipment
struct EquipmentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = MedsEquipmentStore.shared
    @StateObject private var doctorStore = DoctorStore.shared
    
    let equipment: MedsEquipmentEntity?
    
    // Basic Info
    @State private var name = ""
    @State private var serialNumber = ""
    @State private var weight = ""
    @State private var size = ""
    
    // Doctor Selection
    @State private var selectedDoctorId: UUID? = nil
    @State private var manualDoctorName = ""
    @State private var useManualDoctor = false
    
    // Purchase/Prescription Info
    @State private var datePrescribed = Date()
    @State private var hasDatePrescribed = false
    @State private var insuranceUsed = ""
    @State private var datePurchased = Date()
    @State private var hasDatePurchased = false
    @State private var loanedOrPurchased = "Purchased"
    
    // Dates
    @State private var goodThroughDate = Date()
    @State private var hasGoodThroughDate = false
    @State private var replacementAvailableOn = Date()
    @State private var hasReplacementDate = false
    
    // Provider Info
    @State private var equipmentProvider = ""
    @State private var maintenanceProvider = ""
    @State private var lastMaintenance = Date()
    @State private var hasLastMaintenance = false
    @State private var nextMaintenanceDate = Date()
    @State private var hasNextMaintenanceDate = false
    
    // Additional Details
    @State private var sparePartsTools = ""
    @State private var associatedComponents = ""
    @State private var equipmentNotes = ""
    
    // Calendar Sync
    @State private var syncToCalendar = true
    
    // Reminders
    @State private var reminder2Weeks = false
    @State private var reminder1Week = false
    @State private var reminder5Days = false
    @State private var reminder3Days = false
    @State private var reminder1Day = false
    @State private var reminderDayOf = false
    
    private let loanOptions = ["Purchased", "Loaned", "Rented"]
    
    private var isEditing: Bool { equipment != nil }
    
    private var selectedDoctor: DoctorEntity? {
        guard let id = selectedDoctorId else { return nil }
        return doctorStore.doctors.first { $0.id == id }
    }
    
    private var prescribingDoctorName: String? {
        if useManualDoctor {
            return manualDoctorName.isEmpty ? nil : manualDoctorName
        } else {
            return selectedDoctor?.name
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Information
                Section("Basic Information") {
                    TextField("Equipment Name *", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Serial Number", text: $serialNumber)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Weight", text: $weight)
                    
                    TextField("Size / Dimensions", text: $size)
                }
                
                // MARK: - Calendar Sync
                Section {
                    Toggle(isOn: $syncToCalendar) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Add to Calendar")
                                Text("Creates a calendar event for maintenance")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundStyle(Color.swfGreen)
                        }
                    }
                } header: {
                    Text("Calendar Sync")
                }
                
                // MARK: - Prescription Info with Doctor Dropdown
                Section("Prescription Information") {
                    if !doctorStore.doctors.isEmpty {
                        Toggle("Enter doctor manually", isOn: $useManualDoctor)
                        
                        if useManualDoctor {
                            TextField("Doctor Name", text: $manualDoctorName)
                                .textInputAutocapitalization(.words)
                        } else {
                            Picker("Prescribing Doctor", selection: $selectedDoctorId) {
                                Text("None").tag(nil as UUID?)
                                ForEach(doctorStore.doctors, id: \.id) { doctor in
                                    Text(doctor.name ?? "Unknown").tag(doctor.id as UUID?)
                                }
                            }
                        }
                    } else {
                        TextField("Prescribing Doctor", text: $manualDoctorName)
                            .textInputAutocapitalization(.words)
                    }
                    
                    Toggle("Date Prescribed", isOn: $hasDatePrescribed)
                    if hasDatePrescribed {
                        DatePicker("", selection: $datePrescribed, displayedComponents: .date)
                    }
                    
                    TextField("Insurance Used", text: $insuranceUsed)
                }
                
                // MARK: - Purchase Info
                Section("Purchase Information") {
                    Picker("Acquisition Type", selection: $loanedOrPurchased) {
                        ForEach(loanOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    Toggle("Date Purchased/Acquired", isOn: $hasDatePurchased)
                    if hasDatePurchased {
                        DatePicker("", selection: $datePurchased, displayedComponents: .date)
                    }
                    
                    TextField("Equipment Provider", text: $equipmentProvider)
                        .textInputAutocapitalization(.words)
                }
                
                // MARK: - Important Dates
                Section("Important Dates") {
                    Toggle("Good Through Date", isOn: $hasGoodThroughDate)
                    if hasGoodThroughDate {
                        DatePicker("", selection: $goodThroughDate, displayedComponents: .date)
                    }
                    
                    Toggle("Replacement Available On", isOn: $hasReplacementDate)
                    if hasReplacementDate {
                        DatePicker("", selection: $replacementAvailableOn, displayedComponents: .date)
                    }
                }
                
                // MARK: - Maintenance
                Section("Maintenance") {
                    TextField("Maintenance Provider", text: $maintenanceProvider)
                        .textInputAutocapitalization(.words)
                    
                    Toggle("Last Maintenance Date", isOn: $hasLastMaintenance)
                    if hasLastMaintenance {
                        DatePicker("", selection: $lastMaintenance, displayedComponents: .date)
                    }
                    
                    Toggle("Next Maintenance Date", isOn: $hasNextMaintenanceDate)
                    if hasNextMaintenanceDate {
                        DatePicker("", selection: $nextMaintenanceDate, displayedComponents: .date)
                    }
                }
                
                // MARK: - Additional Details
                Section("Additional Details") {
                    TextField("Spare Parts / Tools Required", text: $sparePartsTools, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Associated Components", text: $associatedComponents, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // MARK: - Notes
                Section("Notes") {
                    TextEditor(text: $equipmentNotes)
                        .frame(minHeight: 100)
                }
                
                // MARK: - Reminders
                Section("Maintenance Reminders") {
                    Toggle("2 Weeks Before", isOn: $reminder2Weeks)
                    Toggle("1 Week Before", isOn: $reminder1Week)
                    Toggle("5 Days Before", isOn: $reminder5Days)
                    Toggle("3 Days Before", isOn: $reminder3Days)
                    Toggle("1 Day Before", isOn: $reminder1Day)
                    Toggle("Day Of", isOn: $reminderDayOf)
                }
                
                // MARK: - Delete Button
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let equip = equipment {
                                store.delete(equip)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Equipment", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Equipment" : "New Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveItem() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { loadExistingData() }
        }
    }
    
    private func loadExistingData() {
        guard let equip = equipment else { return }
        
        name = equip.name ?? ""
        serialNumber = equip.serialNumber ?? ""
        weight = equip.weight ?? ""
        size = equip.size ?? ""
        
        if let doctorId = equip.doctorId {
            selectedDoctorId = doctorId
            useManualDoctor = false
        } else if let doctorName = equip.prescribingDoctor {
            manualDoctorName = doctorName
            useManualDoctor = true
        }
        
        if let date = equip.datePrescribed {
            datePrescribed = date
            hasDatePrescribed = true
        }
        insuranceUsed = equip.insuranceUsed ?? ""
        
        loanedOrPurchased = equip.loanedOrPurchased ?? "Purchased"
        if let date = equip.datePurchased {
            datePurchased = date
            hasDatePurchased = true
        }
        equipmentProvider = equip.equipmentProvider ?? ""
        
        if let date = equip.goodThroughDate {
            goodThroughDate = date
            hasGoodThroughDate = true
        }
        if let date = equip.replacementAvailableOn {
            replacementAvailableOn = date
            hasReplacementDate = true
        }
        
        maintenanceProvider = equip.maintenanceProvider ?? ""
        if let date = equip.lastMaintenance {
            lastMaintenance = date
            hasLastMaintenance = true
        }
        if let date = equip.nextDate {
            nextMaintenanceDate = date
            hasNextMaintenanceDate = true
        }
        
        sparePartsTools = equip.sparePartsTools ?? ""
        associatedComponents = equip.associatedComponents ?? ""
        equipmentNotes = equip.equipmentNotes ?? ""
        syncToCalendar = equip.syncToCalendar
        
        reminder2Weeks = equip.reminder2Weeks
        reminder1Week = equip.reminder1Week
        reminder5Days = equip.reminder5Days
        reminder3Days = equip.reminder3Days
        reminder1Day = equip.reminder1Day
        reminderDayOf = equip.reminderDayOf
    }
    
    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let equip = equipment {
            equip.name = trimmedName
            equip.serialNumber = serialNumber.isEmpty ? nil : serialNumber
            equip.weight = weight.isEmpty ? nil : weight
            equip.size = size.isEmpty ? nil : size
            equip.prescribingDoctor = prescribingDoctorName
            equip.doctorId = useManualDoctor ? nil : selectedDoctorId
            equip.datePrescribed = hasDatePrescribed ? datePrescribed : nil
            equip.insuranceUsed = insuranceUsed.isEmpty ? nil : insuranceUsed
            equip.loanedOrPurchased = loanedOrPurchased
            equip.datePurchased = hasDatePurchased ? datePurchased : nil
            equip.equipmentProvider = equipmentProvider.isEmpty ? nil : equipmentProvider
            equip.goodThroughDate = hasGoodThroughDate ? goodThroughDate : nil
            equip.replacementAvailableOn = hasReplacementDate ? replacementAvailableOn : nil
            equip.maintenanceProvider = maintenanceProvider.isEmpty ? nil : maintenanceProvider
            equip.lastMaintenance = hasLastMaintenance ? lastMaintenance : nil
            equip.nextDate = hasNextMaintenanceDate ? nextMaintenanceDate : nil
            equip.sparePartsTools = sparePartsTools.isEmpty ? nil : sparePartsTools
            equip.associatedComponents = associatedComponents.isEmpty ? nil : associatedComponents
            equip.equipmentNotes = equipmentNotes.isEmpty ? nil : equipmentNotes
            equip.syncToCalendar = syncToCalendar
            equip.reminder2Weeks = reminder2Weeks
            equip.reminder1Week = reminder1Week
            equip.reminder5Days = reminder5Days
            equip.reminder3Days = reminder3Days
            equip.reminder1Day = reminder1Day
            equip.reminderDayOf = reminderDayOf
            store.update(equip)
        } else {
            store.addEquipment(
                name: trimmedName,
                serialNumber: serialNumber.isEmpty ? nil : serialNumber,
                weight: weight.isEmpty ? nil : weight,
                size: size.isEmpty ? nil : size,
                prescribingDoctor: prescribingDoctorName,
                doctorId: useManualDoctor ? nil : selectedDoctorId,
                datePrescribed: hasDatePrescribed ? datePrescribed : nil,
                insuranceUsed: insuranceUsed.isEmpty ? nil : insuranceUsed,
                datePurchased: hasDatePurchased ? datePurchased : nil,
                goodThroughDate: hasGoodThroughDate ? goodThroughDate : nil,
                replacementAvailableOn: hasReplacementDate ? replacementAvailableOn : nil,
                equipmentProvider: equipmentProvider.isEmpty ? nil : equipmentProvider,
                loanedOrPurchased: loanedOrPurchased,
                maintenanceProvider: maintenanceProvider.isEmpty ? nil : maintenanceProvider,
                lastMaintenance: hasLastMaintenance ? lastMaintenance : nil,
                nextDate: hasNextMaintenanceDate ? nextMaintenanceDate : nil,
                sparePartsTools: sparePartsTools.isEmpty ? nil : sparePartsTools,
                associatedComponents: associatedComponents.isEmpty ? nil : associatedComponents,
                equipmentNotes: equipmentNotes.isEmpty ? nil : equipmentNotes,
                reminder2Weeks: reminder2Weeks,
                reminder1Week: reminder1Week,
                reminder5Days: reminder5Days,
                reminder3Days: reminder3Days,
                reminder1Day: reminder1Day,
                reminderDayOf: reminderDayOf,
                syncToCalendar: syncToCalendar && hasNextMaintenanceDate
            )
        }
        dismiss()
    }
}

#Preview { EquipmentEditorView(equipment: nil) }
