import Foundation
import Security
import CryptoKit

/// Keychain 安全存储
/// - 为什么：PIN/手势需持久化并抵抗备份与提取，使用设备级访问策略与命名空间隔离
public struct KeychainStorage {
    private let namespace: String
    public enum Item: String {
        case pinHash = "authlocker.pin.hash"
        case pinSalt = "authlocker.pin.salt"
        case lockoutUntil = "authlocker.lockout.until"
        case attemptCount = "authlocker.pin.attempts"
        case gestureHash = "authlocker.gesture.hash"
        case gestureSalt = "authlocker.gesture.salt"
        case gestureAttempts = "authlocker.gesture.attempts"
    }

    public init(namespace: String = "default") {
        self.namespace = namespace
    }

    /// 写入任意数据到 Keychain（覆盖模式）
    public func store(_ data: Data, for item: Item) -> Bool {
        // 为什么：优先使用 WhenPasscodeSetThisDeviceOnly（需设备有密码），否则回退到 AfterFirstUnlockThisDeviceOnly
        var accessible: CFTypeRef = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        #if os(iOS)
        accessible = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        #endif
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: namespaced(item.rawValue),
            kSecAttrAccessible as String: accessible,
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// 读取数据，未命中返回 nil
    public func read(item: Item) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: namespaced(item.rawValue),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// 删除指定项
    public func delete(item: Item) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: namespaced(item.rawValue)
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// 存储 6 位数字 PIN，使用随机盐 + SHA256
    /// - 为什么：避免明文存储与彩虹表攻击；重置尝试与锁定状态
    public func storePIN(_ pin: String) -> Bool {
        guard pin.count == 6, pin.allSatisfy({ $0.isNumber }) else { return false }
        let salt = randomSalt(length: 16)
        let hash: Data
        if #available(macOS 10.15, iOS 13, *) {
            hash = Self.hashPIN(pin: pin, salt: salt)
        } else {
            return false
        }
        let ok1 = store(hash, for: .pinHash)
        let ok2 = store(salt, for: .pinSalt)
        delete(item: .attemptCount)
        delete(item: .lockoutUntil)
        return ok1 && ok2
    }

    /// 验证 PIN 是否匹配
    public func validatePIN(_ pin: String) -> Bool {
        guard let hash = read(item: .pinHash), let salt = read(item: .pinSalt) else { return false }
        if #available(macOS 10.15, iOS 13, *) {
            return Self.hashPIN(pin: pin, salt: salt) == hash
        } else {
            return false
        }
    }

    /// 设置 PIN 尝试次数（用于锁定策略）
    public func setAttemptCount(_ count: Int) {
        let data = withUnsafeBytes(of: count.bigEndian) { Data($0) }
        _ = store(data, for: .attemptCount)
    }

    /// 获取 PIN 尝试次数
    public func getAttemptCount() -> Int {
        guard let data = read(item: .attemptCount), data.count == MemoryLayout<Int>.size else { return 0 }
        return data.withUnsafeBytes { $0.load(as: Int.self).bigEndian }
    }

    /// 设置手势尝试次数
    public func setGestureAttemptCount(_ count: Int) {
        let data = withUnsafeBytes(of: count.bigEndian) { Data($0) }
        _ = store(data, for: .gestureAttempts)
    }

    /// 获取手势尝试次数
    public func getGestureAttemptCount() -> Int {
        guard let data = read(item: .gestureAttempts), data.count == MemoryLayout<Int>.size else { return 0 }
        return data.withUnsafeBytes { $0.load(as: Int.self).bigEndian }
    }

    /// 设置锁定截止时间（序列化为时间戳位模式）
    public func setLockout(until: Date) {
        let interval = until.timeIntervalSince1970
        let bitPattern = interval.bitPattern
        let data = withUnsafeBytes(of: bitPattern.bigEndian) { Data($0) }
        _ = store(data, for: .lockoutUntil)
    }

    /// 读取锁定截止时间
    public func getLockoutUntil() -> Date? {
        guard let data = read(item: .lockoutUntil), data.count == MemoryLayout<UInt64>.size else { return nil }
        let bits = data.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        let interval = TimeInterval(bitPattern: bits)
        return Date(timeIntervalSince1970: interval)
    }

    /// 重置 PIN 相关项（哈希、盐、计数、锁定）
    public func resetPIN() {
        delete(item: .pinHash)
        delete(item: .pinSalt)
        delete(item: .attemptCount)
        delete(item: .lockoutUntil)
    }

    /// 存储手势序列（最少 4 点），使用随机盐 + SHA256
    public func storeGesture(_ sequence: [Int]) -> Bool {
        guard sequence.count >= 4, sequence.allSatisfy({ (0...8).contains($0) }) else { return false }
        let salt = randomSalt(length: 16)
        let hash: Data
        if #available(macOS 10.15, iOS 13, *) {
            hash = Self.hashSequence(sequence: sequence, salt: salt)
        } else {
            return false
        }
        let ok1 = store(hash, for: .gestureHash)
        let ok2 = store(salt, for: .gestureSalt)
        delete(item: .gestureAttempts)
        return ok1 && ok2
    }

    /// 验证手势序列是否匹配
    public func validateGesture(_ sequence: [Int]) -> Bool {
        guard let hash = read(item: .gestureHash), let salt = read(item: .gestureSalt) else { return false }
        if #available(macOS 10.15, iOS 13, *) {
            return Self.hashSequence(sequence: sequence, salt: salt) == hash
        } else {
            return false
        }
    }

    @available(macOS 10.15, iOS 13, *)
    /// 计算 PIN 的哈希（盐 + UTF8）
    static func hashPIN(pin: String, salt: Data) -> Data {
        let pinData = pin.data(using: .utf8)!
        var combined = Data()
        combined.reserveCapacity(salt.count + pinData.count)
        combined.append(salt)
        combined.append(pinData)
        let digest = SHA256.hash(data: combined)
        return Data(digest)
    }

    @available(macOS 10.15, iOS 13, *)
    /// 计算手势序列的哈希（盐 + 索引数组字节）
    static func hashSequence(sequence: [Int], salt: Data) -> Data {
        var combined = Data()
        combined.reserveCapacity(salt.count + sequence.count)
        combined.append(salt)
        let bytes = sequence.map { UInt8($0) }
        combined.append(Data(bytes))
        let digest = SHA256.hash(data: combined)
        return Data(digest)
    }

    /// 生成随机盐（优先 SecRandom）
    private func randomSalt(length: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        if status == errSecSuccess { return Data(bytes) }
        return Data((0..<length).map { _ in UInt8.random(in: 0...255) })
    }

    private func namespaced(_ key: String) -> String { "\(namespace).\(key)" }
}
