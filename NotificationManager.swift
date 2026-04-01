//
//  NotificationManager.swift
//  SubTracker
//
//  Created by AI Agent on 2026-03-27.
//

import Foundation
import UserNotifications

/// 通知管理器
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// 请求通知权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知权限请求失败：\(error.localizedDescription)")
                completion(false)
                return
            }
            completion(granted)
        }
    }
    
    /// 为订阅设置续费提醒
    func scheduleReminder(for sub: Subscription) {
        let billingDate = sub.nextBillingDate
        
        // 续费前 7 天提醒
        if let date7 = Calendar.current.date(byAdding: .day, value: -7, to: billingDate) {
            scheduleNotification(
                for: sub,
                date: date7,
                identifier: "\(sub.id.uuidString)_7days",
                title: "订阅即将续费",
                body: "「\(sub.name)」将在 7 天后续费，费用 ¥\(sub.price)"
            )
        }
        
        // 续费前 3 天提醒
        if let date3 = Calendar.current.date(byAdding: .day, value: -3, to: billingDate) {
            scheduleNotification(
                for: sub,
                date: date3,
                identifier: "\(sub.id.uuidString)_3days",
                title: "订阅即将续费",
                body: "「\(sub.name)」将在 3 天后续费，费用 ¥\(sub.price)"
            )
        }
        
        // 续费前 1 天提醒
        if let date1 = Calendar.current.date(byAdding: .day, value: -1, to: billingDate) {
            scheduleNotification(
                for: sub,
                date: date1,
                identifier: "\(sub.id.uuidString)_1day",
                title: "订阅明天续费",
                body: "「\(sub.name)」将在明天续费，费用 ¥\(sub.price)"
            )
        }
    }
    
    /// 安排单个通知
    private func scheduleNotification(for sub: Subscription,
                                      date: Date,
                                      identifier: String,
                                      title: String,
                                      body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["subscriptionId": sub.id.uuidString]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加通知失败：\(error.localizedDescription)")
            } else {
                print("已为 \(sub.name) 设置提醒：\(title)")
            }
        }
    }
    
    /// 取消某个订阅的所有提醒
    func cancelReminders(for sub: Subscription) {
        let identifiers = [
            "\(sub.id.uuidString)_7days",
            "\(sub.id.uuidString)_3days",
            "\(sub.id.uuidString)_1day"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// 取消所有提醒
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
