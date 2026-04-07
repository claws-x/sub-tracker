//
//  AddSubscriptionView.swift
//  SubTracker
//
//  Created by AI Agent on 2026-03-27.
//

import SwiftUI
import UserNotifications

struct AddSubscriptionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    private let subscription: Subscription?

    @State private var name: String
    @State private var selectedCategory: SubscriptionCategory
    @State private var price: String
    @State private var selectedCycle: BillingCycleOption
    @State private var nextBillingDate: Date
    @State private var notes: String
    @State private var remindersEnabled: Bool

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var isSaving = false

    init(subscription: Subscription? = nil) {
        self.subscription = subscription
        _name = State(initialValue: subscription?.name ?? "")
        _selectedCategory = State(initialValue: SubscriptionCategory.allCases.first { $0.rawValue == subscription?.category } ?? .video)
        _price = State(initialValue: subscription.map { String(format: "%.2f", $0.price) } ?? "")
        _selectedCycle = State(initialValue: subscription.map { BillingCycleOption.fromPersistedValue($0.billingCycle) } ?? .monthly)
        _nextBillingDate = State(initialValue: subscription?.nextBillingDate ?? Date())
        _notes = State(initialValue: subscription?.notes ?? "")
        _remindersEnabled = State(initialValue: subscription?.reminderEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("订阅名称，例如 Netflix", text: $name)

                    Picker("类别", selection: $selectedCategory) {
                        ForEach(SubscriptionCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section("价格信息") {
                    TextField("价格", text: $price)
                        .keyboardType(.decimalPad)

                    Picker("计费周期", selection: $selectedCycle) {
                        ForEach(BillingCycleOption.allCases) { cycle in
                            Text(cycle.title).tag(cycle)
                        }
                    }
                }

                Section("续费信息") {
                    DatePicker("下次续费日期", selection: $nextBillingDate, displayedComponents: .date)

                    if let parsedPrice {
                        LabeledContent("折算月均") {
                            Text(
                                (parsedPrice * selectedCycle.monthlyMultiplier).formattedCurrency(
                                    code: Locale.current.currency?.identifier ?? "USD"
                                )
                            )
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("提醒") {
                    Toggle("启用续费提醒", isOn: $remindersEnabled)

                    Text(reminderFootnote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("备注") {
                    TextField("可记录套餐说明、家庭共享等信息", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(subscription == nil ? "添加订阅" : "编辑订阅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveSubscription()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedPrice == nil || isSaving)
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .task {
                permissionStatus = await NotificationManager.shared.authorizationStatus()
            }
            .onChange(of: remindersEnabled) { newValue in
                guard newValue else { return }
                Task {
                    let status = await NotificationManager.shared.requestAuthorizationIfNeeded()
                    await MainActor.run {
                        permissionStatus = status
                        if status == .denied {
                            remindersEnabled = false
                            alertMessage = "通知权限未开启。你仍可保存订阅，但需要在系统设置中允许通知后才能收到续费提醒。"
                            showingAlert = true
                        }
                    }
                }
            }
        }
    }

    private var parsedPrice: Double? {
        Double(price.replacingOccurrences(of: ",", with: "."))
    }

    private var reminderFootnote: String {
        switch permissionStatus {
        case .authorized, .provisional, .ephemeral:
            return "会在续费前 7 天、3 天、1 天安排本地提醒。"
        case .denied:
            return "系统通知权限已关闭。保存后不会发送提醒，需前往系统设置开启。"
        case .notDetermined:
            return "开启后会请求系统通知权限。"
        @unknown default:
            return "提醒状态未知，保存后会尝试同步。"
        }
    }

    private func saveSubscription() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            alertMessage = "请输入订阅名称。"
            showingAlert = true
            return
        }

        guard let priceValue = parsedPrice, priceValue > 0 else {
            alertMessage = "请输入有效价格。"
            showingAlert = true
            return
        }

        isSaving = true

        let target = subscription ?? Subscription(context: viewContext)
        if subscription == nil {
            target.id = UUID()
            target.createdAt = Date()
        }

        target.name = trimmedName
        target.category = selectedCategory.rawValue
        target.price = priceValue
        target.currency = Locale.current.currency?.identifier ?? "USD"
        target.billingCycle = selectedCycle.rawValue
        target.nextBillingDate = nextBillingDate
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        target.reminderEnabled = remindersEnabled

        do {
            try viewContext.save()

            Task {
                let syncResult = await NotificationManager.shared.syncReminders(for: target)
                await MainActor.run {
                    isSaving = false
                    switch syncResult {
                    case .success, .disabled:
                        dismiss()
                    case .permissionDenied:
                        alertMessage = "订阅已保存，但当前没有通知权限，因此未能安排续费提醒。"
                        showingAlert = true
                    case .failure(let message):
                        alertMessage = "订阅已保存，但提醒同步失败：\(message)"
                        showingAlert = true
                    }
                }
            }
        } catch {
            isSaving = false
            alertMessage = "保存失败：\(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct AddSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        AddSubscriptionView()
            .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
    }
}
