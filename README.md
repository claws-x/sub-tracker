# SubTracker - 订阅管家

**版本**: 1.0  
**创建日期**: 2026-03-27  
**定价**: $1.99（一次性买断）

---

## 📱 应用简介

SubTracker 是一款极简的订阅服务管理工具，帮助您：
- 📝 追踪所有订阅服务（视频、音乐、软件等）
- 🔔 续费前自动提醒，避免忘记取消
- 📊 统计月度/年度订阅支出
- 💾 本地存储，隐私安全

**痛点**: 忘记取消订阅，白白被扣费！

---

## 🎯 核心功能

| 功能 | 说明 |
|------|------|
| 订阅管理 | 添加/编辑/删除订阅服务 |
| 到期提醒 | 续费前 7 天/3 天/1 天推送通知 |
| 支出统计 | 月度/年度订阅总支出 |
| 分类管理 | 视频、音乐、软件、服务等 |
| 本地存储 | 无需注册，数据不离设备 |

---

## 🏗️ 技术架构

- **UI 框架**: SwiftUI
- **数据存储**: CoreData
- **通知系统**: UserNotifications
- **最低版本**: iOS 16.0

---

## 📁 项目结构

```
SubTracker/
├── SubTrackerApp.swift      # 应用入口
├── ContentView.swift         # 主界面
├── AddSubscriptionView.swift # 添加订阅
├── Models.swift              # 数据模型
├── DataController.swift      # CoreData 控制器
├── NotificationManager.swift # 通知管理器
├── Assets.xcassets/          # 资源文件
└── CoreData/                 # CoreData 模型
```

---

## 🚀 快速开始

1. 打开 `SubTracker.xcodeproj`
2. 选择目标设备
3. 点击运行 (⌘R)

---

## 📄 许可证

Copyright © 2026 Claws X. All rights reserved.
