import Foundation
import Combine

final class TimerStore: ObservableObject {
    @Published private(set) var events: [TimerEvent] = []
    static let shared = TimerStore()

    private let fm = FileManager.default
    private let dirURL: URL

    private init() {
        let appSupport = try! fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let bundle = Bundle.main.bundleIdentifier ?? "org.sturgeweber.foundation"
        dirURL = appSupport.appendingPathComponent(bundle).appendingPathComponent("TimerEvents", isDirectory: true)
        try? fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
        loadAll()
    }

    func loadAll() {
        var loaded: [TimerEvent] = []
        guard let urls = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil) else {
            self.events = []
            return
        }
        for u in urls where u.pathExtension == "json" {
            if let data = try? Data(contentsOf: u),
               let event = try? JSONDecoder().decode(TimerEvent.self, from: data) {
                loaded.append(event)
            }
        }
        loaded.sort { $0.createdAt > $1.createdAt }
        self.events = loaded
    }

    func upsert(_ event: TimerEvent) {
        save(event)
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
        } else {
            events.insert(event, at: 0)
        }
    }

    func delete(_ event: TimerEvent) {
        try? fm.removeItem(at: fileURL(for: event.id))
        events.removeAll { $0.id == event.id }
    }

    private func fileURL(for id: UUID) -> URL { dirURL.appendingPathComponent("\(id.uuidString).json") }

    private func save(_ event: TimerEvent) {
        do {
            let data = try JSONEncoder().encode(event)
            try data.write(to: fileURL(for: event.id), options: [.atomic, .completeFileProtection])
        } catch {
            print("TimerStore save error:", error)
        }
    }
}
