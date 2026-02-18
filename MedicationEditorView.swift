import SwiftUI

/// Editor view for adding or editing a medication
/// Features: Doctor dropdown from saved doctors, Calendar sync option
struct MedicationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = MedsEquipmentStore.shared
    @StateObject private var doctorStore = DoctorStore.shared
    
    let medication: MedsEquipmentEntity?
    
    // Basic Info
    @State private var name = ""
    @State private var dosage = ""
    @State private var time = ""
    @State private var nextDate = Date()
    @State private var hasNextDate = false
    
    // Additional Details
    @State private var otherNames = ""
    @State private var specialInstructions = ""
    @State private var bottleDescription = ""
    @State private var sideEffects = ""
    
    // Doctor Info - NEW: Dropdown from saved doctors
    @State private var selectedDoctorId: UUID? = nil
    @State private var manualDoctorName = ""
    @State private var useManualDoctor = false
    @State private var reasonPrescribed = ""
    
    // Notes
    @State private var notes = ""
    
    // Calendar Sync - NEW
    @State private var syncToCalendar = true
    
    // Reminders
    @State private var reminder2Weeks = false
    @State private var reminder1Week = false
    @State private var reminder5Days = false
    @State private var reminder3Days = false
    @State private var reminder1Day = false
    @State private var reminderDayOf = false
    
    private var isEditing: Bool { medication != nil }
    
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
                    TextField("Medication Name *", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Dosage (e.g., 10mg, 2 tablets)", text: $dosage)
                    
                    TextField("Time to Take (e.g., 8:00 AM, Twice daily)", text: $time)
                    
                    Toggle("Set Refill Date", isOn: $hasNextDate)
                    
                    if hasNextDate {
                        DatePicker("Next Refill Date", selection: $nextDate, displayedComponents: .date)
                    }
                }
                
                // MARK: - Calendar Sync (NEW)
                Section {
                    Toggle(isOn: $syncToCalendar) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Add to Calendar")
                                Text("Creates a calendar event for the refill date")
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
                } footer: {
                    if syncToCalendar && hasNextDate {
                        Text("A calendar event will be created for \(nextDate.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
                
                // MARK: - Doctor Information (NEW: Dropdown)
                Section("Prescribing Doctor") {
                    if !doctorStore.doctors.isEmpty {
                        Toggle("Enter doctor manually", isOn: $useManualDoctor)
                        
                        if useManualDoctor {
                            TextField("Doctor Name", text: $manualDoctorName)
                                .textInputAutocapitalization(.words)
                        } else {
                            Picker("Select Doctor", selection: $selectedDoctorId) {
                                Text("None").tag(nil as UUID?)
                                ForEach(doctorStore.doctors, id: \.id) { doctor in
                                    HStack {
                                        Text(doctor.name ?? "Unknown")
                                        if let specialty = doctor.specialty, !specialty.isEmpty {
                                            Text("(\(specialty))")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .tag(doctor.id as UUID?)
                                }
                            }
                            
                            if let doctor = selectedDoctor {
                                // Show doctor details
                                if let specialty = doctor.specialty, !specialty.isEmpty {
                                    LabeledContent("Specialty", value: specialty)
                                }
                                if let phone = doctor.phone, !phone.isEmpty {
                                    LabeledContent("Phone", value: phone)
                                }
                            }
                        }
                    } else {
                        TextField("Doctor Name", text: $manualDoctorName)
                            .textInputAutocapitalization(.words)
                        
                        Text("Tip: Add doctors in Doctor Info to select from a list")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    TextField("Reason Prescribed", text: $reasonPrescribed, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // MARK: - Additional Details
                Section("Additional Details") {
                    TextField("Other Names / Generic Names", text: $otherNames)
                    
                    TextField("Special Instructions", text: $specialInstructions, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Bottle Description", text: $bottleDescription)
                    
                    TextField("Side Effects", text: $sideEffects, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // MARK: - Notes
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                // MARK: - Reminders
                Section("Refill Reminders") {
                    Toggle("2 Weeks Before", isOn: $reminder2Weeks)
                    Toggle("1 Week Before", isOn: $reminder1Week)
                    Toggle("5 Days Before", isOn: $reminder5Days)
                    Toggle("3 Days Before", isOn: $reminder3Days)
                    Toggle("1 Day Before", isOn: $reminder1Day)
                    Toggle("Day Of", isOn: $reminderDayOf)
                }
                
                // MARK: - Delete Button (Edit Mode Only)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let med = medication {
                                store.delete(med)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Medication", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Medication" : "New Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    // MARK: - Load Existing Data
    
    private func loadExistingData() {
        guard let med = medication else { return }
        
        name = med.name ?? ""
        dosage = med.dosage ?? ""
        time = med.time ?? ""
        
        if let date = med.nextDate {
            nextDate = date
            hasNextDate = true
        }
        
        otherNames = med.otherNames ?? ""
        specialInstructions = med.specialInstructions ?? ""
        bottleDescription = med.bottleDescription ?? ""
        sideEffects = med.sideEffects ?? ""
        
        // Load doctor
        if let doctorId = med.doctorId {
            selectedDoctorId = doctorId
            useManualDoctor = false
        } else if let doctorName = med.prescribingDoctor {
            manualDoctorName = doctorName
            useManualDoctor = true
        }
        
        reasonPrescribed = med.reasonPrescribed ?? ""
        notes = med.notes ?? ""
        syncToCalendar = med.syncToCalendar
        
        reminder2Weeks = med.reminder2Weeks
        reminder1Week = med.reminder1Week
        reminder5Days = med.reminder5Days
        reminder3Days = med.reminder3Days
        reminder1Day = med.reminder1Day
        reminderDayOf = med.reminderDayOf
    }
    
    // MARK: - Save Item
    
    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let med = medication {
            // Update existing
            med.name = trimmedName
            med.dosage = dosage.isEmpty ? nil : dosage
            med.time = time.isEmpty ? nil : time
            med.nextDate = hasNextDate ? nextDate : nil
            med.otherNames = otherNames.isEmpty ? nil : otherNames
            med.specialInstructions = specialInstructions.isEmpty ? nil : specialInstructions
            med.bottleDescription = bottleDescription.isEmpty ? nil : bottleDescription
            med.sideEffects = sideEffects.isEmpty ? nil : sideEffects
            med.prescribingDoctor = prescribingDoctorName
            med.doctorId = useManualDoctor ? nil : selectedDoctorId
            med.reasonPrescribed = reasonPrescribed.isEmpty ? nil : reasonPrescribed
            med.notes = notes.isEmpty ? nil : notes
            med.syncToCalendar = syncToCalendar
            med.reminder2Weeks = reminder2Weeks
            med.reminder1Week = reminder1Week
            med.reminder5Days = reminder5Days
            med.reminder3Days = reminder3Days
            med.reminder1Day = reminder1Day
            med.reminderDayOf = reminderDayOf
            store.update(med)
        } else {
            // Add new
            store.addMedication(
                name: trimmedName,
                dosage: dosage.isEmpty ? nil : dosage,
                time: time.isEmpty ? nil : time,
                nextDate: hasNextDate ? nextDate : nil,
                otherNames: otherNames.isEmpty ? nil : otherNames,
                specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions,
                bottleDescription: bottleDescription.isEmpty ? nil : bottleDescription,
                sideEffects: sideEffects.isEmpty ? nil : sideEffects,
                prescribingDoctor: prescribingDoctorName,
                doctorId: useManualDoctor ? nil : selectedDoctorId,
                reasonPrescribed: reasonPrescribed.isEmpty ? nil : reasonPrescribed,
                notes: notes.isEmpty ? nil : notes,
                reminder2Weeks: reminder2Weeks,
                reminder1Week: reminder1Week,
                reminder5Days: reminder5Days,
                reminder3Days: reminder3Days,
                reminder1Day: reminder1Day,
                reminderDayOf: reminderDayOf,
                syncToCalendar: syncToCalendar && hasNextDate
            )
        }
        
        dismiss()
    }
}

// MARK: - Preview

#Preview("New Medication") {
    MedicationEditorView(medication: nil)
}
