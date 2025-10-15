//
//  EventStore.swift
//  TheSturgeWeberFoundation
//
//  Created by Anannya Reddy Gade on 10/11/25.
//

import Foundation
import CoreData
import Combine   // required for ObservableObject/@Published

@MainActor
final class EventStore: ObservableObject {
    // Shared instance used app-wide
    static let shared = EventStore()

    @Published var events: [EventEntity] = []

    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }

    // Make init private to reinforce singleton usage
    private init() {
        // MUST match your .xcdatamodeld filename
        container = NSPersistentContainer(name: "TheSturgeWeberFoundation")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("CoreData load failed:", error)
            }
        }
        fetchEvents()
    }

    // MARK: - Queries
    func fetchEvents() {
        let req = NSFetchRequest<EventEntity>(entityName: "EventEntity")
        req.sortDescriptors = [NSSortDescriptor(keyPath: \EventEntity.date, ascending: true)]
        events = (try? context.fetch(req)) ?? []
    }

    // MARK: - CRUD
    func addEvent(title: String, date: Date, notes: String?) {
        let e = EventEntity(context: context)
        e.id = UUID()
        e.title = title
        e.date = date
        e.notes = notes
        save()
    }

    func deleteEvent(_ e: EventEntity) {
        context.delete(e)
        save()
    }

    // MARK: - Persistence
    private func save() {
        do { try context.save() } catch { print("CoreData save error:", error) }
        fetchEvents()
    }
}
