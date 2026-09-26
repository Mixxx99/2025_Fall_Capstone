import Foundation
import CoreData
import Combine

@MainActor
final class EventStore: ObservableObject {
    static let shared = EventStore()

    @Published var events: [EventEntity] = []

    private var context: NSManagedObjectContext {
        PersistenceController.shared.viewContext
    }

    private init() {
        // One-time legacy-data cleanup: if we find any rows without a userId
        // and we have a current user, tag them to that user so long-time
        // testers don't lose their data when we flip on user scoping.
        migrateLegacyRowsIfNeeded()
        fetchEvents()
    }

    // MARK: - Queries

    /// Fetches events belonging to the current user, sorted by date.
    func fetchEvents() {
        let req = NSFetchRequest<EventEntity>(entityName: "EventEntity")
        req.predicate = NSPredicate(format: "userId == %@", CurrentUser.id)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \EventEntity.date, ascending: true)]
        events = (try? context.fetch(req)) ?? []
    }

    // MARK: - CRUD

    func addEvent(title: String,
                  date: Date,
                  notes: String?,
                  tagTitle: String? = nil,
                  tagColorHex: String? = nil) {
        let e = EventEntity(context: context)
        e.id = UUID()
        e.title = title
        e.date = date
        e.notes = notes
        e.tagTitle = tagTitle
        e.tagColorHex = tagColorHex
        e.userId = CurrentUser.id
        save()
    }

    /// Update an existing event in place. This is what was missing —
    /// previously the "Edit" view silently created a duplicate, which is
    /// why users saw new entries every time they tried to edit.
    func updateEvent(_ event: EventEntity,
                     title: String,
                     date: Date,
                     notes: String?,
                     tagTitle: String? = nil,
                     tagColorHex: String? = nil) {
        event.title = title
        event.date = date
        event.notes = notes
        event.tagTitle = tagTitle
        event.tagColorHex = tagColorHex
        save()
    }

    func deleteEvent(_ e: EventEntity) {
        context.delete(e)
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            try context.save()
        } catch {
            print("CoreData save error:", error)
        }
        fetchEvents()
    }

    // MARK: - Migration

    /// Rows created before user-scoping was added have no userId. If the
    /// active user has a real ID (i.e. someone is logged in), claim those
    /// orphan rows for them. This runs once per launch and is cheap.
    private func migrateLegacyRowsIfNeeded() {
        guard CurrentUser.id != CurrentUser.unknownId else { return }
        let req = NSFetchRequest<EventEntity>(entityName: "EventEntity")
        req.predicate = NSPredicate(format: "userId == nil OR userId == ''")
        if let orphans = try? context.fetch(req), !orphans.isEmpty {
            for row in orphans {
                row.userId = CurrentUser.id
            }
            try? context.save()
        }
    }
}
