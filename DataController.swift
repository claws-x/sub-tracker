//
//  DataController.swift
//  SubTracker
//
//  Created by AI Agent on 2026-03-27.
//

import Foundation
import CoreData

/// CoreData 数据控制器
class DataController: ObservableObject {
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SubTracker")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreData 加载失败：\(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// 保存上下文
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("保存失败：\(error.localizedDescription)")
            }
        }
    }
    
    /// 创建新订阅
    func createSubscription(name: String,
                           category: String,
                           price: Double,
                           currency: String = "CNY",
                           billingCycle: String,
                           nextBillingDate: Date,
                           notes: String? = nil) -> Subscription {
        let sub = Subscription(context: container.viewContext)
        sub.id = UUID()
        sub.name = name
        sub.category = category
        sub.price = price
        sub.currency = currency
        sub.billingCycle = billingCycle
        sub.nextBillingDate = nextBillingDate
        sub.notes = notes
        sub.reminderEnabled = true
        sub.createdAt = Date()
        
        save()
        return sub
    }
    
    /// 获取所有订阅（按到期日排序）
    func fetchSubscriptions() -> [Subscription] {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest() as! NSFetchRequest<Subscription>
        request.sortDescriptors = [NSSortDescriptor(key: "nextBillingDate", ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("获取数据失败：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 删除订阅
    func deleteSubscription(_ sub: Subscription) {
        container.viewContext.delete(sub)
        save()
    }
    
    /// 月度总支出
    func totalMonthlyExpense() -> Double {
        let subs = fetchSubscriptions()
        return subs.reduce(0) { $0 + $1.monthlyPrice }
    }
    
    /// 年度总支出
    func totalYearlyExpense() -> Double {
        totalMonthlyExpense() * 12
    }
}
