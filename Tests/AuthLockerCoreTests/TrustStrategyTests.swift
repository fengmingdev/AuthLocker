import XCTest
@testable import AuthLockerCore

final class TrustStrategyTests: XCTestCase {
    func testTrustEnablesUnlockAndClears() {
        let m = AppLockManager.shared
        m.configure(.init(enabled: true, triggerInterval: .minutes(1), defaultMethod: .pin, accountID: "t", trustEnabled: true))
        _ = m.setPIN("123456")
        m.setTrustedDays(1)
        XCTAssertTrue(m.isTrustEnabled())
        XCTAssertTrue(m.isTrustedActive())
        XCTAssertEqual(m.currentState(), .unlocked)
        m.clearTrusted()
        XCTAssertFalse(m.isTrustedActive())
    }
}
