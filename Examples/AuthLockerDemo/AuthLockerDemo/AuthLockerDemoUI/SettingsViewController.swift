#if canImport(UIKit)
import UIKit
import AuthLockerCore
import AuthLockerUIKit

public final class SettingsViewController: UIViewController {
    private var settings: AppLockSettings
    private let onReset: (() -> Void)?
    private let onViewLogs: (() -> Void)?

    private let enabledSwitch = UISwitch()
    private let methodSegment = UISegmentedControl(items: ["密码", "生物识别", "手势"])
    private let intervalSegment = UISegmentedControl(items: ["1 分钟", "3 分钟", "5 分钟", "永不"])
    private let resetButton = UIButton(type: .system)
    private let logsButton = UIButton(type: .system)
    private let changePINButton = UIButton(type: .system)
    private let changeGestureButton = UIButton(type: .system)
    private let stack = UIStackView()
    private let trustSwitch = UISwitch()
    private let trustSegment = UISegmentedControl(items: ["不信任", "7 天", "30 天"])
    private let trustStatusLabel = UILabel()
    private let retentionSegment = UISegmentedControl(items: ["7 天", "30 天", "90 天"])

    public init(settings: AppLockSettings = AppLockSettings(), onReset: (() -> Void)? = nil, onViewLogs: (() -> Void)? = nil) {
        self.settings = settings
        self.onReset = onReset
        self.onViewLogs = onViewLogs
        super.init(nibName: nil, bundle: nil)
        title = Localizer.text("settings.title")
    }

