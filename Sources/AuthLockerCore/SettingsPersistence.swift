import Foundation

/// 用户设置持久化
/// - 为什么：保持 AppLock 配置跨会话一致，避免直接操作 UserDefaults 分散
public struct SettingsPersistence {
    private let defaults: UserDefaults
    private let prefix = "authlocker.settings."
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    /// 读取是否启用应用锁
    public func readEnabled() -> Bool? {
        defaults.object(forKey: prefix + "enabled") as? Bool
    }

    /// 写入启用状态
    public func writeEnabled(_ enabled: Bool) {
        defaults.setValue(enabled, forKey: prefix + "enabled")
    }

    /// 读取默认解锁方式
    public func readDefaultMethod() -> AppLockManager.UnlockMethod? {
        guard let raw = defaults.string(forKey: prefix + "method") else { return nil }
        switch raw {
        case "pin": return .pin
        case "biometric": return .biometric
        case "gesture": return .gesture
        default: return nil
        }
    }

    /// 写入默认解锁方式
    public func writeDefaultMethod(_ method: AppLockManager.UnlockMethod) {
        let raw: String = (method == .pin ? "pin" : (method == .biometric ? "biometric" : "gesture"))
        defaults.setValue(raw, forKey: prefix + "method")
    }

    /// 读取后台触发间隔
    public func readTriggerInterval() -> BackgroundTriggerInterval? {
        if let raw = defaults.string(forKey: prefix + "interval"), raw == "never" { return .never }
        if let v = defaults.object(forKey: prefix + "interval") as? Int { return .minutes(v) }
        return nil
    }

    /// 写入后台触发间隔
    public func writeTriggerInterval(_ interval: BackgroundTriggerInterval) {
        switch interval {
        case .minutes(let m): defaults.setValue(m, forKey: prefix + "interval")
        case .never: defaults.setValue("never", forKey: prefix + "interval")
        }
    }

    /// 读取信任设备的截止时间
    public func readTrustedUntil() -> Date? {
        guard let ts = defaults.object(forKey: prefix + "trustedUntil") as? Double else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    /// 写入信任设备截止时间
    public func writeTrustedUntil(_ date: Date) {
        defaults.setValue(date.timeIntervalSince1970, forKey: prefix + "trustedUntil")
    }

    /// 清除信任设备时间
    public func clearTrustedUntil() {
        defaults.removeObject(forKey: prefix + "trustedUntil")
    }

    /// 读取是否启用信任设备策略
    public func readTrustEnabled() -> Bool? {
        defaults.object(forKey: prefix + "trustEnabled") as? Bool
    }

    /// 写入信任设备策略开关
    public func writeTrustEnabled(_ enabled: Bool) {
        defaults.setValue(enabled, forKey: prefix + "trustEnabled")
    }
}
