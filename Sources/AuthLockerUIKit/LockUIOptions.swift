import UIKit
import AuthLockerCore

public enum LockUIMode {
    case validate
    case createPIN
    case createGesture
    case changePIN
    case changeGesture
    case deactivate
}

public struct LockUIOptions {
    public var title: String?
    public var subtitle: String?
    public var image: UIImage?
    public var style: LockStyleProvider
    public var enableBiometrics: Bool?
    public weak var delegate: LockUIEventDelegate?
    public init(title: String? = nil,
                subtitle: String? = nil,
                image: UIImage? = nil,
                style: LockStyleProvider = LockThemeManager.shared.currentStyle,
                enableBiometrics: Bool? = nil,
                delegate: LockUIEventDelegate? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.style = style
        self.enableBiometrics = enableBiometrics
        self.delegate = delegate
    }
}