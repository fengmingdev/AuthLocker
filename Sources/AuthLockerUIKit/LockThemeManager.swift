import UIKit

public final class LockThemeManager {
    public static let shared = LockThemeManager()
    private(set) public var currentStyle: LockStyleProvider = MinimalStyle()
    private init() {}
    public func setStyle(_ style: LockStyleProvider) { currentStyle = style }
}