import SwiftUI

/// Editor view for adding or editing medical supplies
struct SupplyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = MedsEquipmentStore.shared
    @StateObject private var doctorStore = DoctorStore.shared
    
    let supply: MedsEquipmentEntity?
    
    // Basic Info
    @State private var name = ""
    @State private var preferredBrand = ""
    @State private var alternativeBrands = ""
    @State private var sku = ""
    @State private var size = ""
    
    // Order Info
    @State private var orderQuantity = ""
    @State private var orderFrequency = ""
    @State private var refillsRemaining = ""
    
    // Supply Company
    @State private var supplyCompany = ""
    @State private var supplyCompanyPhone = ""
    @State private var supplyCompanyAddress = ""
    @State private var alternateSources = ""
    
    // Doctor Selection
    @State private var selectedDoctorId: UUID? = nil
    @State private var manualDoctorName = ""
    @State private var useManualDoctor = false
    @State private var datePrescribed = Date()
    @State private var hasDatePrescribed = false
    @State private var insuranceUsed = ""
    
    // Dates
    @State private var lastOrderDate = Date()
    @State private var hasLastOrderDate = false
    @State private var expectedDeliveryDate = Date()
    @State private var hasExpectedDeliveryDate = false
    @State private var nextOrderDate = Date()
    @State private var hasNextOrderDate = false
    @State private var expiryDate = Date()
    @State private var hasExpiryDate = false
    
    // Notes
    @State private var supplyNotes = ""
    
    // Calendar Sync
    @State private var syncToCalendar = true
    
    // Reminders
    @State private var reminder2Weeks = false
    @State private var reminder1Week = false
    @State private var reminder5Days = false
    @State private var reminder3Days = false
    @State private var reminder1Day = false
    @State private var reminderDayOf = false
    
    private var isEditing: Bool { supply != nil }
    
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
                    TextField("Supply Name *", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Preferred Brand", text: $preferredBrand)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Alternative Brands", text: $alternativeBrands)
                    
                    TextField("SKU / Product Code", text: $sku)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Size", text: $size)
                }
                
                // MARK: - Calendar Sync
                Section {
                    Toggle(isOn: $syncToCalendar) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Add to Calendar")
                                Text("Creates a calendar event for order date")
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
                
                // MARK: - Order Information
                Section("Order Information") {
                    TextField("Order Quantity", text: $orderQuantity)
                        .keyboardType(.numberPad)
                    
                    TextField("Order Frequency (e.g., Monthly)", text: $orderFrequency)
                    
                    TextField("Refills Remaining", text: $refillsRemaining)
                        .keyboardType(.numberPad)
                }
                
                // MARK: - Supply Company
                Section("Supply Company") {
                    TextField("Medical Supply Company", text: $supplyCompany)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Company Phone", text: $supplyCompanyPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    TextField("Company Address", text: $supplyCompanyAddress, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Alternate Sources", text: $alternateSources, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // MARK: - Prescription Information with Doctor Dropdown
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
                
                // MARK: - Important Dates
                Section("Important Dates") {
                    Toggle("Last Order Date", isOn: $hasLastOrderDate)
                    if hasLastOrderDate {
                        DatePicker("", selection: $lastOrderDate, displayedComponents: .date)
                    }
                    
                    Toggle("Expected Delivery Date", isOn: $hasExpectedDeliveryDate)
                    if hasExpectedDeliveryDate {
                        DatePicker("", selection: $expectedDeliveryDate, displayedComponents: .date)
                    }
                    
                    Toggle("Next Order Date", isOn: $hasNextOrderDate)
                    if hasNextOrderDate {
                        DatePicker("", selection: $nextOrderDate, displayedComponents: .date)
                    }
                    
                    Toggle("Expiry Date", isOn: $hasExpiryDate)
                    if hasExpiryDate {
                        DatePicker("", selection: $expiryDate, displayedComponents: .date)
                    }
                }
                
                // MARK: - Notes
                Section("Notes") {
                    TextEditor(text: $supplyNotes)
                        .frame(minHeight: 100)
                }
                
                // MARK: - Reminders
                Section("Order Reminders") {
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
                            if let sup = supply {
                                store.delete(sup)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Supply", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Supply" : "New Supply")
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
        guard let sup = supply else { return }
        
        name = sup.name ?? ""
        preferredBrand = sup.preferredBrand ?? ""
        alternativeBrands = sup.alternativeBrands ?? ""
        sku = sup.sku ?? ""
        size = sup.size ?? ""
        
        orderQuantity = sup.orderQuantity ?? ""
        orderFrequency = sup.orderFrequency ?? ""
        refillsRemaining = sup.refillsRemaining ?? ""
        
        supplyCompany = sup.supplyCompany ?? ""
        supplyCompanyPhone = sup.supplyCompanyPhone ?? ""
        supplyCompanyAddress = sup.supplyCompanyAddress ?? ""
        alternateSources = sup.alternateSources ?? ""
        
        if let doctorId = sup.doctorId {
            selectedDoctorId = doctorId
            useManualDoctor = false
        } else if let doctorName = sup.prescribingDoctor {
            manualDoctorName = doctorName
            useManualDoctor = true
        }
        
        if let date = sup.datePrescribed {
            datePrescribed = date
            hasDatePrescribed = true
        }
        insuranceUsed = sup.insuranceUsed ?? ""
        
        if let date = sup.lastOrderDate {
            lastOrderDate = date
            hasLastOrderDate = true
        }
        if let date = sup.expectedDeliveryDate {
            expectedDeliveryDate = date
            hasExpectedDeliveryDate = true
        }
        if let date = sup.nextDate {
            nextOrderDate = date
            hasNextOrderDate = true
        }
        if let date = sup.expiryDate {
            expiryDate = date
            hasExpiryDate = true
        }
        
        supplyNotes = sup.supplyNotes ?? ""
        syncToCalendar = sup.syncToCalendar
        
        reminder2Weeks = sup.reminder2Weeks
        reminder1Week = sup.reminder1Week
        reminder5Days = sup.reminder5Days
        reminder3Days = sup.reminder3Days
        reminder1Day = sup.reminder1Day
        reminderDayOf = sup.reminderDayOf
    }
    
    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let sup = supply {
            sup.name = trimmedName
            sup.preferredBrand = preferredBrand.isEmpty ? nil : preferredBrand
            sup.alternativeBrands = alternativeBrands.isEmpty ? nil : alternativeBrands
            sup.sku = sku.isEmpty ? nil : sku
            sup.size = size.isEmpty ? nil : size
            sup.orderQuantity = orderQuantity.isEmpty ? nil : orderQuantity
            sup.orderFrequency = orderFrequency.isEmpty ? nil : orderFrequency
            sup.refillsRemaining = refillsRemaining.isEmpty ? nil : refillsRemaining
            sup.supplyCompany = supplyCompany.isEmpty ? nil : supplyCompany
            sup.supplyCompanyPhone = supplyCompanyPhone.isEmpty ? nil : supplyCompanyPhone
            sup.supplyCompanyAddress = supplyCompanyAddress.isEmpty ? nil : supplyCompanyAddress
            sup.alternateSources = alternateSources.isEmpty ? nil : alternateSources
            sup.prescribingDoctor = prescribingDoctorName
            sup.doctorId = useManualDoctor ? nil : selectedDoctorId
            sup.datePrescribed = hasDatePrescribed ? datePrescribed : nil
            sup.insuranceUsed = insuranceUsed.isEmpty ? nil : insuranceUsed
            sup.lastOrderDate = hasLastOrderDate ? lastOrderDate : nil
            sup.expectedDeliveryDate = hasExpectedDeliveryDate ? expectedDeliveryDate : nil
            sup.nextDate = hasNextOrderDate ? nextOrderDate : nil
            sup.expiryDate = hasExpiryDate ? expiryDate : nil
            sup.supplyNotes = supplyNotes.isEmpty ? nil : supplyNotes
            sup.syncToCalendar = syncToCalendar
            sup.reminder2Weeks = reminder2Weeks
            sup.reminder1Week = reminder1Week
            sup.reminder5Days = reminder5Days
            sup.reminder3Days = reminder3Days
            sup.reminder1Day = reminder1Day
            sup.reminderDayOf = reminderDayOf
            store.update(sup)
        } else {
            store.addSupply(
                name: trimmedName,
                preferredBrand: preferredBrand.isEmpty ? nil : preferredBrand,
                alternativeBrands: alternativeBrands.isEmpty ? nil : alternativeBrands,
                sku: sku.isEmpty ? nil : sku,
                size: size.isEmpty ? nil : size,
                orderQuantity: orderQuantity.isEmpty ? nil : orderQuantity,
                orderFrequency: orderFrequency.isEmpty ? nil : orderFrequency,
                refillsRemaining: refillsRemaining.isEmpty ? nil : refillsRemaining,
                supplyCompany: supplyCompany.isEmpty ? nil : supplyCompany,
                supplyCompanyPhone: supplyCompanyPhone.isEmpty ? nil : supplyCompanyPhone,
                supplyCompanyAddress: supplyCompanyAddress.isEmpty ? nil : supplyCompanyAddress,
                prescribingDoctor: prescribingDoctorName,
                doctorId: useManualDoctor ? nil : selectedDoctorId,
                datePrescribed: hasDatePrescribed ? datePrescribed : nil,
                insuranceUsed: insuranceUsed.isEmpty ? nil : insuranceUsed,
                lastOrderDate: hasLastOrderDate ? lastOrderDate : nil,
                expectedDeliveryDate: hasExpectedDeliveryDate ? expectedDeliveryDate : nil,
                nextDate: hasNextOrderDate ? nextOrderDate : nil,
                expiryDate: hasExpiryDate ? expiryDate : nil,
                alternateSources: alternateSources.isEmpty ? nil : alternateSources,
                supplyNotes: supplyNotes.isEmpty ? nil : supplyNotes,
                reminder2Weeks: reminder2Weeks,
                reminder1Week: reminder1Week,
                reminder5Days: reminder5Days,
                reminder3Days: reminder3Days,
                reminder1Day: reminder1Day,
                reminderDayOf: reminderDayOf,
                syncToCalendar: syncToCalendar && hasNextOrderDate
            )
        }
        dismiss()
    }
}

#Preview { SupplyEditorView(supply: nil) }
