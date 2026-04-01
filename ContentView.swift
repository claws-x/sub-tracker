//
//  ContentView.swift
//  SubTracker
//
//  Created by AI Agent on 2026-03-27.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddSubscription = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.nextBillingDate, ascending: true)],
        animation: .default)
    private var subscriptions: FetchedResults<Subscription>
    
    var monthlyTotal: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyPrice }
    }
    
    var yearlyTotal: Double {
        monthlyTotal * 12
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 支出统计卡片
                ExpenseSummaryCard(monthly: monthlyTotal, yearly: yearlyTotal)
                
                // 订阅列表
                List(subscriptions) { sub in
                    SubscriptionRow(subscription: sub)
                }
                .listStyle(.plain)
            }
            .navigationTitle("订阅管家")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSubscription = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSubscription) {
                AddSubscriptionView()
            }
        }
    }
}

/// 支出统计卡片
struct ExpenseSummaryCard: View {
    let monthly: Double
    let yearly: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                // 月度支出
                VStack(alignment: .leading) {
                    Text("月度支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(monthly, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Divider()
                
                // 年度支出
                VStack(alignment: .leading) {
                    Text("年度支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(yearly, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
}

/// 订阅行视图
struct SubscriptionRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    let subscription: Subscription
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // 类别图标
                Image(systemName: subscription.categoryIcon)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Text("¥\(subscription.price, specifier: "%.2f")/\(subscription.billingCycleText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(subscription.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(subscription.statusText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text("¥\(subscription.monthlyPrice, specifier: "%.2f")/月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .alert("删除订阅", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                viewContext.delete(subscription)
                try? viewContext.save()
            }
        } message: {
            Text("确定要删除「\(subscription.name)」吗？")
        }
    }
    
    var statusColor: Color {
        if subscription.daysRemaining <= 0 {
            return .red
        } else if subscription.daysRemaining <= 1 {
            return .orange
        } else if subscription.daysRemaining <= 7 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Helpers
extension Subscription {
    var categoryIcon: String {
        SubscriptionCategory.allCases.first { $0.rawValue == category }?.icon ?? "bag"
    }
    
    var billingCycleText: String {
        switch billingCycle {
        case "weekly": return "周"
        case "monthly": return "月"
        case "yearly": return "年"
        default: return "月"
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
    }
}
