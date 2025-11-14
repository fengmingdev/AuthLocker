import Foundation

/// 简易 PIN 重置服务（示例实现）
/// - 为什么：无需后端即可演示流程；生产环境请替换为安全的短信/风控服务
public final class SimpleLockResetService: LockResetService {
    private let defaults: UserDefaults
    private let prefix = "authlocker.reset."
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    /// 生成并缓存 6 位验证码（10 分钟有效）
    public func requestVerificationCode(toPhone phone: String, completion: @escaping (Bool) -> Void) {
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        let ts = Date().timeIntervalSince1970
        defaults.set(["code": code, "ts": ts], forKey: prefix + phone)
        completion(true)
    }

    /// 验证输入的验证码是否命中有效缓存
    public func verifyCode(_ code: String, completion: @escaping (Bool) -> Void) {
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        var ok = false
        for k in keys {
            if let dict = defaults.dictionary(forKey: k), let stored = dict["code"] as? String, let ts = dict["ts"] as? Double {
                if Date().timeIntervalSince1970 - ts <= 600, stored == code {
                    ok = true
                    defaults.removeObject(forKey: k)
                    break
                }
            }
        }
        completion(ok)
    }
}
