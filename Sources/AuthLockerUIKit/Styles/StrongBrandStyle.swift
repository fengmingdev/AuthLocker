import UIKit

public struct StrongBrandStyle: LockStyleProvider {
    public init() {}
    public var backgroundColor: UIColor { .systemGroupedBackground }
    public var primaryTintColor: UIColor { .systemIndigo }
    public var errorColor: UIColor { .systemOrange }
    public var titleFont: UIFont { UIFont.systemFont(ofSize: 22, weight: .semibold) }
    public var bodyFont: UIFont { UIFont.systemFont(ofSize: 18, weight: .medium) }
    public var captionFont: UIFont { UIFont.systemFont(ofSize: 14, weight: .regular) }
    public var spacing: CGFloat { 20 }
    public var gridSpacing: CGFloat { 28 }
    public var dotSize: CGSize { CGSize(width: 18, height: 18) }
    public var lineWidth: CGFloat { 5 }
    public var controlMinHeight: CGFloat { 48 }
    public var buttonCornerRadius: CGFloat { 14 }
    public var gesturePointSize: CGSize { CGSize(width: 50, height: 50) }
    public var gesturePointCornerRadius: CGFloat { 22 }
    public var gestureHitRadius: CGFloat { 32 }
}