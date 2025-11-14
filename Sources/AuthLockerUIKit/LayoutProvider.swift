import UIKit

public enum KeypadItem {
    case number(Int)
    case delete
    case submit
    case spacer
}

public protocol KeypadLayoutProvider {
    var rows: [[KeypadItem]] { get }
    var rowSpacing: CGFloat { get }
    func makeButton(for item: KeypadItem, target: Any, action: Selector) -> UIButton?
}

public struct DefaultKeypadLayoutProvider: KeypadLayoutProvider {
    private let style: LockStyleProvider
    public init(style: LockStyleProvider) { self.style = style }
    public var rows: [[KeypadItem]] {
        [[.number(1), .number(2), .number(3)],
         [.number(4), .number(5), .number(6)],
         [.number(7), .number(8), .number(9)],
         [.delete, .number(0), .submit]]
    }
    public var rowSpacing: CGFloat { style.spacing }
    public func makeButton(for item: KeypadItem, target: Any, action: Selector) -> UIButton? {
        switch item {
        case .number(let n):
            let btn = UIButton(type: .system)
            btn.setTitle("\(n)", for: .normal)
            btn.titleLabel?.font = style.bodyFont
            btn.titleLabel?.adjustsFontForContentSizeCategory = true
            btn.isAccessibilityElement = true
            btn.accessibilityLabel = "数字 \(n)"
            btn.tag = n
            btn.addTarget(target, action: action, for: .touchUpInside)
            btn.backgroundColor = style.primaryTintColor.withAlphaComponent(0.08)
            btn.layer.cornerRadius = style.buttonCornerRadius
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: style.controlMinHeight).isActive = true
            return btn
        case .delete:
            let btn = UIButton(type: .system)
            btn.setImage(UIImage(systemName: "delete.left"), for: .normal)
            btn.isAccessibilityElement = true
            btn.accessibilityLabel = "删除"
            btn.addTarget(target, action: action, for: .touchUpInside)
            btn.backgroundColor = style.primaryTintColor.withAlphaComponent(0.08)
            btn.layer.cornerRadius = style.buttonCornerRadius
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: style.controlMinHeight).isActive = true
            return btn
        case .submit:
            let btn = UIButton(type: .system)
            btn.setImage(UIImage(systemName: "checkmark"), for: .normal)
            btn.isAccessibilityElement = true
            btn.accessibilityLabel = "提交"
            btn.addTarget(target, action: action, for: .touchUpInside)
            btn.backgroundColor = style.primaryTintColor.withAlphaComponent(0.08)
            btn.layer.cornerRadius = style.buttonCornerRadius
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: style.controlMinHeight).isActive = true
            return btn
        case .spacer:
            return nil
        }
    }
}

public protocol GestureGridLayoutProvider {
    var rows: Int { get }
    var columns: Int { get }
    var gridSpacing: CGFloat { get }
    var pointSize: CGSize { get }
}

public struct DefaultGestureGridLayoutProvider: GestureGridLayoutProvider {
    private let style: LockStyleProvider
    public init(style: LockStyleProvider) { self.style = style }
    public var rows: Int { 3 }
    public var columns: Int { 3 }
    public var gridSpacing: CGFloat { style.gridSpacing }
    public var pointSize: CGSize { style.gesturePointSize }
}