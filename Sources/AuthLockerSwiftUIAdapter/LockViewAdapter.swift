#if canImport(UIKit)
import SwiftUI
import AuthLockerCore
import AuthLockerUIKit

/// SwiftUI 适配：封装 PIN 解锁 UIKit 控制器
public struct LockViewAdapter: UIViewControllerRepresentable {
    private let manager: AppLockManager
    private let style: LockStyleProvider
    private let keypadLayout: KeypadLayoutProvider?
    private let gridLayout: GestureGridLayoutProvider?

    public init(manager: AppLockManager = .shared, style: LockStyleProvider = LockThemeManager.shared.currentStyle, keypadLayout: KeypadLayoutProvider? = nil, gridLayout: GestureGridLayoutProvider? = nil) {
        self.manager = manager
        self.style = style
        self.keypadLayout = keypadLayout
        self.gridLayout = gridLayout
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        let nav = UINavigationController()
        let root = LockUIFactory.make(manager: manager, style: style, delegate: nil, keypadLayout: keypadLayout, gridLayout: gridLayout)
        nav.viewControllers = [root]
        return nav
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#endif
