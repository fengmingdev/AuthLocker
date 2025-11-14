# 应用锁（AuthLocker）逻辑与集成指南

## 总览
AuthLocker 提供可扩展的应用锁能力，覆盖 PIN、手势与生物识别三种方式，并结合后台触发、设备锁屏、信任设备、风险检测与版本变更等策略构成完整的状态机与事件记录体系。该指南面向集成者与二次开发者，说明核心架构、关键 API、触发策略与 UI 集成方式。

## 核心架构
- 核心状态机：`Sources/AuthLockerCore/AppLockManager.swift:10`
  - 状态：`locked`、`unlocked`、`lockedOut(until:)`（`AppLockManager.State`，`Sources/AuthLockerCore/AppLockManager.swift:37`）
  - 默认解锁方式：`AppLockManager.UnlockMethod`（`pin`/`biometric`/`gesture`，`Sources/AuthLockerCore/AppLockManager.swift:11`）
  - 配置结构：`AppLockManager.Configuration`（`enabled`、`triggerInterval`、`defaultMethod`、`accountID`、`trustEnabled`，`Sources/AuthLockerCore/AppLockManager.swift:16–35`）
- 设置持久化：`Sources/AuthLockerCore/SettingsPersistence.swift:5`
  - 读写启用状态：`readEnabled`/`writeEnabled`（`Sources/AuthLockerCore/SettingsPersistence.swift:10–18`）
  - 读写默认解锁方式：`readDefaultMethod`/`writeDefaultMethod`（`Sources/AuthLockerCore/SettingsPersistence.swift:20–35`）
  - 读写后台触发间隔：`readTriggerInterval`/`writeTriggerInterval`（`Sources/AuthLockerCore/SettingsPersistence.swift:37–49`）
  - 信任设备：`readTrustedUntil`/`writeTrustedUntil`/`clearTrustedUntil`/`readTrustEnabled`/`writeTrustEnabled`（`Sources/AuthLockerCore/SettingsPersistence.swift:52–76`）
- 安全日志：`Sources/AuthLockerCore/SecurityLogger.swift:35`
  - 事件模型与类型：`SecurityEvent`/`SecurityEvent.Kind`（`unlockSuccess`、`unlockFailure`、`lockoutStarted` 等，`Sources/AuthLockerCore/SecurityLogger.swift:3–19`）
  - 记录与查询：`record`、`recentEvents`、`query`（`Sources/AuthLockerCore/SecurityLogger.swift:59–83`）
  - 导出：`exportCSV`（`Sources/AuthLockerCore/SecurityLogger.swift:85–99`）
- 设备锁屏监控：`Sources/AuthLockerUIKit/DeviceLockMonitor.swift:7`
  - 监听 `UIApplicationProtectedDataWillBecomeUnavailable` 并触发 `onDeviceLock`（`Sources/AuthLockerUIKit/DeviceLockMonitor.swift:17–21`）

## 触发策略
- 启动触发：`onAppLaunch`（`Sources/AuthLockerCore/AppLockManager.swift:88–94`）在启用时进入 `locked` 并记录 `appLaunchTrigger`
- 前台触发：`onEnterForeground`（`Sources/AuthLockerCore/AppLockManager.swift:100–125`）
  - 满足后台间隔（`BackgroundTriggerInterval.minutes(m)`）即触发锁定并记录 `foregroundTrigger`
  - 若处于信任设备窗口内则跳过触发
  - 若检测到设备锁屏事件（`onDeviceLock`）则锁定并记录 `deviceUnlock`
- 后台记录：`onEnterBackground`（`Sources/AuthLockerCore/AppLockManager.swift:96–98`）写入时间用于前台触发间隔判定
- 版本变更：`checkVersionChange`（`Sources/AuthLockerCore/AppLockManager.swift:314–324`）版本跃迁时强制锁定并记录 `versionChanged`
- 风险检测：`applyRiskStatus`（`Sources/AuthLockerCore/AppLockManager.swift:271–280`）在风险态收敛能力（禁用生物识别，记录 `riskDetected`）

