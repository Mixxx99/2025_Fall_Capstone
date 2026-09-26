import Foundation
import CoreData
import Combine

@MainActor
final class DoctorStore: ObservableObject {
    static let shared = DoctorStore()

    @Published var doctors: [DoctorEntity] = []

    private var context: NSManagedObjectContext {
        PersistenceController.shared.viewContext
    }

    private init() {
        migrateLegacyRowsIfNeeded()
        fetch(search: nil)
    }

    // MARK: - Fetch

    /// All fetches are implicitly scoped to the current user.
    func fetch(search: String?, specialty: String? = nil) {
        let req = NSFetchRequest<DoctorEntity>(entityName: "DoctorEntity")
        var preds: [NSPredicate] = [
            NSPredicate(format: "userId == %@", CurrentUser.id)
        ]

        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            preds.append(NSPredicate(format:
                "(name CONTAINS[cd] %@) OR (specialty CONTAINS[cd] %@) OR (phone CONTAINS[cd] %@) OR (email CONTAINS[cd] %@) OR (address CONTAINS[cd] %@)",
                q, q, q, q, q))
        }
        if let s = specialty, !s.isEmpty, s != "All" {
            preds.append(NSPredicate(format: "specialty == %@", s))
        }
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \DoctorEntity.dateAdded, ascending: false)]
        doctors = (try? context.fetch(req)) ?? []
    }

    // MARK: - CRUD
    func add(name: String, specialty: String?, phone: String?, email: String?, address: String?, notes: String?) {
        let d = DoctorEntity(context: context)
        d.id = UUID()
        d.name = name
        d.specialty = specialty
        d.phone = phone
        d.email = email
        d.address = address
        d.notes = notes
        d.dateAdded = Date()
        d.userId = CurrentUser.id
        save()
    }

    func update(_ doc: DoctorEntity,
                name: String,
                specialty: String?,
                phone: String?,
                email: String?,
                address: String?,
                notes: String?) {
        doc.name = name
        doc.specialty = specialty
        doc.phone = phone
        doc.email = email
        doc.address = address
        doc.notes = notes
        save()
    }

    func delete(_ doc: DoctorEntity) {
        context.delete(doc)
        save()
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("CoreData save error:", error)
        }
        fetch(search: nil)
    }

    // MARK: - Migration

    private func migrateLegacyRowsIfNeeded() {
        guard CurrentUser.id != CurrentUser.unknownId else { return }
        let req = NSFetchRequest<DoctorEntity>(entityName: "DoctorEntity")
        req.predicate = NSPredicate(format: "userId == nil OR userId == ''")
        if let orphans = try? context.fetch(req), !orphans.isEmpty {
            for row in orphans {
                row.userId = CurrentUser.id
            }
            try? context.save()
        }
    }
}
