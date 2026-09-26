import Foundation
import Combine

/// Stores timer events as JSON files on disk, scoped per user.
///
/// Directory layout:
///   AppSupport/<bundleId>/TimerEvents/<userId>/<eventId>.json
///
/// Scoping by folder (rather than filtering every file) is much cheaper
/// on launch — we only enumerate files belonging to the active user.
/// Guest timers (pre-login) use the "__guest__" folder and are kept
/// around so a user can adopt them after registering if we ever want to
/// support that flow.
final class TimerStore: ObservableObject {
    @Published private(set) var events: [TimerEvent] = []
    static let shared = TimerStore()

    private let fm = FileManager.default
    private let rootDir: URL

    /// Kept track of so we can reload when the active user changes.
    private var loadedForUserId: String = ""

    private init() {
        let appSupport = try! fm.url(for: .applicationSupportDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: true)
        let bundle = Bundle.main.bundleIdentifier ?? "org.sturgeweber.foundation"
        rootDir = appSupport
            .appendingPathComponent(bundle)
            .appendingPathComponent("TimerEvents", isDirectory: true)
        try? fm.createDirectory(at: rootDir, withIntermediateDirectories: true)

        migrateLegacyFlatFilesIfNeeded()
        loadAll()
    }

    // MARK: - Paths

    private func userDir(for userId: String) -> URL {
        rootDir.appendingPathComponent(userId, isDirectory: true)
    }

    private var currentUserDir: URL {
        let dir = userDir(for: CurrentUser.id)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func fileURL(for id: UUID, userId: String) -> URL {
        userDir(for: userId).appendingPathComponent("\(id.uuidString).json")
    }

    // MARK: - Load

    /// Loads timer events belonging to the current user. Automatically
    /// refreshes if the active user has changed since the last load.
    func loadAll() {
        let uid = CurrentUser.id
        loadedForUserId = uid

        let dir = currentUserDir
        var loaded: [TimerEvent] = []

        guard let urls = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
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

    /// Public hook the app can call when the logged-in user changes
    /// (e.g. after login, register, or account deletion).
    func reloadForCurrentUserIfNeeded() {
        if loadedForUserId != CurrentUser.id {
            loadAll()
        }
    }

    // MARK: - Mutations

    func upsert(_ event: TimerEvent) {
        var tagged = event
        // Stamp with the active userId regardless of what was set on the
        // struct — avoids cross-account writes if someone passes a stale
        // value.
        tagged.userId = CurrentUser.id
        save(tagged)
        if let i = events.firstIndex(where: { $0.id == tagged.id }) {
            events[i] = tagged
        } else {
            events.insert(tagged, at: 0)
        }
    }

    func delete(_ event: TimerEvent) {
        try? fm.removeItem(at: fileURL(for: event.id, userId: CurrentUser.id))
        events.removeAll { $0.id == event.id }
    }

    /// Wipes every timer event belonging to the given user. Called from
    /// UserProfileStore.deleteAccount().
    func deleteAllEvents(forUserId userId: String) {
        let dir = userDir(for: userId)
        try? fm.removeItem(at: dir)
        if userId == CurrentUser.id {
            events = []
        }
    }

    // MARK: - Persistence

    private func save(_ event: TimerEvent) {
        do {
            let data = try JSONEncoder().encode(event)
            let url = fileURL(for: event.id, userId: CurrentUser.id)
            // Make sure the directory exists before writing.
            let dir = url.deletingLastPathComponent()
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            print("TimerStore save error:", error)
        }
    }

    // MARK: - Migration

    /// Early builds wrote timer JSON files directly into TimerEvents/ with
    /// no per-user subfolder. If we find any, relocate them into the
    /// current user's folder so they don't get orphaned.
    private func migrateLegacyFlatFilesIfNeeded() {
        guard CurrentUser.id != CurrentUser.unknownId else { return }
        guard let contents = try? fm.contentsOfDirectory(at: rootDir, includingPropertiesForKeys: [.isDirectoryKey]) else { return }

        let target = userDir(for: CurrentUser.id)
        try? fm.createDirectory(at: target, withIntermediateDirectories: true)

        for url in contents where url.pathExtension == "json" {
            let dest = target.appendingPathComponent(url.lastPathComponent)
            // Only move if destination doesn't already exist.
            if !fm.fileExists(atPath: dest.path) {
                try? fm.moveItem(at: url, to: dest)
            } else {
                try? fm.removeItem(at: url)
            }
        }
    }
}
