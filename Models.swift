//
//  Models.swift
//  SubTracker
//
//  Created by AI Agent on 2026-03-27.
//

import Foundation
import CoreData

enum BillingCycleOption: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly:
            return "每周"
        case .monthly:
            return "每月"
        case .yearly:
            return "每年"
        }
    }

    var shortLabel: String {
        switch self {
        case .weekly:
            return "周"
        case .monthly:
            return "月"
        case .yearly:
            return "年"
        }
    }

    var monthlyMultiplier: Double {
        switch self {
        case .weekly:
            return 52.0 / 12.0
        case .monthly:
            return 1
        case .yearly:
            return 1.0 / 12.0
        }
    }

    static func fromPersistedValue(_ value: String) -> BillingCycleOption {
        switch value {
        case BillingCycleOption.weekly.rawValue, "每周":
            return .weekly
        case BillingCycleOption.yearly.rawValue, "每年":
            return .yearly
        default:
            return .monthly
        }
    }
}

/// 订阅服务数据模型
class Subscription: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var category: String
    @NSManaged var price: Double
    @NSManaged var currency: String
    @NSManaged var billingCycle: String // monthly, yearly, weekly
    @NSManaged var nextBillingDate: Date
    @NSManaged var notes: String?
    @NSManaged var reminderEnabled: Bool
    @NSManaged var createdAt: Date
    
    /// 月度支出（标准化）
    var monthlyPrice: Double {
        price * billingCycleOption.monthlyMultiplier
    }
    
    /// 年度支出（标准化）
    var yearlyPrice: Double {
        monthlyPrice * 12
    }
    
    /// 剩余天数
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextBillingDate).day ?? 0
    }
    
    /// 状态文本
    var statusText: String {
        if daysRemaining <= 0 {
            return "今日续费"
        } else if daysRemaining <= 1 {
            return "明天续费"
        } else if daysRemaining <= 7 {
            return "剩余 \(daysRemaining) 天"
        } else {
            return "正常"
        }
    }

    var billingCycleOption: BillingCycleOption {
        BillingCycleOption.fromPersistedValue(billingCycle)
    }

    var currencyCode: String {
        currency.isEmpty ? Locale.current.currency?.identifier ?? "USD" : currency
    }

    var priceText: String {
        price.formattedCurrency(code: currencyCode)
    }

    var monthlyPriceText: String {
        monthlyPrice.formattedCurrency(code: currencyCode)
    }

    var nextBillingDateText: String {
        nextBillingDate.formatted(date: .abbreviated, time: .omitted)
    }

    var nextBillingRelativeText: String {
        switch daysRemaining {
        case ..<0:
            return "已过期 \(abs(daysRemaining)) 天"
        case 0:
            return "今天"
        case 1:
            return "明天"
        default:
            return "\(daysRemaining) 天后"
        }
    }
}

/// 订阅类别枚举
enum SubscriptionCategory: String, CaseIterable, Identifiable {
    case video = "视频影音"
    case music = "音乐音频"
    case software = "软件工具"
    case cloud = "云服务"
    case news = "新闻资讯"
    case gaming = "游戏"
    case education = "教育学习"
    case other = "其他"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .video: return "tv"
        case .music: return "music.note"
        case .software: return "macwindow"
        case .cloud: return "cloud"
        case .news: return "newspaper"
        case .gaming: return "gamecontroller"
        case .education: return "book"
        case .other: return "bag"
        }
    }
}

extension Double {
    func formattedCurrency(code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }
}
