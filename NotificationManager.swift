//
//  NotificationManager.swift
//  SubTracker
//
//  Created by AI Agent on 2026-03-27.
//

import Foundation
import UserNotifications

enum ReminderSyncResult {
    case success
    case disabled
    case permissionDenied
    case failure(String)
}

final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorizationIfNeeded() async -> UNAuthorizationStatus {
        let currentStatus = await authorizationStatus()

        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return .denied
        }

        return await authorizationStatus()
    }

    func syncReminders(for sub: Subscription) async -> ReminderSyncResult {
        cancelReminders(for: sub)

        guard sub.reminderEnabled else {
            return .disabled
        }

        let status = await requestAuthorizationIfNeeded()
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            return .permissionDenied
        }

        do {
            let scheduleDates = reminderDates(for: sub.nextBillingDate)
            for item in scheduleDates {
                try await addReminder(for: sub, offsetDays: item.offsetDays, date: item.date)
            }
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    func cancelReminders(for sub: Subscription) {
        center.removePendingNotificationRequests(withIdentifiers: notificationIdentifiers(for: sub))
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    private func reminderDates(for billingDate: Date) -> [(offsetDays: Int, date: Date)] {
        let calendar = Calendar.current
        let reminderOffsets = [7, 3, 1]

        return reminderOffsets.compactMap { offset in
            guard let candidate = calendar.date(byAdding: .day, value: -offset, to: billingDate) else {
                return nil
            }

            let scheduledDate = calendar.date(
                bySettingHour: 9,
                minute: 0,
                second: 0,
                of: candidate
            ) ?? candidate

            guard scheduledDate > Date() else {
                return nil
            }

            return (offset, scheduledDate)
        }
    }

    private func addReminder(for sub: Subscription, offsetDays: Int, date: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = offsetDays == 1 ? "订阅明天续费" : "订阅即将续费"
        content.body = "「\(sub.name)」将在 \(offsetDays) 天后续费，费用 \(sub.priceText)。"
        content.sound = .default
        content.userInfo = ["subscriptionId": sub.id.uuidString]

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(sub.id.uuidString)_\(offsetDays)days",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    private func notificationIdentifiers(for sub: Subscription) -> [String] {
        [7, 3, 1].map { "\(sub.id.uuidString)_\($0)days" }
    }
}
