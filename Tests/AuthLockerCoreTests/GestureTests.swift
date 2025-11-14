import XCTest
@testable import AuthLockerCore

final class GestureTests: XCTestCase {
    func testGestureStoreAndValidate() {
        let kc = KeychainStorage()
        XCTAssertTrue(kc.storeGesture([0,1,2,4]))
        XCTAssertTrue(kc.validateGesture([0,1,2,4]))
        XCTAssertFalse(kc.validateGesture([0,1,3,4]))
    }

    func testGestureFourFailuresKeepsLocked() {
        let manager = AppLockManager.shared
        manager.configure(.init(enabled: true, defaultMethod: .gesture))
        _ = manager.setPIN("222222")
        XCTAssertTrue(KeychainStorage().storeGesture([0,4,8,7]))
        for _ in 0..<4 { XCTAssertFalse(manager.attemptUnlockWithGesture([1,2,3,4])) }
        XCTAssertTrue(manager.requiresUnlock())
    }
}

