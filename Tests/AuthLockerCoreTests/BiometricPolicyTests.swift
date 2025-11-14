import XCTest
@testable import AuthLockerCore

final class BiometricPolicyTests: XCTestCase {
    func testFaceIDSuggestsAfterTwoFailures() {
        let m = AppLockManager.shared
        m.configure(.init(enabled: true))
        m.setBiometryKindForTest(.faceID)
        m.simulateBiometricFailureForTest()
        XCTAssertFalse(m.shouldSuggestPINAfterBiometricFailure())
        m.simulateBiometricFailureForTest()
        XCTAssertTrue(m.shouldSuggestPINAfterBiometricFailure())
    }

    func testTouchIDSuggestsAfterThreeFailures() {
        let m = AppLockManager.shared
        m.configure(.init(enabled: true))
        m.setBiometryKindForTest(.touchID)
        m.simulateBiometricFailureForTest()
        XCTAssertFalse(m.shouldSuggestPINAfterBiometricFailure())
        m.simulateBiometricFailureForTest()
        XCTAssertFalse(m.shouldSuggestPINAfterBiometricFailure())
        m.simulateBiometricFailureForTest()
        XCTAssertTrue(m.shouldSuggestPINAfterBiometricFailure())
    }
}

