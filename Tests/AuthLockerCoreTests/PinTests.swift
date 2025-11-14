import XCTest
@testable import AuthLockerCore

final class PinTests: XCTestCase {
    func testPinStoreAndValidate() {
        let kc = KeychainStorage()
        XCTAssertTrue(kc.storePIN("123456"))
        XCTAssertTrue(kc.validatePIN("123456"))
        XCTAssertFalse(kc.validatePIN("000000"))
    }

    func testLockoutAfterFiveFailures() {
        let manager = AppLockManager.shared
        manager.configure(.init(enabled: true))
        _ = manager.setPIN("654321")
        for _ in 0..<5 { XCTAssertFalse(manager.attemptUnlockWithPIN("000000")) }
        switch manager.currentState() {
        case .lockedOut(let until):
            XCTAssertGreaterThan(until, Date())
        default:
            XCTFail("Expected lockedOut state")
        }
    }
}
