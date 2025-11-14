import Foundation

/// 时间提供者协议，便于注入网络时间与测试替身
/// - 为什么：解锁策略依赖时间（前后台间隔、信任期限、生物识别时间漂移），抽象时间源可测试与复用
public protocol TimeProvider {
    /// 返回当前本地时间
    func now() -> Date
    /// 返回可信的网络时间（可空）；当网络时间与本地时间漂移过大时将阻止生物识别解锁
    func networkNow() -> Date?
}

/// 系统时间实现：仅提供本地时间，网络时间为空
public struct SystemTimeProvider: TimeProvider {
    public init() {}
    public func now() -> Date { Date() }
    public func networkNow() -> Date? { nil }
}
