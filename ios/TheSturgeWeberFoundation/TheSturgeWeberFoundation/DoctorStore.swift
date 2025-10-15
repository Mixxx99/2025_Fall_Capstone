//
//  DoctorStore.swift
//  TheSturgeWeberFoundation
//
//  Created by Anannya Reddy Gade on 10/11/25.
//

import Foundation
import CoreData
import Combine

@MainActor
final class DoctorStore: ObservableObject {
    static let shared = DoctorStore()

    @Published var doctors: [DoctorEntity] = []

    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }

    private init() {
        // MUST match your .xcdatamodeld filename
        container = NSPersistentContainer(name: "TheSturgeWeberFoundation")
        container.loadPersistentStores { _, error in
            if let error = error { print("CoreData load failed:", error) }
        }
        fetch(search: nil)
    }

    // MARK: - Fetch
    func fetch(search: String?, specialty: String? = nil) {
        let req = NSFetchRequest<DoctorEntity>(entityName: "DoctorEntity")
        var preds: [NSPredicate] = []

        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            // search name, specialty, phone
            preds.append(NSPredicate(format: "(name CONTAINS[cd] %@) OR (specialty CONTAINS[cd] %@) OR (phone CONTAINS[cd] %@)", q, q, q))
        }
        if let s = specialty, !s.isEmpty, s != "All" {
            preds.append(NSPredicate(format: "specialty == %@", s))
        }
        if !preds.isEmpty {
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
        }

        req.sortDescriptors = [NSSortDescriptor(keyPath: \DoctorEntity.dateAdded, ascending: false)]
        doctors = (try? context.fetch(req)) ?? []
    }

    // MARK: - CRUD
    func add(name: String, specialty: String?, phone: String?, notes: String?) {
        let d = DoctorEntity(context: context)
        d.id = UUID()
        d.name = name
        d.specialty = specialty
        d.phone = phone
        d.notes = notes
        d.dateAdded = Date()
        save()
    }

    func update(_ doc: DoctorEntity, name: String, specialty: String?, phone: String?, notes: String?) {
        doc.name = name
        doc.specialty = specialty
        doc.phone = phone
        doc.notes = notes
        save()
    }

    func delete(_ doc: DoctorEntity) {
        context.delete(doc)
        save()
    }

    private func save() {
        do { try context.save() } catch { print("CoreData save error:", error) }
        fetch(search: nil)
    }
}