## 解锁方法
- PIN：`attemptUnlockWithPIN`（`Sources/AuthLockerCore/AppLockManager.swift:168–194`）
  - 失败计数累积至 5 次时进入 10 分钟锁定（记录 `lockoutStarted`），成功清零计数并记录 `unlockSuccess`
- 手势：`attemptUnlockWithGesture`（`Sources/AuthLockerCore/AppLockManager.swift:196–217`）
  - 失败计数至 4 次后进入 `locked`，成功记录 `unlockSuccess(details: "gesture")`
- 生物识别：`attemptBiometricUnlock`（`Sources/AuthLockerCore/AppLockManager.swift:230–265`）
  - 风险态禁用；网络时间与本地时间漂移过大全禁；成功记录 `unlockSuccess(details: "biometric")`

## 信任设备策略
- 启用/关闭：`setTrustEnabled`/`isTrustEnabled`（`Sources/AuthLockerCore/AppLockManager.swift:153–154`）
- 写入信任窗口：`setTrustedDays`（通过 `SettingsPersistence.writeTrustedUntil`，引用于管理器内部逻辑）
- 清除信任：`clearTrusted`（`Sources/AuthLockerCore/AppLockManager.swift:334–339`）
- 判断是否在信任窗口：`isTrustedActive`（`Sources/AuthLockerCore/AppLockManager.swift:341–345`）

## 日志与导出
- 记录所有关键事件：启用/禁用、触发、成功/失败、锁定期、风险、版本变更等（参见 `SecurityLogger.record` 与各处 `logger.record(...)` 调用）
- 导出 CSV：`SecurityLogger.exportCSV(limit:sanitize:)`，可脱敏 `details` 字段（`Sources/AuthLockerCore/SecurityLogger.swift:85–99`）

## UI 集成（UIKit）
- 统一工厂入口：`LockUIFactory.make(manager:style:delegate:keypadLayout:gridLayout)`（`Sources/AuthLockerUIKit/LockUIFactory.swift`）
  - 自动根据 `AppLockManager.getDefaultMethod()` 返回 PIN 或手势控制器
  - 支持注入 `LockStyleProvider`（主题）、`KeypadLayoutProvider`（键盘布局）、`GestureGridLayoutProvider`（点阵布局）、`LockUIEventDelegate`（统一事件）
- 样式系统：`LockStyleProvider` 与预设 `MinimalStyle` / `StrongBrandStyle`
  - 主题切换：`LockThemeManager.shared.setStyle(...)`（`Sources/AuthLockerUIKit/LockThemeManager.swift`）
- 事件协议：`LockUIEventDelegate`（`Sources/AuthLockerUIKit/LockInteraction.swift`）
  - `didRequestPINReset`、`didRequestSwitchToPIN`、`didUnlockSuccess(method:)`、`didUnlockFailure(method:)`

### 示例（UIKit）
```swift
// 入口处（示例首页）创建锁界面并展示
let vc = LockUIFactory.make(manager: AppLockManager.shared,
                            style: LockThemeManager.shared.currentStyle,
                            delegate: self)
present(vc, animated: true)

// 运行时切换主题
LockThemeManager.shared.setStyle(StrongBrandStyle())
```

## UI 集成（SwiftUI）
- 适配器：`LockViewAdapter(manager:style:keypadLayout:gridLayout)`（`Sources/AuthLockerSwiftUIAdapter/LockViewAdapter.swift`）
  - 内部通过工厂初始化并返回 `UINavigationController`

### 示例（SwiftUI）
```swift
// SwiftUI 场景里嵌入锁界面
LockViewAdapter(manager: .shared, style: MinimalStyle())
```

## 设置页集成
- 面向 UI 的轻量封装：`AppLockSettings`（`Sources/AuthLockerCore/AppLockSettings.swift`）
  - 启用开关：`enabled`（读写 `AppLockManager.isEnabled/setEnabled`）
  - 后台触发间隔：`triggerInterval`（读写 `AppLockManager.get/setTriggerInterval`）
  - 默认解锁方式：`defaultMethod`（读写 `AppLockManager.get/setDefaultMethod`）
- 示例设置页：`Examples/AuthLockerDemo/.../SettingsViewController.swift` 通过 `AppLockSettings` 与管理器交互

