import Foundation
import CoreData
import Combine

/// Item type for Meds & Equipment tracking
enum MedsEquipmentType: String, CaseIterable, Identifiable {
    case medication = "Medication"
    case equipment = "Equipment"
    case supplies = "Supplies"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .medication: return "pills.fill"
        case .equipment: return "cross.case.fill"
        case .supplies: return "shippingbox.fill"
        }
    }
    
    var color: String {
        switch self {
        case .medication: return "8C1E41"  // Port Wine
        case .equipment: return "083533"   // Green
        case .supplies: return "EBB533"    // Golden Yellow
        }
    }
}

@MainActor
final class MedsEquipmentStore: ObservableObject {
    static let shared = MedsEquipmentStore()
    
    @Published var medications: [MedsEquipmentEntity] = []
    @Published var equipment: [MedsEquipmentEntity] = []
    @Published var supplies: [MedsEquipmentEntity] = []
    
    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }
    
    private init() {
        container = NSPersistentContainer(name: "TheSturgeWeberFoundation")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("CoreData load failed:", error)
            }
        }
        fetchAll()
    }
    
    // MARK: - Fetch
    
    func fetchAll() {
        fetchMedications()
        fetchEquipment()
        fetchSupplies()
    }
    
    func fetchMedications(search: String? = nil) {
        let req = NSFetchRequest<MedsEquipmentEntity>(entityName: "MedsEquipmentEntity")
        var preds: [NSPredicate] = [NSPredicate(format: "itemType == %@", MedsEquipmentType.medication.rawValue)]
        
        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            preds.append(NSPredicate(format: "(name CONTAINS[cd] %@) OR (dosage CONTAINS[cd] %@) OR (prescribingDoctor CONTAINS[cd] %@)", q, q, q))
        }
        
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MedsEquipmentEntity.name, ascending: true)]
        medications = (try? context.fetch(req)) ?? []
    }
    
    func fetchEquipment(search: String? = nil) {
        let req = NSFetchRequest<MedsEquipmentEntity>(entityName: "MedsEquipmentEntity")
        var preds: [NSPredicate] = [NSPredicate(format: "itemType == %@", MedsEquipmentType.equipment.rawValue)]
        
        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            preds.append(NSPredicate(format: "(name CONTAINS[cd] %@) OR (serialNumber CONTAINS[cd] %@) OR (equipmentProvider CONTAINS[cd] %@)", q, q, q))
        }
        
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MedsEquipmentEntity.name, ascending: true)]
        equipment = (try? context.fetch(req)) ?? []
    }
    
    func fetchSupplies(search: String? = nil) {
        let req = NSFetchRequest<MedsEquipmentEntity>(entityName: "MedsEquipmentEntity")
        var preds: [NSPredicate] = [NSPredicate(format: "itemType == %@", MedsEquipmentType.supplies.rawValue)]
        
        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            preds.append(NSPredicate(format: "(name CONTAINS[cd] %@) OR (preferredBrand CONTAINS[cd] %@) OR (supplyCompany CONTAINS[cd] %@)", q, q, q))
        }
        
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MedsEquipmentEntity.name, ascending: true)]
        supplies = (try? context.fetch(req)) ?? []
    }
    
    // MARK: - Add Medication (with Calendar Sync)
    
    func addMedication(
        name: String,
        dosage: String?,
        time: String?,
        nextDate: Date?,
        otherNames: String?,
        specialInstructions: String?,
        bottleDescription: String?,
        sideEffects: String?,
        prescribingDoctor: String?,
        doctorId: UUID?,
        reasonPrescribed: String?,
        notes: String?,
        reminder2Weeks: Bool,
        reminder1Week: Bool,
        reminder5Days: Bool,
        reminder3Days: Bool,
        reminder1Day: Bool,
        reminderDayOf: Bool,
        syncToCalendar: Bool
    ) {
        let item = MedsEquipmentEntity(context: context)
        item.id = UUID()
        item.itemType = MedsEquipmentType.medication.rawValue
        item.name = name
        item.dosage = dosage
        item.time = time
        item.nextDate = nextDate
        item.otherNames = otherNames
        item.specialInstructions = specialInstructions
        item.bottleDescription = bottleDescription
        item.sideEffects = sideEffects
        item.prescribingDoctor = prescribingDoctor
        item.doctorId = doctorId
        item.reasonPrescribed = reasonPrescribed
        item.notes = notes
        item.reminder2Weeks = reminder2Weeks
        item.reminder1Week = reminder1Week
        item.reminder5Days = reminder5Days
        item.reminder3Days = reminder3Days
        item.reminder1Day = reminder1Day
        item.reminderDayOf = reminderDayOf
        item.syncToCalendar = syncToCalendar
        item.createdAt = Date()
        item.updatedAt = Date()
        save()
        
        // Sync to calendar if enabled
        if syncToCalendar, let refillDate = nextDate {
            addCalendarEvent(
                title: "💊 Refill: \(name)",
                date: refillDate,
                notes: "Medication refill reminder for \(name)\nDosage: \(dosage ?? "N/A")\nDoctor: \(prescribingDoctor ?? "N/A")",
                tagTitle: "Medication",
                tagColor: MedsEquipmentType.medication.color
            )
        }
    }
    
    // MARK: - Add Equipment (with Calendar Sync)
    
    func addEquipment(
        name: String,
        serialNumber: String?,
        weight: String?,
        size: String?,
        prescribingDoctor: String?,
        doctorId: UUID?,
        datePrescribed: Date?,
        insuranceUsed: String?,
        datePurchased: Date?,
        goodThroughDate: Date?,
        replacementAvailableOn: Date?,
        equipmentProvider: String?,
        loanedOrPurchased: String?,
        maintenanceProvider: String?,
        lastMaintenance: Date?,
        nextDate: Date?,
        sparePartsTools: String?,
        associatedComponents: String?,
        equipmentNotes: String?,
        reminder2Weeks: Bool,
        reminder1Week: Bool,
        reminder5Days: Bool,
        reminder3Days: Bool,
        reminder1Day: Bool,
        reminderDayOf: Bool,
        syncToCalendar: Bool
    ) {
        let item = MedsEquipmentEntity(context: context)
        item.id = UUID()
        item.itemType = MedsEquipmentType.equipment.rawValue
        item.name = name
        item.serialNumber = serialNumber
        item.weight = weight
        item.size = size
        item.prescribingDoctor = prescribingDoctor
        item.doctorId = doctorId
        item.datePrescribed = datePrescribed
        item.insuranceUsed = insuranceUsed
        item.datePurchased = datePurchased
        item.goodThroughDate = goodThroughDate
        item.replacementAvailableOn = replacementAvailableOn
        item.equipmentProvider = equipmentProvider
        item.loanedOrPurchased = loanedOrPurchased
        item.maintenanceProvider = maintenanceProvider
        item.lastMaintenance = lastMaintenance
        item.nextDate = nextDate
        item.sparePartsTools = sparePartsTools
        item.associatedComponents = associatedComponents
        item.equipmentNotes = equipmentNotes
        item.reminder2Weeks = reminder2Weeks
        item.reminder1Week = reminder1Week
        item.reminder5Days = reminder5Days
        item.reminder3Days = reminder3Days
        item.reminder1Day = reminder1Day
        item.reminderDayOf = reminderDayOf
        item.syncToCalendar = syncToCalendar
        item.createdAt = Date()
        item.updatedAt = Date()
        save()
        
        // Sync to calendar if enabled
        if syncToCalendar, let maintenanceDate = nextDate {
            addCalendarEvent(
                title: "🔧 Maintenance: \(name)",
                date: maintenanceDate,
                notes: "Equipment maintenance reminder for \(name)\nS/N: \(serialNumber ?? "N/A")\nProvider: \(maintenanceProvider ?? "N/A")",
                tagTitle: "Equipment",
                tagColor: MedsEquipmentType.equipment.color
            )
        }
    }
    
    // MARK: - Add Supply (with Calendar Sync)
    
    func addSupply(
        name: String,
        preferredBrand: String?,
        alternativeBrands: String?,
        sku: String?,
        size: String?,
        orderQuantity: String?,
        orderFrequency: String?,
        refillsRemaining: String?,
        supplyCompany: String?,
        supplyCompanyPhone: String?,
        supplyCompanyAddress: String?,
        prescribingDoctor: String?,
        doctorId: UUID?,
        datePrescribed: Date?,
        insuranceUsed: String?,
        lastOrderDate: Date?,
        expectedDeliveryDate: Date?,
        nextDate: Date?,
        expiryDate: Date?,
        alternateSources: String?,
        supplyNotes: String?,
        reminder2Weeks: Bool,
        reminder1Week: Bool,
        reminder5Days: Bool,
        reminder3Days: Bool,
        reminder1Day: Bool,
        reminderDayOf: Bool,
        syncToCalendar: Bool
    ) {
        let item = MedsEquipmentEntity(context: context)
        item.id = UUID()
        item.itemType = MedsEquipmentType.supplies.rawValue
        item.name = name
        item.preferredBrand = preferredBrand
        item.alternativeBrands = alternativeBrands
        item.sku = sku
        item.size = size
        item.orderQuantity = orderQuantity
        item.orderFrequency = orderFrequency
        item.refillsRemaining = refillsRemaining
        item.supplyCompany = supplyCompany
        item.supplyCompanyPhone = supplyCompanyPhone
        item.supplyCompanyAddress = supplyCompanyAddress
        item.prescribingDoctor = prescribingDoctor
        item.doctorId = doctorId
        item.datePrescribed = datePrescribed
        item.insuranceUsed = insuranceUsed
        item.lastOrderDate = lastOrderDate
        item.expectedDeliveryDate = expectedDeliveryDate
        item.nextDate = nextDate
        item.expiryDate = expiryDate
        item.alternateSources = alternateSources
        item.supplyNotes = supplyNotes
        item.reminder2Weeks = reminder2Weeks
        item.reminder1Week = reminder1Week
        item.reminder5Days = reminder5Days
        item.reminder3Days = reminder3Days
        item.reminder1Day = reminder1Day
        item.reminderDayOf = reminderDayOf
        item.syncToCalendar = syncToCalendar
        item.createdAt = Date()
        item.updatedAt = Date()
        save()
        
        // Sync to calendar if enabled
        if syncToCalendar, let orderDate = nextDate {
            addCalendarEvent(
                title: "📦 Order: \(name)",
                date: orderDate,
                notes: "Supply order reminder for \(name)\nBrand: \(preferredBrand ?? "N/A")\nQuantity: \(orderQuantity ?? "N/A")",
                tagTitle: "Supplies",
                tagColor: MedsEquipmentType.supplies.color
            )
        }
    }
    
    // MARK: - Calendar Sync Helper
    
    private func addCalendarEvent(title: String, date: Date, notes: String, tagTitle: String, tagColor: String) {
        Task { @MainActor in
            EventStore.shared.addEvent(
                title: title,
                date: date,
                notes: notes,
                tagTitle: tagTitle,
                tagColorHex: tagColor
            )
        }
    }
    
    // MARK: - Update
    
    func update(_ item: MedsEquipmentEntity) {
        item.updatedAt = Date()
        save()
    }
    
    // MARK: - Delete
    
    func delete(_ item: MedsEquipmentEntity) {
        context.delete(item)
        save()
    }
    
    // MARK: - Save
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("CoreData save error:", error)
        }
        fetchAll()
    }
}
