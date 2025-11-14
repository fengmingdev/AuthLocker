import XCTest
@testable import AuthLockerCore

final class RiskDetectorTests: XCTestCase {
    func testBiometryDisabledOnRisk() {
        let m = AppLockManager.shared
        m.configure(.init(enabled: true))
        m.setRiskStatusForTest(.jailbroken)
        XCTAssertFalse(m.isBiometryEnabled())
    }
}

