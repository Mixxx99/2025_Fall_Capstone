import Foundation
import CoreData
import Combine

@MainActor
final class NoteStore: ObservableObject {
    static let shared = NoteStore()

    @Published var notes: [NoteEntity] = []

    private var context: NSManagedObjectContext {
        PersistenceController.shared.viewContext
    }

    private init() {
        migrateLegacyRowsIfNeeded()
        fetchNotes()
    }

    // MARK: - Fetch

    /// All fetches are implicitly scoped to the current user.
    func fetchNotes(search: String? = nil, type: String? = nil) {
        let req = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
        var preds: [NSPredicate] = [
            NSPredicate(format: "userId == %@", CurrentUser.id)
        ]

        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            preds.append(NSPredicate(format: "(title CONTAINS[cd] %@) OR (body CONTAINS[cd] %@) OR (tagTitle CONTAINS[cd] %@)", q, q, q))
        }
        if let t = type, !t.isEmpty, t != "All" {
            preds.append(NSPredicate(format: "type == %@", t))
        }
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \NoteEntity.updatedAt, ascending: false)]
        notes = (try? context.fetch(req)) ?? []
    }

    // MARK: - CRUD
    func add(title: String,
             body: String?,
             userId: String? = nil,   // kept for signature compatibility; ignored
             attachmentPath: String?,
             type: String?,
             tagTitle: String?,
             tagColorHex: String?) {
        let n = NoteEntity(context: context)
        n.id = UUID()
        n.title = title
        n.body = body
        // Always use the active user — ignore any callers that tried to
        // pass a different one, to avoid accidental cross-account writes.
        n.userId = CurrentUser.id
        n.attachmentPath = attachmentPath
        n.type = type
        n.tagTitle = tagTitle
        n.tagColorHex = tagColorHex
        let now = Date()
        n.createdAt = now
        n.updatedAt = now
        save()
    }

    func update(_ note: NoteEntity,
                title: String,
                body: String?,
                userId: String? = nil,   // kept for signature compatibility; ignored
                attachmentPath: String?,
                type: String?,
                tagTitle: String?,
                tagColorHex: String?) {
        note.title = title
        note.body = body
        // Don't overwrite ownership on edit.
        note.attachmentPath = attachmentPath
        note.type = type
        note.tagTitle = tagTitle
        note.tagColorHex = tagColorHex
        note.updatedAt = Date()
        save()
    }

    func delete(_ note: NoteEntity) {
        context.delete(note)
        save()
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("CoreData save error:", error)
        }
        fetchNotes()
    }

    // MARK: - Migration

    private func migrateLegacyRowsIfNeeded() {
        guard CurrentUser.id != CurrentUser.unknownId else { return }
        let req = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
        req.predicate = NSPredicate(format: "userId == nil OR userId == ''")
        if let orphans = try? context.fetch(req), !orphans.isEmpty {
            for row in orphans {
                row.userId = CurrentUser.id
            }
            try? context.save()
        }
    }
}
