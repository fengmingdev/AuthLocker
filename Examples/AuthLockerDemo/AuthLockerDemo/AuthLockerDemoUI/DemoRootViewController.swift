#if canImport(UIKit)
import UIKit
import AuthLockerCore
import AuthLockerUIKit

public final class DemoRootViewController: UIViewController, LockUIEventDelegate {
    private let manager = AppLockManager.shared
    private let monitor = DeviceLockMonitor()
    private let stack = UIStackView()
    private let lockButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let logsButton = UIButton(type: .system)
    private let themeSegment = UISegmentedControl(items: ["Minimal", "StrongBrand"])

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "AuthLocker Demo"
        view.backgroundColor = .systemBackground
        setupUI()
        setupLifecycle()
        manager.configure(.init(enabled: true, triggerInterval: .minutes(3), defaultMethod: .pin, accountID: "demo", trustEnabled: false))
        _ = manager.setPIN("123456")
        manager.onAppLaunch()
        monitor.start()
    }

    private func setupUI() {
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        lockButton.setTitle("打开锁界面", for: .normal)
        lockButton.addTarget(self, action: #selector(onOpenLock), for: .touchUpInside)
        settingsButton.setTitle("打开设置", for: .normal)
        settingsButton.addTarget(self, action: #selector(onOpenSettings), for: .touchUpInside)
        logsButton.setTitle("查看日志", for: .normal)
        logsButton.addTarget(self, action: #selector(onOpenLogs), for: .touchUpInside)

        [lockButton, settingsButton, logsButton].forEach { b in
            b.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
            b.titleLabel?.adjustsFontForContentSizeCategory = true
            stack.addArrangedSubview(b)
        }
        themeSegment.selectedSegmentIndex = 0
        themeSegment.addTarget(self, action: #selector(onThemeChanged), for: .valueChanged)
        stack.addArrangedSubview(themeSegment)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupLifecycle() {
        NotificationCenter.default.addObserver(self, selector: #selector(onDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func onDidEnterBackground() { manager.onEnterBackground() }
    @objc private func onWillEnterForeground() { manager.onEnterForeground() }

    @objc private func onOpenLock() {
        let opts = LockUIOptions(title: "AuthLocker 验证", style: LockThemeManager.shared.currentStyle, enableBiometrics: true, delegate: self)
        LockUIFactory.present(mode: .validate, options: opts, over: self, manager: manager)
    }

    @objc private func onThemeChanged() {
        if themeSegment.selectedSegmentIndex == 0 {
            LockThemeManager.shared.setStyle(MinimalStyle())
        } else {
            LockThemeManager.shared.setStyle(StrongBrandStyle())
        }
    }

    @objc private func onOpenSettings() {
        let vc = SettingsViewController(onReset: { [weak self] in
            guard let self = self else { return }
            let reset = ResetPINViewController(manager: self.manager)
            self.present(reset, animated: true)
        }, onViewLogs: { [weak self] in
            self?.onOpenLogs()
        })
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func onOpenLogs() {
        let vc = LogsViewController(style: .plain)
        navigationController?.pushViewController(vc, animated: true)
    }

    deinit { monitor.stop() }

    public static func makeDemoRoot() -> UINavigationController {
        let root = DemoRootViewController()
        return UINavigationController(rootViewController: root)
    }

    public func didRequestPINReset() {
        let reset = ResetPINViewController(manager: manager)
        present(reset, animated: true)
    }
    public func didRequestSwitchToPIN() {
        let pinVC = LockUIFactory.make(manager: manager, style: LockThemeManager.shared.currentStyle, delegate: self)
        present(pinVC, animated: true)
    }
    public func didUnlockSuccess(method: AppLockManager.UnlockMethod) {}
    public func didUnlockFailure(method: AppLockManager.UnlockMethod) {}
}
#endif
