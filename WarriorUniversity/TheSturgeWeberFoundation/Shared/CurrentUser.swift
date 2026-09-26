import Foundation

/// Lightweight, synchronous access to the currently-logged-in user's ID.
///
/// Every Core Data store reads this at fetch/add time so data stays scoped to
/// the right account. UserProfileStore is the source of truth for the value
/// itself — this helper just exposes it without forcing every store to import
/// UserProfileStore (which is @MainActor and would cause concurrency noise).
enum CurrentUser {
    static let userIdKey = "wu.user.currentUserId"
    static let unknownId = "__unknown__"

    /// Returns the active user's ID, or a stable sentinel ("__unknown__") if
    /// nobody is logged in. We never return nil so predicates like
    /// `userId == %@` always match correctly.
    static var id: String {
        UserDefaults.standard.string(forKey: userIdKey) ?? unknownId
    }

    /// Called once at account creation.
    static func setId(_ id: String) {
        UserDefaults.standard.set(id, forKey: userIdKey)
    }

    /// Called at account deletion. We DON'T clear this on logout — logout
    /// keeps the user around so they can log back in with their data intact.
    static func clearId() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
}
