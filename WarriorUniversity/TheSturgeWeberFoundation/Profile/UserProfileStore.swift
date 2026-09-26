import Foundation
import SwiftUI
import Security
import Combine

/// Manages user profile data (name, photo, preferences) and the current
/// session. Profile data goes in UserDefaults, passcodes go in the Keychain,
/// and the `currentUserId` is shared with every Core Data store through
/// `CurrentUser` so each account only sees its own events, notes, doctors,
/// meds and timer history.
///
/// Multi-account design notes:
/// - One account per device is still the primary flow, but the architecture
///   supports multiple (e.g. family members sharing an iPad) because every
///   stored record is tagged with the owner's userId.
/// - Deleting an account cascades across every store and wipes the Keychain
///   passcode for that account.
final class UserProfileStore: ObservableObject {
    static let shared = UserProfileStore()

    // MARK: - Published Properties

    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: userScopedKey(Keys.userName)) }
    }
    @Published var userEmail: String {
        didSet { UserDefaults.standard.set(userEmail, forKey: userScopedKey(Keys.userEmail)) }
    }
    @Published var profileImageData: Data? {
        didSet { UserDefaults.standard.set(profileImageData, forKey: userScopedKey(Keys.profileImage)) }
    }
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: userScopedKey(Keys.notificationsEnabled)) }
    }
    @Published var reminderHoursBefore: Int {
        didSet { UserDefaults.standard.set(reminderHoursBefore, forKey: userScopedKey(Keys.reminderHours)) }
    }
    @Published var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: Keys.isLoggedIn) }
    }

    // MARK: - Keys

    private enum Keys {
        // Per-user (namespaced with userId so a second account on the device
        // doesn't overwrite the first one's fields)
        static let userName = "wu.user.name"
        static let userEmail = "wu.user.email"
        static let profileImage = "wu.user.profileImage"
        static let notificationsEnabled = "wu.user.notificationsEnabled"
        static let reminderHours = "wu.user.reminderHours"

        // Device-wide
        static let isLoggedIn = "wu.user.isLoggedIn"
        static let hasAccount = "wu.user.hasAccount"

        // Keychain
        static let keychainService = "org.sturgeweber.warrioruniversity"
        /// Account field is derived: "wu.passcode.<userId>" so multiple
        /// accounts can each have their own passcode.
        static func keychainAccount(for userId: String) -> String {
            "wu.passcode.\(userId)"
        }
    }

    /// Scopes a base key to the currently-active user so different users'
    /// profile data doesn't collide.
    private func userScopedKey(_ base: String) -> String {
        "\(base).\(CurrentUser.id)"
    }

    // MARK: - Init

    private init() {
        let ud = UserDefaults.standard
        // Read the currently-active user first, THEN load that user's fields.
        let uid = CurrentUser.id
        let scope: (String) -> String = { "\($0).\(uid)" }

        self.userName = ud.string(forKey: scope(Keys.userName)) ?? ""
        self.userEmail = ud.string(forKey: scope(Keys.userEmail)) ?? ""
        self.profileImageData = ud.data(forKey: scope(Keys.profileImage))
        self.notificationsEnabled = ud.bool(forKey: scope(Keys.notificationsEnabled))
        self.reminderHoursBefore = ud.object(forKey: scope(Keys.reminderHours)) as? Int ?? 24
        self.isLoggedIn = ud.bool(forKey: Keys.isLoggedIn)
    }

    // MARK: - Account Management

    var hasAccount: Bool {
        UserDefaults.standard.bool(forKey: Keys.hasAccount)
    }

    /// Create a new account with name + passcode. Generates a fresh userId
    /// and tags every future record with it.
    func createAccount(name: String, email: String, passcode: String) {
        // Assign this user a stable ID and remember it for the session.
        let newId = UUID().uuidString
        CurrentUser.setId(newId)

        // Persist the profile fields under the new user's namespace.
        userName = name
        userEmail = email

        savePasscodeToKeychain(passcode, for: newId)
        UserDefaults.standard.set(true, forKey: Keys.hasAccount)
        isLoggedIn = true
    }

    /// Validate passcode for login.
    func validatePasscode(_ passcode: String) -> Bool {
        let uid = CurrentUser.id
        if let stored = loadPasscodeFromKeychain(for: uid) {
            return stored == passcode
        }
        // Migration path: old builds stored the passcode under the legacy
        // key without a userId suffix. If we find one, move it over.
        if let legacy = loadLegacyPasscodeFromKeychain() {
            if legacy == passcode {
                savePasscodeToKeychain(passcode, for: uid)
                deleteLegacyPasscodeFromKeychain()
                return true
            }
        }
        // Even older fallback: passcode saved in UserDefaults.
        if let oldPasscode = UserDefaults.standard.string(forKey: "wu.passcode"),
           oldPasscode == passcode {
            savePasscodeToKeychain(passcode, for: uid)
            UserDefaults.standard.removeObject(forKey: "wu.passcode")
            return true
        }
        return false
    }

    /// Change passcode.
    func changePasscode(oldPasscode: String, newPasscode: String) -> Bool {
        guard validatePasscode(oldPasscode) else { return false }
        savePasscodeToKeychain(newPasscode, for: CurrentUser.id)
        return true
    }

    func logout() {
        isLoggedIn = false
        // We deliberately keep CurrentUser.id intact so the user's data is
        // still there when they log back in.
    }

    /// Permanently delete this account and every piece of data associated
    /// with it. Cascades to every store.
    func deleteAccount() {
        let uid = CurrentUser.id

        // 1. Wipe all Core Data rows owned by this user.
        DataCleanup.deleteAllData(forUserId: uid)

        // 2. Wipe timer files for this user.
        TimerStore.shared.deleteAllEvents(forUserId: uid)

        // 3. Clear the profile fields in UserDefaults.
        let ud = UserDefaults.standard
        ud.removeObject(forKey: userScopedKey(Keys.userName))
        ud.removeObject(forKey: userScopedKey(Keys.userEmail))
        ud.removeObject(forKey: userScopedKey(Keys.profileImage))
        ud.removeObject(forKey: userScopedKey(Keys.notificationsEnabled))
        ud.removeObject(forKey: userScopedKey(Keys.reminderHours))

        // 4. Wipe the Keychain passcode for this account.
        deletePasscodeFromKeychain(for: uid)
        deleteLegacyPasscodeFromKeychain()  // clean old migrations too
        ud.removeObject(forKey: "wu.passcode")

        // 5. Reset the in-memory state.
        userName = ""
        userEmail = ""
        profileImageData = nil
        notificationsEnabled = false
        reminderHoursBefore = 24
        isLoggedIn = false

        // 6. Clear current user + account flag last so earlier writes still
        //    went to the right namespace.
        ud.removeObject(forKey: Keys.hasAccount)
        CurrentUser.clearId()
    }

    // MARK: - Profile Image

    var profileImage: UIImage? {
        guard let data = profileImageData else { return nil }
        return UIImage(data: data)
    }

    func setProfileImage(_ image: UIImage?) {
        profileImageData = image?.jpegData(compressionQuality: 0.7)
    }

    // MARK: - Keychain Helpers

    private func savePasscodeToKeychain(_ passcode: String, for userId: String) {
        let data = passcode.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.keychainService,
            kSecAttrAccount as String: Keys.keychainAccount(for: userId),
        ]
        SecItemDelete(query as CFDictionary)
        var newQuery = query
        newQuery[kSecValueData as String] = data
        SecItemAdd(newQuery as CFDictionary, nil)
    }

    private func loadPasscodeFromKeychain(for userId: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.keychainService,
            kSecAttrAccount as String: Keys.keychainAccount(for: userId),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deletePasscodeFromKeychain(for userId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.keychainService,
            kSecAttrAccount as String: Keys.keychainAccount(for: userId),
        ]
        SecItemDelete(query as CFDictionary)
    }

    // Legacy (pre-multi-account) helpers — kept only for migration.
    private func loadLegacyPasscodeFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.keychainService,
            kSecAttrAccount as String: "wu.passcode",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteLegacyPasscodeFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.keychainService,
            kSecAttrAccount as String: "wu.passcode",
        ]
        SecItemDelete(query as CFDictionary)
    }
}
