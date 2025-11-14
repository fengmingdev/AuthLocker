import XCTest
@testable import AuthLockerCore

final class PerformanceTests: XCTestCase {
    func testPINValidationPerformance() {
        let kc = KeychainStorage()
        XCTAssertTrue(kc.storePIN("123456"))
        let start = Date()
        for _ in 0..<50 { _ = kc.validatePIN("123456") }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0)
    }

    func testManagerAttemptUnlockPerformance() {
        let m = AppLockManager.shared
        m.configure(.init(enabled: true))
        _ = m.setPIN("654321")
        let start = Date()
        for _ in 0..<50 { _ = m.attemptUnlockWithPIN("654321") }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0)
    }
}
