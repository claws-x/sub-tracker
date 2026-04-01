//
//  Models.swift
//  SubTracker
//
//  Created by AI Agent on 2026-03-27.
//

import Foundation
import CoreData

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
        switch billingCycle {
        case "weekly": return price * 4
        case "monthly": return price
        case "yearly": return price / 12
        default: return price
        }
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

/// 计费周期枚举
enum BillingCycle: String, CaseIterable, Identifiable {
    case weekly = "每周"
    case monthly = "每月"
    case yearly = "每年"
    
    var id: String { self.rawValue }
}
