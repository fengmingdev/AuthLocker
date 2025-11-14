#if canImport(UIKit)
import UIKit
import AuthLockerCore

/// 设备锁屏监控器：监听受保护数据不可用事件
@available(iOS 13.0, *)
public final class DeviceLockMonitor {
    private var tokens: [NSObjectProtocol] = []
    private let center: NotificationCenter
    private let manager: AppLockManager

    public init(center: NotificationCenter = .default, manager: AppLockManager = .shared) {
        self.center = center
        self.manager = manager
    }

    public func start() {
        let protectedName = Notification.Name("UIApplicationProtectedDataWillBecomeUnavailable")
        let t1 = center.addObserver(forName: protectedName, object: nil, queue: .main) { [weak self] _ in
            self?.manager.onDeviceLock()
        }
        tokens.append(t1)
    }

    public func stop() {
        for t in tokens { center.removeObserver(t) }
        tokens.removeAll()
    }
}
#endif
