import Foundation
import CoreData

/// Centralized "wipe everything belonging to this user" helper.
///
/// Called when an account is deleted. Loops every Core Data entity that
/// carries a userId column, and issues a batch delete for rows belonging
/// to the given user. TimerStore handles its own cleanup separately since
/// it stores JSON on disk, not Core Data.
///
/// Batch delete is used over per-row delete because it's dramatically
/// faster for users with months of events/notes and doesn't load objects
/// into memory.
enum DataCleanup {
    /// Every entity that should be scoped to a user. Add new ones here
    /// when the model grows.
    private static let scopedEntities = [
        "EventEntity",
        "DoctorEntity",
        "NoteEntity",
        "MedsEquipmentEntity",
    ]

    /// Delete every row across all scoped entities whose userId matches.
    static func deleteAllData(forUserId userId: String) {
        let context = PersistenceController.shared.viewContext
        for entityName in scopedEntities {
            deleteRows(entityName: entityName, userId: userId, in: context)
        }
        // Persist the deletions and refresh the context so any live fetches
        // see an empty result immediately.
        do {
            try context.save()
        } catch {
            print("DataCleanup save error:", error)
        }
        context.reset()
    }

    private static func deleteRows(entityName: String,
                                   userId: String,
                                   in context: NSManagedObjectContext) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetch.predicate = NSPredicate(format: "userId == %@", userId)

        let batch = NSBatchDeleteRequest(fetchRequest: fetch)
        batch.resultType = .resultTypeObjectIDs

        do {
            if let result = try context.execute(batch) as? NSBatchDeleteResult,
               let ids = result.result as? [NSManagedObjectID] {
                // Merge the deletions into the current context so @Published
                // arrays in stores get invalidated.
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                    into: [context]
                )
            }
        } catch {
            print("DataCleanup batch delete failed for \(entityName):", error)
        }
    }
}
