import Foundation
import UserNotifications

/// Manages local push notifications for medication reminders, equipment maintenance, etc.
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error:", error)
            }
            print("Notifications \(granted ? "granted" : "denied")")
        }
    }

    func checkPermission(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Schedule Medication Reminder

    /// Schedule a reminder for a medication refill
    func scheduleMedicationReminder(
        id: String,
        medicationName: String,
        dosage: String?,
        refillDate: Date,
        hoursBefore: Int = 24
    ) {
        // Remove any existing notification for this medication
        cancelNotification(id: id)

        // Calculate trigger date
        let triggerDate = Calendar.current.date(byAdding: .hour, value: -hoursBefore, to: refillDate) ?? refillDate

        // Don't schedule if the reminder date has already passed
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = dosage != nil
            ? "Time to refill \(medicationName) (\(dosage!))"
            : "Time to refill \(medicationName)"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.userInfo = ["type": "medication", "id": id]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "med-\(id)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule medication reminder:", error)
            }
        }
    }

    // MARK: - Schedule Equipment Maintenance Reminder

    func scheduleEquipmentReminder(
        id: String,
        equipmentName: String,
        maintenanceDate: Date,
        hoursBefore: Int = 24
    ) {
        cancelNotification(id: id)

        let triggerDate = Calendar.current.date(byAdding: .hour, value: -hoursBefore, to: maintenanceDate) ?? maintenanceDate
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Equipment Maintenance"
        content.body = "Upcoming maintenance for \(equipmentName)"
        content.sound = .default
        content.categoryIdentifier = "EQUIPMENT_REMINDER"
        content.userInfo = ["type": "equipment", "id": id]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "equip-\(id)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule equipment reminder:", error)
            }
        }
    }

    // MARK: - Schedule Supply Order Reminder

    func scheduleSupplyReminder(
        id: String,
        supplyName: String,
        orderDate: Date,
        hoursBefore: Int = 24
    ) {
        cancelNotification(id: id)

        let triggerDate = Calendar.current.date(byAdding: .hour, value: -hoursBefore, to: orderDate) ?? orderDate
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Supply Order Reminder"
        content.body = "Time to reorder \(supplyName)"
        content.sound = .default
        content.categoryIdentifier = "SUPPLY_REMINDER"
        content.userInfo = ["type": "supply", "id": id]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "supply-\(id)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule supply reminder:", error)
            }
        }
    }

    // MARK: - Schedule Reminders Based on Toggle Settings

    /// Schedules multiple reminders based on toggle preferences (2 weeks, 1 week, 5 days, etc.)
    func scheduleReminderSet(
        baseId: String,
        title: String,
        bodyPrefix: String,
        targetDate: Date,
        reminder2Weeks: Bool,
        reminder1Week: Bool,
        reminder5Days: Bool,
        reminder3Days: Bool,
        reminder1Day: Bool,
        reminderDayOf: Bool
    ) {
        // Cancel all existing reminders for this item
        let ids = ["-14d", "-7d", "-5d", "-3d", "-1d", "-0d"].map { "reminder-\(baseId)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        let reminders: [(Bool, Int, String)] = [
            (reminder2Weeks, -14, "in 2 weeks"),
            (reminder1Week, -7, "in 1 week"),
            (reminder5Days, -5, "in 5 days"),
            (reminder3Days, -3, "in 3 days"),
            (reminder1Day, -1, "tomorrow"),
            (reminderDayOf, 0, "today"),
        ]

        for (enabled, dayOffset, label) in reminders {
            guard enabled else { continue }

            let triggerDate: Date
            if dayOffset == 0 {
                // Day of: schedule at 9 AM on the target date
                var components = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
                components.hour = 9
                components.minute = 0
                triggerDate = Calendar.current.date(from: components) ?? targetDate
            } else {
                guard let d = Calendar.current.date(byAdding: .day, value: dayOffset, to: targetDate) else { continue }
                var components = Calendar.current.dateComponents([.year, .month, .day], from: d)
                components.hour = 9
                components.minute = 0
                triggerDate = Calendar.current.date(from: components) ?? d
            }

            guard triggerDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = "\(bodyPrefix) is \(label)"
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let suffix: String
            switch dayOffset {
            case -14: suffix = "-14d"
            case -7: suffix = "-7d"
            case -5: suffix = "-5d"
            case -3: suffix = "-3d"
            case -1: suffix = "-1d"
            default: suffix = "-0d"
            }

            let request = UNNotificationRequest(
                identifier: "reminder-\(baseId)\(suffix)",
                content: content,
                trigger: trigger
            )
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule reminder:", error)
                }
            }
        }
    }

    // MARK: - Cancel

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "med-\(id)", "equip-\(id)", "supply-\(id)"
        ])
    }

    func cancelAllReminders(baseId: String) {
        let ids = ["-14d", "-7d", "-5d", "-3d", "-1d", "-0d"].map { "reminder-\(baseId)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Debug

    func listPending() {
        center.getPendingNotificationRequests { requests in
            print("Pending notifications: \(requests.count)")
            for r in requests {
                print("  - \(r.identifier): \(r.content.title)")
            }
        }
    }
}
