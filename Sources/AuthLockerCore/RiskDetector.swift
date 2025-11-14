import Foundation
#if os(iOS)
import Darwin
#endif

/// 风险状态：正常、越狱、篡改
public enum RiskStatus: Equatable {
    case safe
    case jailbroken
    case tampered
}

/// 风险检测器
/// - 为什么：在风险环境下收敛解锁能力（禁用生物识别），降低绕过概率
public struct RiskDetector {
    public init() {}
    public func evaluate() -> RiskStatus {
        if isJailbroken() { return .jailbroken }
        if hasInjection() { return .tampered }
        if isDebuggerAttached() { return .tampered }
        return .safe
    }

    private func isJailbroken() -> Bool {
        let suspicious = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/bin/bash"
        ]
        for p in suspicious {
            if FileManager.default.fileExists(atPath: p) { return true }
        }
        let testPath = "/private/authlocker_jb_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {}
        return false
    }

    private func hasInjection() -> Bool {
        let env = ProcessInfo.processInfo.environment
        if env["DYLD_INSERT_LIBRARIES"] != nil { return true }
        return false
    }

    private func isDebuggerAttached() -> Bool {
        #if canImport(Darwin)
        // 为什么：被调试可能用于策略绕过，检测 P_TRACED 标记以降级能力
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let result = name.withUnsafeMutableBufferPointer { ptr -> Int32 in
            return sysctl(ptr.baseAddress, 4, &info, &size, nil, 0)
        }
        if result == 0 {
            return (info.kp_proc.p_flag & P_TRACED) != 0
        }
        #endif
        return false
    }
}
