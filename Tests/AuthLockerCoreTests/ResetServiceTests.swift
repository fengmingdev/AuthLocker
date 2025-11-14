import XCTest
@testable import AuthLockerCore

final class MockResetService: LockResetService {
    var ok = true
    func requestVerificationCode(toPhone phone: String, completion: @escaping (Bool) -> Void) { completion(ok) }
    func verifyCode(_ code: String, completion: @escaping (Bool) -> Void) { completion(ok && code == "123456") }
}

final class ResetServiceTests: XCTestCase {
    func testResetFlowSuccess() {
        let manager = AppLockManager.shared
        manager.configure(.init(enabled: true))
        let svc = MockResetService()
        manager.setResetService(svc)
        let e1 = expectation(description: "request")
        manager.startPINReset(toPhone: "13800000000") { ok in
            XCTAssertTrue(ok)
            e1.fulfill()
        }
        wait(for: [e1], timeout: 1.0)
        let e2 = expectation(description: "verify")
        manager.completePINReset(code: "123456", newPIN: "111111") { ok in
            XCTAssertTrue(ok)
            e2.fulfill()
        }
        wait(for: [e2], timeout: 1.0)
        XCTAssertTrue(manager.attemptUnlockWithPIN("111111"))
    }
}

