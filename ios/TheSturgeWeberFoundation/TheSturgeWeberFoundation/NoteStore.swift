import Foundation
import CoreData
import Combine   // 👈 REQUIRED for ObservableObject/@Published

@MainActor
final class NoteStore: ObservableObject {
    static let shared = NoteStore()

    private let container: NSPersistentContainer
    @Published var notes: [NoteEntity] = []

    private init() {
        // MUST match your .xcdatamodeld name
        container = NSPersistentContainer(name: "TheSturgeWeberFoundation")
        container.loadPersistentStores { _, error in
            if let error = error { print("CoreData load failed:", error) }
        }
        fetchNotes()
    }

    private var context: NSManagedObjectContext { container.viewContext }

    // MARK: - Fetch
    func fetchNotes(search: String? = nil, type: String? = nil) {
        let req = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
        var preds: [NSPredicate] = []

        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            preds.append(NSPredicate(format: "(title CONTAINS[cd] %@) OR (body CONTAINS[cd] %@)", q, q))
        }
        if let t = type, !t.isEmpty, t != "All" {
            preds.append(NSPredicate(format: "type == %@", t))
        }
        if !preds.isEmpty {
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
        }

        req.sortDescriptors = [NSSortDescriptor(keyPath: \NoteEntity.updatedAt, ascending: false)]
        notes = (try? context.fetch(req)) ?? []
    }

    // MARK: - CRUD
    func add(title: String,
             body: String?,
             userId: String?,
             attachmentPath: String?,
             type: String?) {
        let n = NoteEntity(context: context)
        n.id = UUID()
        n.title = title
        n.body = body
        n.userId = userId
        n.attachmentPath = attachmentPath
        n.type = type
        let now = Date()
        n.createdAt = now
        n.updatedAt = now
        save()
    }

    func update(_ note: NoteEntity,
                title: String,
                body: String?,
                userId: String?,
                attachmentPath: String?,
                type: String?) {
        note.title = title
        note.body = body
        note.userId = userId
        note.attachmentPath = attachmentPath
        note.type = type
        note.updatedAt = Date()
        save()
    }

    func delete(_ note: NoteEntity) {
        context.delete(note)
        save()
    }

    private func save() {
        do { try context.save() } catch { print("CoreData save error:", error) }
        fetchNotes()
    }
}
