import Foundation
import CoreData

/// Single Core Data stack shared by every store in the app.
///
/// Previously each store (EventStore, DoctorStore, NoteStore, MedsEquipmentStore)
/// created its own NSPersistentContainer pointing at the same .xcdatamodel, which
/// meant writes in one store were not reliably visible to fetches in another
/// without forcing a refresh. This controller gives everyone the same viewContext.
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    private init() {
        container = NSPersistentContainer(name: "TheSturgeWeberFoundation")

        // Lightweight migration so adding optional attributes (like userId) to
        // existing entities doesn't crash returning users on their next launch.
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                // In production we don't want to silently lose data. Log it loudly.
                assertionFailure("CoreData load failed: \(error)")
                print("CoreData load failed:", error)
            }
        }

        // Merge changes automatically if we ever use background contexts later.
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Save the view context if there are pending changes. Safe to call frequently.
    @discardableResult
    func saveIfNeeded() -> Bool {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return true }
        do {
            try ctx.save()
            return true
        } catch {
            print("CoreData save error:", error)
            return false
        }
    }
}