## 设备锁屏监控
- `DeviceLockMonitor.start()` 订阅系统受保护数据事件，触发 `onDeviceLock`，用于前台归来时判定（`Sources/AuthLockerUIKit/DeviceLockMonitor.swift:17–21`）

## 事件语义与保留期
- 所有事件以 JSONL 附加在应用支持目录，默认保留 30 天，可通过 `SecurityLogger.setRetentionDays` 调整（`Sources/AuthLockerCore/SecurityLogger.swift:115–125`）

## 使用指南（推荐流程）
1. 启用并配置
```swift
let manager = AppLockManager.shared
manager.configure(.init(enabled: true, triggerInterval: .minutes(3), defaultMethod: .pin, accountID: "userA", trustEnabled: true))
manager.onAppLaunch()
```
2. 设置默认解锁方式与触发策略
```swift
manager.setDefaultMethod(.gesture)
manager.setTriggerInterval(.minutes(5))
```
3. 集成 UI
```swift
LockThemeManager.shared.setStyle(MinimalStyle())
let lockVC = LockUIFactory.make(manager: manager, style: LockThemeManager.shared.currentStyle, delegate: self)
present(lockVC, animated: true)
```
4. 设备锁监控（可选）
```swift
let monitor = DeviceLockMonitor()
monitor.start()
```
5. 导出日志
```swift
let csv = SecurityLogger.shared.exportCSV(limit: 1000, sanitize: true)
```

## 扩展性建议
- 主题：实现自定义 `LockStyleProvider` 并通过 `LockThemeManager.setStyle` 切换
- 布局：实现 `KeypadLayoutProvider`/`GestureGridLayoutProvider` 自定义键盘键位与点阵规模
- 交互：通过 `LockUIEventDelegate` 统一上报与调试，提高可观测性
- 风险策略：根据业务强化 `RiskDetector`，在越狱/注入等风险态收敛能力

## 关键 API 参考
- 配置与状态
  - `AppLockManager.configure(_:)`（`Sources/AuthLockerCore/AppLockManager.swift:63–76`）
  - `AppLockManager.currentState()`（`Sources/AuthLockerCore/AppLockManager.swift:81–86`）
  - `AppLockManager.requiresUnlock()`（`Sources/AuthLockerCore/AppLockManager.swift:127–133`）
- 触发与锁屏
  - `onAppLaunch`（`Sources/AuthLockerCore/AppLockManager.swift:88–94`）
  - `onEnterBackground`（`Sources/AuthLockerCore/AppLockManager.swift:96–98`）
  - `onEnterForeground`（`Sources/AuthLockerCore/AppLockManager.swift:100–125`）
  - `onDeviceLock`（`Sources/AuthLockerCore/AppLockManager.swift:219–222`）
- 解锁与策略
  - `attemptUnlockWithPIN`（`Sources/AuthLockerCore/AppLockManager.swift:168–194`）
  - `attemptUnlockWithGesture`（`Sources/AuthLockerCore/AppLockManager.swift:196–217`）
  - `attemptBiometricUnlock`（`Sources/AuthLockerCore/AppLockManager.swift:230–265`）
- 设置读写
  - `setEnabled` / `isEnabled`（`Sources/AuthLockerCore/AppLockManager.swift:135–140`、`78`）
  - `setTriggerInterval` / `getTriggerInterval`（`Sources/AuthLockerCore/AppLockManager.swift:142–145`、`79`）
  - `setDefaultMethod` / `getDefaultMethod`（`Sources/AuthLockerCore/AppLockManager.swift:147–149`）
- 日志
  - `SecurityLogger.record`/`recentEvents`/`query`/`exportCSV`（`Sources/AuthLockerCore/SecurityLogger.swift:59–99`）

## 兼容性与无障碍
- 触控目标建议 ≥ 44×44pt，控件高度通过 `style.controlMinHeight` 控制
- 支持 `VoiceOver` 模式：手势页面在开启时隐藏点阵并提示改用密码
- iOS 13+ 支持：日志列表 iOS 13 回退单元格样式（示例已实现）

---
本指南覆盖 v2.0.0 核心逻辑与可扩展接口；后续如需新增主题预设或布局变体，可在现有协议之上实现并通过工厂/主题管理器完成集成。