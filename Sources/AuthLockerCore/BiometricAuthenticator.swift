import Foundation
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

/// 生物识别类型
public enum BiometryKind: Equatable {
    case none
    case touchID
    case faceID
}

/// 生物识别封装
/// - 为什么：统一可用性判断与错误映射，减少调用方复杂度
public final class BiometricAuthenticator {
    public static let shared = BiometricAuthenticator()
    private init() {}

    /// 返回设备支持的生物识别类型
    public func availableBiometry() -> BiometryKind {
        #if canImport(LocalAuthentication)
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if #available(iOS 11.0, macOS 10.13.2, *) {
                switch context.biometryType {
                case .faceID: return .faceID
                case .touchID: return .touchID
                default: return .none
                }
            } else {
                return .touchID
            }
        }
        return .none
        #else
        return .none
        #endif
    }

    /// 触发生物识别验证（简单结果）
    public func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        #if canImport(LocalAuthentication)
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
        } else {
            completion(false)
        }
        #else
        completion(false)
        #endif
    }

    /// 失败原因枚举（标准化映射）
    public enum FailureReason: Equatable {
        case lockedOut
        case notAvailable
        case userCancel
        case other
    }

    /// 触发生物识别验证并返回标准化失败原因
    public func authenticateDetailed(reason: String, completion: @escaping (Bool, FailureReason?) -> Void) {
        #if canImport(LocalAuthentication)
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, err in
                let mapped: FailureReason? = {
                    guard let e = err as NSError? else { return nil }
                    if #available(iOS 11.0, macOS 10.13.2, *) {
                        switch LAError.Code(rawValue: e.code) {
                        case .biometryLockout: return .lockedOut
                        case .biometryNotAvailable: return .notAvailable
                        case .userCancel, .systemCancel: return .userCancel
                        default: return .other
                        }
                    } else {
                        return .other
                    }
                }()
                DispatchQueue.main.async { completion(success, mapped) }
            }
        } else {
            completion(false, .notAvailable)
        }
        #else
        completion(false, .notAvailable)
        #endif
    }
}
