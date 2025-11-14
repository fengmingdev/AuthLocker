import Foundation

/// 应用锁设置的轻量封装，用于 UI 读写核心配置
/// - 为什么：隔离控制器与核心管理器，保持接口稳定与便于测试
public struct AppLockSettings {
    private let manager: AppLockManager
    public init(manager: AppLockManager = .shared) { self.manager = manager }
    /// 是否开启应用锁
    public var enabled: Bool {
        get { manager.isEnabled() }
        set { manager.setEnabled(newValue) }
    }
    /// 后台触发锁的时间间隔
    public var triggerInterval: BackgroundTriggerInterval {
        get { manager.getTriggerInterval() }
        set { manager.setTriggerInterval(newValue) }
    }
    /// 默认解锁方式（PIN/生物识别/手势）
    public var defaultMethod: AppLockManager.UnlockMethod {
        get { manager.getDefaultMethod() }
        set { manager.setDefaultMethod(newValue) }
    }
    /// 最近安全事件（默认30天）
    public func recentEvents(days: Int = 30) -> [SecurityEvent] {
        manager.recentEvents(days: days)
    }
}
