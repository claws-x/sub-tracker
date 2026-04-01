//
//  AddSubscriptionView.swift
//  SubTracker
//
//  Created by AI Agent on 2026-03-27.
//

import SwiftUI

struct AddSubscriptionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedCategory = SubscriptionCategory.video
    @State private var price = ""
    @State private var selectedCycle = BillingCycle.monthly
    @State private var nextBillingDate = Date()
    @State private var notes = ""
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // 基本信息
                Section(header: Text("基本信息")) {
                    TextField("订阅名称（如：Netflix）", text: $name)
                    
                    Picker("类别", selection: $selectedCategory) {
                        ForEach(SubscriptionCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                // 价格信息
                Section(header: Text("价格信息")) {
                    TextField("价格（如：9.99）", text: $price)
                        .keyboardType(.decimalPad)
                    
                    Picker("计费周期", selection: $selectedCycle) {
                        ForEach(BillingCycle.allCases) { cycle in
                            Text(cycle.rawValue).tag(cycle)
                        }
                    }
                }
                
                // 续费日期
                Section(header: Text("续费日期")) {
                    DatePicker("下次续费日期", selection: $nextBillingDate, displayedComponents: .date)
                }
                
                // 备注
                Section(header: Text("备注（可选）")) {
                    TextField("备注信息", text: $notes, axis: .vertical)
                }
                
                // 提醒设置
                Section(header: Text("提醒设置")) {
                    Toggle("启用续费提醒", isOn: .constant(true))
                    Text("将在续费前 7 天、3 天、1 天发送通知")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加订阅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSubscription()
                    }
                    .disabled(name.isEmpty || price.isEmpty)
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveSubscription() {
        guard !name.isEmpty else {
            alertMessage = "请输入订阅名称"
            showingAlert = true
            return
        }
        
        guard let priceValue = Double(price), priceValue > 0 else {
            alertMessage = "请输入有效价格"
            showingAlert = true
            return
        }
        
        let sub = Subscription(context: viewContext)
        sub.id = UUID()
        sub.name = name
        sub.category = selectedCategory.rawValue
        sub.price = priceValue
        sub.currency = "CNY"
        sub.billingCycle = selectedCycle.rawValue
        sub.nextBillingDate = nextBillingDate
        sub.notes = notes.isEmpty ? nil : notes
        sub.reminderEnabled = true
        sub.createdAt = Date()
        
        do {
            try viewContext.save()
            
            // 设置提醒
            scheduleReminder(for: sub)
            
            dismiss()
        } catch {
            alertMessage = "保存失败：\(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func scheduleReminder(for sub: Subscription) {
        // 简化实现，实际应使用 UserNotifications
        print("将为 \(sub.name) 设置续费提醒")
    }
}

// MARK: - Preview
struct AddSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        AddSubscriptionView()
            .environment(\.managedObjectContext, DataController(inMemory: true).container.viewContext)
    }
}
