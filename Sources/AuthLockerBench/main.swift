import Foundation
import AuthLockerCore

func measure(_ label: String, _ block: () -> Void) -> Double {
    let s = Date()
    block()
    let e = Date().timeIntervalSince(s)
    print("\(label): \(String(format: "%.3f", e))s")
    return e
}

let manager = AppLockManager.shared
manager.configure(.init(enabled: true))
_ = manager.setPIN("654321")

let kc = KeychainStorage()
_ = kc.storePIN("123456")

measure("PIN validate x200") {
    for _ in 0..<200 { _ = kc.validatePIN("123456") }
}

measure("Manager unlock x100") {
    for _ in 0..<100 { _ = manager.attemptUnlockWithPIN("654321") }
}

let logger = SecurityLogger.shared
measure("Logger record x100") {
    for i in 0..<100 { logger.record(SecurityEvent(kind: .unlockFailure, details: "bench_\(i)")) }
}

let gesture = [0,1,2,4,7]
_ = kc.storeGesture(gesture)
measure("Gesture validate x200") {
    for _ in 0..<200 { _ = kc.validateGesture(gesture) }
}

print("Benchmark completed")

