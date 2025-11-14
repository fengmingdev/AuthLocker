import Foundation

public enum BackgroundTriggerInterval: Equatable {
    case minutes(Int)
    case never
}

/// 应用锁核心管理器（状态机 + 策略）
/// - 为什么：集中管理触发、解锁、锁定与风险/版本/信任策略，保证行为一致且可测试
public final class AppLockManager {
    public enum UnlockMethod: Equatable {
        case pin
        case biometric
        case gesture
    }
    /// 初始化配置（可持久化覆盖）
    public struct Configuration: Equatable {
        /// 初始是否启用应用锁
        public var enabled: Bool
        /// 后台触发间隔
        public var triggerInterval: BackgroundTriggerInterval
        /// 默认解锁方式
        public var defaultMethod: UnlockMethod
        /// 命名空间（账户隔离）
        public var accountID: String?
        /// 是否启用信任设备策略
        public var trustEnabled: Bool
        public init(enabled: Bool = false, triggerInterval: BackgroundTriggerInterval = .minutes(3), defaultMethod: UnlockMethod = .pin, accountID: String? = nil, trustEnabled: Bool = false) {
            self.enabled = enabled
            self.triggerInterval = triggerInterval
            self.defaultMethod = defaultMethod
            self.accountID = accountID
            self.trustEnabled = trustEnabled
        }
    }

    public enum State: Equatable {
        case locked
        case unlocked
        case lockedOut(until: Date)
    }

    public static let shared = AppLockManager()

    private var keychain = KeychainStorage()
    private let logger = SecurityLogger.shared
    private var config = Configuration()
    private var lastBackgroundAt: Date?
    private var state: State = .locked
    private var deviceLockedFlag = false
    private var defaultMethod: UnlockMethod = .pin
    private var timeProvider: TimeProvider = SystemTimeProvider()
    private var resetService: LockResetService?
    private var biometricFailures: Int = 0
    private var lastBiometryKind: BiometryKind = .none
    private var persistence = SettingsPersistence()
    private var riskDetector = RiskDetector()
    private var riskStatus: RiskStatus = .safe
    private var trustedUntil: Date?

    private init() {}

    public func configure(_ config: Configuration) {
        self.config = config
        let ns = config.accountID ?? "default"
        self.keychain = KeychainStorage(namespace: ns)
        state = config.enabled ? .locked : .unlocked
        defaultMethod = persistence.readDefaultMethod() ?? config.defaultMethod
        if let e = persistence.readEnabled() { self.config.enabled = e }
        if let iv = persistence.readTriggerInterval() { self.config.triggerInterval = iv }
        if let te = persistence.readTrustEnabled() { self.config.trustEnabled = te }
        if let t = persistence.readTrustedUntil() { self.trustedUntil = t }
        biometricFailures = 0
        lastBiometryKind = .none
        logger.record(SecurityEvent(kind: config.enabled ? .enabled : .disabled))
    }

    public func isEnabled() -> Bool { config.enabled }
    public func getTriggerInterval() -> BackgroundTriggerInterval { config.triggerInterval }

    public func currentState() -> State {
        let now = timeProvider.now()
        if let until = keychain.getLockoutUntil(), until > now { return .lockedOut(until: until) }
        if config.trustEnabled, let t = trustedUntil, t > now { return .unlocked }
        return state
    }

    public func onAppLaunch() {
        guard config.enabled else { state = .unlocked; return }
        state = .locked
        logger.record(SecurityEvent(kind: .appLaunchTrigger))
        applyRiskStatus()
        checkVersionChange()
    }

    public func onEnterBackground() {
        lastBackgroundAt = timeProvider.now()
    }

    public func onEnterForeground() {
        /// 为什么：前台触发遵循“后台间隔 + 设备锁屏 + 信任设备”综合策略
        guard config.enabled else { state = .unlocked; return }
        if case .never = config.triggerInterval {
            return
        }
        applyRiskStatus()
        if config.trustEnabled, let t = trustedUntil, t > timeProvider.now() { return }
        if deviceLockedFlag {
            state = .locked
            logger.record(SecurityEvent(kind: .deviceUnlock))
            deviceLockedFlag = false
            return
        }
        if let last = lastBackgroundAt {
            switch config.triggerInterval {
            case .minutes(let m):
                if timeProvider.now().timeIntervalSince(last) >= Double(m * 60) { state = .locked; logger.record(SecurityEvent(kind: .foregroundTrigger)) }
            case .never:
                break
            }
        } else {
            state = .locked
            logger.record(SecurityEvent(kind: .foregroundTrigger))
        }
    }

