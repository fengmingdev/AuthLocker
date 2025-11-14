import UIKit
import AuthLockerCore

public struct LockUIFactory {
    public static func make(manager: AppLockManager = .shared,
                            style: LockStyleProvider = LockThemeManager.shared.currentStyle,
                            delegate: LockUIEventDelegate? = nil,
                            keypadLayout: KeypadLayoutProvider? = nil,
                            gridLayout: GestureGridLayoutProvider? = nil) -> UIViewController {
        switch manager.getDefaultMethod() {
        case .gesture:
            return GestureLockViewController(manager: manager, delegate: delegate, style: style, gridLayout: gridLayout)
        case .pin, .biometric:
            return LockViewController(manager: manager, delegate: delegate, style: style, keypadLayout: keypadLayout)
        }
    }

    public static func present(mode: LockUIMode,
                               options: LockUIOptions,
                               over presenter: UIViewController,
                               manager: AppLockManager = .shared,
                               keypadLayout: KeypadLayoutProvider? = nil,
                               gridLayout: GestureGridLayoutProvider? = nil) {
        switch mode {
        case .validate:
            let vc = (manager.getDefaultMethod() == .gesture)
                ? GestureLockViewController(manager: manager, delegate: options.delegate, style: options.style, gridLayout: gridLayout)
                : LockViewController(manager: manager, delegate: options.delegate, style: options.style, keypadLayout: keypadLayout, titleOverride: options.title, subtitleOverride: options.subtitle, headerImage: options.image, enableBiometricsOverride: options.enableBiometrics)
            presenter.present(vc, animated: true)
        case .createPIN:
            let vc = SetPINViewController(manager: manager, style: options.style, keypadLayout: keypadLayout, titleOverride: options.title, subtitleOverride: options.subtitle, headerImage: options.image)
            presenter.present(vc, animated: true)
        case .createGesture:
            let vc = SetGestureViewController(manager: manager, style: options.style, gridLayout: gridLayout, titleOverride: options.title, subtitleOverride: options.subtitle, headerImage: options.image)
            presenter.present(vc, animated: true)
        case .changePIN:
            let verify = VerifyPINViewController(manager: manager, style: options.style, keypadLayout: keypadLayout, onVerified: {
                let setVC = SetPINViewController(manager: manager, style: options.style, keypadLayout: keypadLayout, titleOverride: options.title, subtitleOverride: options.subtitle, headerImage: options.image)
                presenter.present(setVC, animated: true)
            }, titleOverride: options.title, subtitleOverride: options.subtitle, headerImage: options.image)
            presenter.present(verify, animated: true)
        case .changeGesture:
            let vc = SetGestureViewController(manager: manager, style: options.style, gridLayout: gridLayout, titleOverride: options.title, subtitleOverride: options.subtitle, headerImage: options.image)
            presenter.present(vc, animated: true)
        case .deactivate:
            manager.setEnabled(false)
        }
    }
}