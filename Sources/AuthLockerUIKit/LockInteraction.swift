import UIKit
import AuthLockerCore

public protocol LockUIEventDelegate: AnyObject {
    func didRequestPINReset()
    func didRequestSwitchToPIN()
    func didUnlockSuccess(method: AppLockManager.UnlockMethod)
    func didUnlockFailure(method: AppLockManager.UnlockMethod)
}