    public func requiresUnlock() -> Bool {
        switch currentState() {
        case .locked: return true
        case .unlocked: return false
        case .lockedOut: return true
        }
    }

    public func setEnabled(_ enabled: Bool) {
        config.enabled = enabled
        state = enabled ? .locked : .unlocked
        persistence.writeEnabled(enabled)
        logger.record(SecurityEvent(kind: enabled ? .enabled : .disabled))
    }

    public func setTriggerInterval(_ interval: BackgroundTriggerInterval) {
        config.triggerInterval = interval
        persistence.writeTriggerInterval(interval)
    }

    public func setDefaultMethod(_ method: UnlockMethod) { defaultMethod = method; persistence.writeDefaultMethod(method) }
    public func getDefaultMethod() -> UnlockMethod { defaultMethod }
    public func recentEvents(days: Int = 30) -> [SecurityEvent] { logger.recentEvents(days: days) }

    public func setTimeProvider(_ provider: TimeProvider) { timeProvider = provider }
    public func setResetService(_ service: LockResetService?) { resetService = service }
    public func setTrustEnabled(_ enabled: Bool) { config.trustEnabled = enabled; persistence.writeTrustEnabled(enabled) }
    public func isTrustEnabled() -> Bool { config.trustEnabled }

    public func setPIN(_ pin: String) -> Bool {
        let ok = keychain.storePIN(pin)
        if ok { state = .locked }
        return ok
    }

    public func resetPIN() {
        keychain.resetPIN()
        state = .locked
        logger.record(SecurityEvent(kind: .pinReset))
    }

    public func setGesture(_ sequence: [Int]) -> Bool {
        let ok = keychain.storeGesture(sequence)
        if ok { state = .locked }
        return ok
    }

    public func hasPINConfigured() -> Bool {
        return keychain.read(item: .pinHash) != nil && keychain.read(item: .pinSalt) != nil
    }

    public func hasGestureConfigured() -> Bool {
        return keychain.read(item: .gestureHash) != nil && keychain.read(item: .gestureSalt) != nil
    }

    public func attemptUnlockWithPIN(_ pin: String) -> Bool {
        /// 为什么：失败计数驱动锁定（5 次失败 -> 10 分钟），成功清零计数
        let now = timeProvider.now()
        if let until = keychain.getLockoutUntil(), until > now {
            state = .lockedOut(until: until)
            return false
        }
        if keychain.validatePIN(pin) {
            keychain.setAttemptCount(0)
            state = .unlocked
            logger.record(SecurityEvent(kind: .unlockSuccess))
            return true
        } else {
            let attempts = keychain.getAttemptCount() + 1
            keychain.setAttemptCount(attempts)
            if attempts >= 5 {
                let until = timeProvider.now().addingTimeInterval(10 * 60)
                keychain.setLockout(until: until)
                state = .lockedOut(until: until)
                logger.record(SecurityEvent(kind: .lockoutStarted, details: "10min"))
            } else {
                state = .locked
            }
            logger.record(SecurityEvent(kind: .unlockFailure, details: "attempts=\(attempts)"))
            return false
        }
    }

    public func attemptUnlockWithGesture(_ sequence: [Int]) -> Bool {
        /// 为什么：手势错误次数累积到 4 次后需回退或提示
        let now = timeProvider.now()
        if let until = keychain.getLockoutUntil(), until > now {
            state = .lockedOut(until: until)
            return false
        }
        if keychain.validateGesture(sequence) {
            keychain.setGestureAttemptCount(0)
            state = .unlocked
            logger.record(SecurityEvent(kind: .unlockSuccess, details: "gesture"))
            return true
        } else {
            let attempts = keychain.getGestureAttemptCount() + 1
            keychain.setGestureAttemptCount(attempts)
            if attempts >= 4 {
                state = .locked
            }
            logger.record(SecurityEvent(kind: .unlockFailure, details: "gesture_attempts=\(attempts)"))
            return false
        }
    }

    public func onDeviceLock() {
        deviceLockedFlag = true
        logger.record(SecurityEvent(kind: .deviceLock))
    }