    required init?(coder: NSCoder) { return nil }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        refresh()
    }

    private func setupUI() {
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let enabledRow = makeRow(title: Localizer.text("settings.enabled"), control: enabledSwitch)
        enabledSwitch.addTarget(self, action: #selector(onEnabledChanged), for: .valueChanged)
        enabledSwitch.isAccessibilityElement = true
        enabledSwitch.accessibilityLabel = "开启应用锁"
        stack.addArrangedSubview(enabledRow)

        let methodRow = makeRow(title: Localizer.text("settings.method"), control: methodSegment)
        methodSegment.addTarget(self, action: #selector(onMethodChanged), for: .valueChanged)
        methodSegment.isAccessibilityElement = true
        methodSegment.accessibilityLabel = "默认解锁方式"
        stack.addArrangedSubview(methodRow)

        let intervalRow = makeRow(title: Localizer.text("settings.interval"), control: intervalSegment)
        intervalSegment.addTarget(self, action: #selector(onIntervalChanged), for: .valueChanged)
        intervalSegment.isAccessibilityElement = true
        intervalSegment.accessibilityLabel = "后台触发时长"
        stack.addArrangedSubview(intervalRow)

        let trustEnableRow = makeRow(title: Localizer.text("settings.trustEnabled"), control: trustSwitch)
        trustSwitch.addTarget(self, action: #selector(onTrustEnabledChanged), for: .valueChanged)
        trustSwitch.isAccessibilityElement = true
        trustSwitch.accessibilityLabel = "信任设备开关"
        stack.addArrangedSubview(trustEnableRow)

        let trustDaysRow = makeRow(title: Localizer.text("settings.trustDays"), control: trustSegment)
        trustSegment.addTarget(self, action: #selector(onTrustDaysChanged), for: .valueChanged)
        trustSegment.isAccessibilityElement = true
        trustSegment.accessibilityLabel = "信任天数"
        stack.addArrangedSubview(trustDaysRow)

        trustStatusLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        trustStatusLabel.adjustsFontForContentSizeCategory = true
        stack.addArrangedSubview(trustStatusLabel)

        let retentionRow = makeRow(title: Localizer.text("settings.logsRetention"), control: retentionSegment)
        retentionSegment.addTarget(self, action: #selector(onRetentionChanged), for: .valueChanged)
        retentionSegment.isAccessibilityElement = true
        retentionSegment.accessibilityLabel = "日志保留天数"
        stack.addArrangedSubview(retentionRow)

        resetButton.setTitle(Localizer.text("settings.reset"), for: .normal)
        resetButton.addTarget(self, action: #selector(onResetTap), for: .touchUpInside)
        resetButton.titleLabel?.adjustsFontForContentSizeCategory = true
        resetButton.isAccessibilityElement = true
        resetButton.accessibilityLabel = "重置应用锁"
        stack.addArrangedSubview(resetButton)

        changePINButton.setTitle("更改应用锁密码", for: .normal)
        changePINButton.addTarget(self, action: #selector(onChangePinTap), for: .touchUpInside)
        changePINButton.titleLabel?.adjustsFontForContentSizeCategory = true
        changePINButton.isAccessibilityElement = true
        changePINButton.accessibilityLabel = "更改应用锁密码"
        stack.addArrangedSubview(changePINButton)

        changeGestureButton.setTitle("更改手势应用锁", for: .normal)
        changeGestureButton.addTarget(self, action: #selector(onChangeGestureTap), for: .touchUpInside)
        changeGestureButton.titleLabel?.adjustsFontForContentSizeCategory = true
        changeGestureButton.isAccessibilityElement = true
        changeGestureButton.accessibilityLabel = "更改手势应用锁"
        stack.addArrangedSubview(changeGestureButton)

        logsButton.setTitle(Localizer.text("settings.logs"), for: .normal)
        logsButton.addTarget(self, action: #selector(onViewLogsTap), for: .touchUpInside)
        logsButton.titleLabel?.adjustsFontForContentSizeCategory = true
        logsButton.isAccessibilityElement = true
        logsButton.accessibilityLabel = "查看安全日志"
        stack.addArrangedSubview(logsButton)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func makeRow(title: String, control: UIView) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.distribution = .fill
        let label = UILabel()
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        control.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        container.addArrangedSubview(label)
        container.addArrangedSubview(control)
        return container
    }

    private func refresh() {
        enabledSwitch.isOn = settings.enabled
        switch settings.defaultMethod {
        case .pin: methodSegment.selectedSegmentIndex = 0
        case .biometric: methodSegment.selectedSegmentIndex = 1
        case .gesture: methodSegment.selectedSegmentIndex = 2
        }
        switch settings.triggerInterval {
        case .minutes(1): intervalSegment.selectedSegmentIndex = 0
        case .minutes(3): intervalSegment.selectedSegmentIndex = 1
        case .minutes(5): intervalSegment.selectedSegmentIndex = 2
        case .never: intervalSegment.selectedSegmentIndex = 3
        default: intervalSegment.selectedSegmentIndex = 1
        }
        trustSwitch.isOn = AppLockManager.shared.isTrustEnabled()
        trustSegment.isEnabled = trustSwitch.isOn
        updateTrustStatus()
        let rd = SecurityLogger.shared.getRetentionDays()
        retentionSegment.selectedSegmentIndex = (rd <= 7 ? 0 : (rd <= 30 ? 1 : 2))
    }

    @objc private func onEnabledChanged() { settings.enabled = enabledSwitch.isOn }

    @objc private func onMethodChanged() {
        let idx = methodSegment.selectedSegmentIndex
        let m: AppLockManager.UnlockMethod = (idx == 0 ? .pin : (idx == 1 ? .biometric : .gesture))
        settings.defaultMethod = m
        switch m {
        case .gesture:
            if !AppLockManager.shared.hasGestureConfigured() {
                let opts = LockUIOptions(style: LockThemeManager.shared.currentStyle)
                LockUIFactory.present(mode: .createGesture, options: opts, over: self, manager: AppLockManager.shared)
            }
        case .pin:
            if !AppLockManager.shared.hasPINConfigured() {
                let opts = LockUIOptions(style: LockThemeManager.shared.currentStyle)
                LockUIFactory.present(mode: .createPIN, options: opts, over: self, manager: AppLockManager.shared)
            }
        case .biometric:
            break
        }
    }

    @objc private func onIntervalChanged() {
        let idx = intervalSegment.selectedSegmentIndex
        let iv: BackgroundTriggerInterval = (idx == 0 ? .minutes(1) : (idx == 1 ? .minutes(3) : (idx == 2 ? .minutes(5) : .never)))
        settings.triggerInterval = iv
    }

    @objc private func onResetTap() { onReset?() }

    @objc private func onChangePinTap() {
        let verify = VerifyPINViewController(manager: AppLockManager.shared, style: LockThemeManager.shared.currentStyle) {
            let setVC = SetPINViewController(manager: AppLockManager.shared, style: LockThemeManager.shared.currentStyle)
            self.present(setVC, animated: true)
        }
        present(verify, animated: true)
    }

    @objc private func onChangeGestureTap() {
        let vc = SetGestureViewController(manager: AppLockManager.shared, style: LockThemeManager.shared.currentStyle)
        present(vc, animated: true)
    }

    @objc private func onViewLogsTap() { onViewLogs?() }

    @objc private func onTrustEnabledChanged() {
        let enabled = trustSwitch.isOn
        AppLockManager.shared.setTrustEnabled(enabled)
        trustSegment.isEnabled = enabled
        updateTrustStatus()
    }

    @objc private func onTrustDaysChanged() {
        guard AppLockManager.shared.isTrustEnabled() else { return }
        let idx = trustSegment.selectedSegmentIndex
        if idx == 0 { AppLockManager.shared.clearTrusted() }
        else if idx == 1 { AppLockManager.shared.setTrustedDays(7) }
        else { AppLockManager.shared.setTrustedDays(30) }
        updateTrustStatus()
    }

    private func updateTrustStatus() {
        trustStatusLabel.text = AppLockManager.shared.isTrustedActive() ? Localizer.text("settings.trustActive") : Localizer.text("settings.trustInactive")
    }

    @objc private func onRetentionChanged() {
        let idx = retentionSegment.selectedSegmentIndex
        let days = (idx == 0 ? 7 : (idx == 1 ? 30 : 90))
        SecurityLogger.shared.setRetentionDays(days)
    }
}
#endif
