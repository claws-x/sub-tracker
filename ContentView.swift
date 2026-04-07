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
    @State private var activeSheet: SubscriptionSheet?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.nextBillingDate, ascending: true)],
        animation: .default
    )
    private var subscriptions: FetchedResults<Subscription>

    private var monthlyTotal: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyPrice }
    }

    private var yearlyTotal: Double {
        subscriptions.reduce(0) { $0 + $1.yearlyPrice }
    }

    private var activeReminders: Int {
        subscriptions.filter(\.reminderEnabled).count
    }

    private var upcomingRenewals: [Subscription] {
        subscriptions.filter { $0.daysRemaining <= 7 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    EmptySubscriptionsView {
                        activeSheet = .add
                    }
                } else {
                    List {
                        Section {
                            ExpenseSummaryCard(
                                subscriptionCount: subscriptions.count,
                                monthly: monthlyTotal,
                                yearly: yearlyTotal,
                                remindersEnabled: activeReminders
                            )
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }

                        if !upcomingRenewals.isEmpty {
                            Section("7 天内即将续费") {
                                ForEach(upcomingRenewals) { sub in
                                    SubscriptionRow(subscription: sub)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            activeSheet = .edit(sub.objectID)
                                        }
                                }
                            }
                        }

                        Section("全部订阅") {
                            ForEach(subscriptions) { sub in
                                SubscriptionRow(subscription: sub)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        activeSheet = .edit(sub.objectID)
                                    }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("SubTracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .add
                    } label: {
                        Label("添加订阅", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { destination in
                switch destination {
                case .add:
                    AddSubscriptionView()
                        .environment(\.managedObjectContext, viewContext)
                case .edit(let objectID):
                    SubscriptionEditorSheet(objectID: objectID)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
    }
}

private enum SubscriptionSheet: Identifiable {
    case add
    case edit(NSManagedObjectID)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let objectID):
            return objectID.uriRepresentation().absoluteString
        }
    }
}

private struct SubscriptionEditorSheet: View {
    @Environment(\.managedObjectContext) private var viewContext

    let objectID: NSManagedObjectID

    var body: some View {
        if let subscription = try? viewContext.existingObject(with: objectID) as? Subscription {
            AddSubscriptionView(subscription: subscription)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
                Text("订阅不存在")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ExpenseSummaryCard: View {
    let subscriptionCount: Int
    let monthly: Double
    let yearly: Double
    let remindersEnabled: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("订阅概览")
                .font(.headline)

            HStack(alignment: .top) {
                metricView(title: "月均支出", value: monthly.formattedCurrency())
                Spacer()
                metricView(title: "年均支出", value: yearly.formattedCurrency())
            }

            Divider()

            HStack {
                Label("\(subscriptionCount) 个活跃订阅", systemImage: "creditcard")
                Spacer()
                Label("\(remindersEnabled) 个提醒已启用", systemImage: "bell")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.14), Color.cyan.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func metricView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
    }
}

struct SubscriptionRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false

    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subscription.categoryIcon)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(statusColor.opacity(0.14))
                .foregroundStyle(statusColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(subscription.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text("\(subscription.priceText)/\(subscription.billingCycleOption.shortLabel)")
                    Text("•")
                    Text(subscription.category)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("下次续费 \(subscription.nextBillingDateText) · \(subscription.nextBillingRelativeText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(subscription.statusText)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())

                Text("\(subscription.monthlyPriceText)/月")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .alert("删除订阅", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                NotificationManager.shared.cancelReminders(for: subscription)
                viewContext.delete(subscription)
                try? viewContext.save()
            }
        } message: {
            Text("确定要删除「\(subscription.name)」吗？")
        }
    }

    private var statusColor: Color {
        if subscription.daysRemaining <= 0 {
            return .red
        } else if subscription.daysRemaining <= 3 {
            return .orange
        } else if subscription.daysRemaining <= 7 {
            return .yellow
        } else {
            return .green
        }
    }
}

private struct EmptySubscriptionsView: View {
    let addAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 44))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("先添加你的第一个订阅")
                    .font(.title3.weight(.semibold))
                Text("记录周期、价格和下次扣费时间，避免忘记取消自动续费。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("添加订阅", action: addAction)
                .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private extension Subscription {
    var categoryIcon: String {
        SubscriptionCategory.allCases.first { $0.rawValue == category }?.icon ?? "bag"
    }
}

private extension Double {
    func formattedCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
    }
}
