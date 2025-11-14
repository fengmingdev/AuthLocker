import XCTest
@testable import AuthLockerCore

struct DriftTimeProvider: TimeProvider {
    let driftSeconds: TimeInterval
    func now() -> Date { Date() }
    func networkNow() -> Date? { now().addingTimeInterval(driftSeconds) }
}

final class TimeProviderTests: XCTestCase {
    func testDriftBlocksBiometric() {
        let manager = AppLockManager.shared
        manager.configure(.init(enabled: true))
        manager.setTimeProvider(DriftTimeProvider(driftSeconds: 700))
        let exp = expectation(description: "biometric")
        manager.attemptBiometricUnlock(reason: "test") { success in
            XCTAssertFalse(success)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}

