import UIKit

public protocol LockStyleProvider {
    var backgroundColor: UIColor { get }
    var primaryTintColor: UIColor { get }
    var errorColor: UIColor { get }
    var titleFont: UIFont { get }
    var bodyFont: UIFont { get }
    var captionFont: UIFont { get }
    var spacing: CGFloat { get }
    var gridSpacing: CGFloat { get }
    var dotSize: CGSize { get }
    var lineWidth: CGFloat { get }
    var controlMinHeight: CGFloat { get }
    var buttonCornerRadius: CGFloat { get }
    var gesturePointSize: CGSize { get }
    var gesturePointCornerRadius: CGFloat { get }
    var gestureHitRadius: CGFloat { get }
}

public struct DefaultLockStyle: LockStyleProvider {
    public init() {}
    public var backgroundColor: UIColor { .systemBackground }
    public var primaryTintColor: UIColor { .systemBlue }
    public var errorColor: UIColor { .systemRed }
    public var titleFont: UIFont { UIFont.preferredFont(forTextStyle: .headline) }
    public var bodyFont: UIFont { UIFont.preferredFont(forTextStyle: .body) }
    public var captionFont: UIFont { UIFont.preferredFont(forTextStyle: .subheadline) }
    public var spacing: CGFloat { 16 }
    public var gridSpacing: CGFloat { 24 }
    public var dotSize: CGSize { CGSize(width: 16, height: 16) }
    public var lineWidth: CGFloat { 4 }
    public var controlMinHeight: CGFloat { 44 }
    public var buttonCornerRadius: CGFloat { 10 }
    public var gesturePointSize: CGSize { CGSize(width: 44, height: 44) }
    public var gesturePointCornerRadius: CGFloat { 20 }
    public var gestureHitRadius: CGFloat { 30 }
}