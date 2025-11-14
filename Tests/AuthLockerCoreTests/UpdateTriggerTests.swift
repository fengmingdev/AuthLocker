import XCTest
@testable import AuthLockerCore

final class UpdateTriggerTests: XCTestCase {
    func testVersionChangeLocksOnLaunch() {
        let defaults = UserDefaults.standard
        defaults.setValue("0.0-test", forKey: "authlocker.app.version")
        let manager = AppLockManager.shared
        manager.configure(.init(enabled: true, triggerInterval: .minutes(3)))
        manager.onAppLaunch()
        XCTAssertTrue(manager.requiresUnlock())
    }
}