    public func onAccountSwitched(to accountID: String?) {
        let ns = accountID ?? "default"
        keychain = KeychainStorage(namespace: ns)
        state = .locked
    }

    public func attemptBiometricUnlock(reason: String, completion: @escaping (Bool) -> Void) {
        /// 为什么：风险环境禁用；网络时间与本地时间漂移过大时阻止以防回溯攻击
        if riskStatus != .safe { completion(false); return }
        if let net = timeProvider.networkNow() {
            let local = timeProvider.now()
            if abs(net.timeIntervalSince(local)) > 600 {
                completion(false)
                return
            }
        }
        let bio = BiometricAuthenticator.shared
        let kind = bio.availableBiometry()
        lastBiometryKind = kind
        guard kind != .none else { completion(false); return }
        bio.authenticateDetailed(reason: reason) { success, reason in
            if success {
                self.state = .unlocked
                self.logger.record(SecurityEvent(kind: .unlockSuccess, details: "biometric"))
                self.biometricFailures = 0
                completion(true)
            } else {
                self.biometricFailures += 1
                let detail = {
                    switch reason {
                    case .lockedOut?: return "lockedOut"
                    case .notAvailable?: return "notAvailable"
                    case .userCancel?: return "userCancel"
                    case .other?: return "other"
                    case nil: return "unknown"
                    }
                }()
                self.logger.record(SecurityEvent(kind: .unlockFailure, details: "biometric_fail=\(detail), count=\(self.biometricFailures)"))
                completion(false)
            }
        }
    }

    public func isBiometryEnabled() -> Bool { riskStatus == .safe && BiometricAuthenticator.shared.availableBiometry() != .none }

    public func setRiskStatusForTest(_ status: RiskStatus) { riskStatus = status }

    private func applyRiskStatus() {
        /// 为什么：每次前台与启动时刷新风险态，记录日志并收敛能力
        let status = riskDetector.evaluate()
        if status != .safe {
            riskStatus = status
            logger.record(SecurityEvent(kind: .riskDetected, details: "\(status)"))
        } else {
            riskStatus = .safe
        }
    }

    public func shouldSuggestPINAfterBiometricFailure() -> Bool {
        /// 为什么：FaceID 2 次/TouchID 3 次失败后建议改用 PIN，提高成功率与体验
        let threshold: Int
        switch lastBiometryKind {
        case .faceID: threshold = 2
        case .touchID: threshold = 3
        default: threshold = 3
        }
        return biometricFailures >= threshold
    }

    public func setBiometryKindForTest(_ kind: BiometryKind) { lastBiometryKind = kind }
    public func simulateBiometricFailureForTest() { biometricFailures += 1 }

    public func startPINReset(toPhone phone: String, completion: @escaping (Bool) -> Void) {
        guard let service = resetService else { completion(false); return }
        service.requestVerificationCode(toPhone: phone, completion: completion)
    }

    public func completePINReset(code: String, newPIN: String, completion: @escaping (Bool) -> Void) {
        guard let service = resetService else { completion(false); return }
        service.verifyCode(code) { ok in
            if ok {
                let saved = self.setPIN(newPIN)
                if saved { self.logger.record(SecurityEvent(kind: .pinReset)) }
                completion(saved)
            } else {
                completion(false)
            }
        }
    }

    private func checkVersionChange() {
        let defaults = UserDefaults.standard
        let key = "authlocker.app.version"
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let previous = defaults.string(forKey: key)
        if previous != nil && previous != current {
            state = .locked
            logger.record(SecurityEvent(kind: .versionChanged, details: "\(previous ?? "") -> \(current)"))
        }
        defaults.setValue(current, forKey: key)
    }

    public func setTrustedDays(_ days: Int) {
        /// 设置信任设备天数（启用后前台触发免锁），写入持久化
        guard config.trustEnabled else { return }
        let until = timeProvider.now().addingTimeInterval(Double(days) * 86400)
        trustedUntil = until
        persistence.writeTrustedUntil(until)
    }

    public func clearTrusted() {
        /// 清除信任设备
        trustedUntil = nil
        persistence.clearTrustedUntil()
    }

    public func isTrustedActive() -> Bool {
        /// 当前是否处于信任窗口内
        guard config.trustEnabled, let t = trustedUntil else { return false }
        return t > timeProvider.now()
    }
}
