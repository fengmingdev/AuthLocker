#if canImport(UIKit)
import UIKit
import AuthLockerCore

/// PIN 解锁界面（UIKit）
public final class LockViewController: UIViewController {
    private let manager: AppLockManager
    private weak var delegate: LockUIEventDelegate?
    private let style: LockStyleProvider
    private let keypadLayout: KeypadLayoutProvider
    private let titleOverride: String?
    private let subtitleOverride: String?
    private let headerImage: UIImage?
    private let enableBiometricsOverride: Bool?
    private let headerImageView = UIImageView()
    private let subtitleLabel = UILabel()
    private var digits: [Int] = []
    private let titleLabel = UILabel()
    private let dotsStack = UIStackView()
    private let errorLabel = UILabel()
    private let keypadStack = UIStackView()
    private let forgotButton = UIButton(type: .system)
    private let biometricButton = UIButton(type: .system)
    private var shieldView: UIVisualEffectView?

    public init(manager: AppLockManager = .shared, delegate: LockUIEventDelegate? = nil, style: LockStyleProvider = DefaultLockStyle(), keypadLayout: KeypadLayoutProvider? = nil, titleOverride: String? = nil, subtitleOverride: String? = nil, headerImage: UIImage? = nil, enableBiometricsOverride: Bool? = nil) {
        self.manager = manager
        self.delegate = delegate
        self.style = style
        self.keypadLayout = keypadLayout ?? DefaultKeypadLayoutProvider(style: style)
        self.titleOverride = titleOverride
        self.subtitleOverride = subtitleOverride
        self.headerImage = headerImage
        self.enableBiometricsOverride = enableBiometricsOverride
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { return nil }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = style.backgroundColor
        view.tintColor = style.primaryTintColor
        setupUI()
        updateLockoutIfNeeded()
    }

    private func setupUI() {
        setupHeader()
        setupDots()
        setupError()
        setupKeypad()
        setupButtons()
        setupConstraints()
        refreshDots()
        updateBiometricVisibility()
        setupAccessibility()
        registerObservers()
    }

    private func setupHeader() {
        titleLabel.text = titleOverride ?? Localizer.text("lock.title")
        titleLabel.font = style.titleFont
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        if let img = headerImage {
            headerImageView.image = img
            headerImageView.translatesAutoresizingMaskIntoConstraints = false
            headerImageView.contentMode = .scaleAspectFit
            view.addSubview(headerImageView)
        }
        if let sub = subtitleOverride {
            subtitleLabel.text = sub
            subtitleLabel.font = style.captionFont
            subtitleLabel.adjustsFontForContentSizeCategory = true
            subtitleLabel.textColor = .secondaryLabel
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subtitleLabel)
        }
    }

    private func setupDots() {
        dotsStack.axis = .horizontal
        dotsStack.spacing = style.spacing
        dotsStack.translatesAutoresizingMaskIntoConstraints = false
        for _ in 0..<6 { dotsStack.addArrangedSubview(makeDot()) }
        view.addSubview(dotsStack)
    }

    private func setupError() {
        errorLabel.textColor = style.errorColor
        errorLabel.font = style.captionFont
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.numberOfLines = 0
        view.addSubview(errorLabel)
    }

    private func setupKeypad() {
        keypadStack.axis = .vertical
        keypadStack.spacing = style.spacing
        keypadStack.translatesAutoresizingMaskIntoConstraints = false
        for items in keypadLayout.rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = keypadLayout.rowSpacing
            row.distribution = .fillEqually
            for item in items {
                if let btn = keypadLayout.makeButton(for: item, target: self, action: selector(for: item)) {
                    row.addArrangedSubview(btn)
                } else {
                    let v = UIView()
                    row.addArrangedSubview(v)
                }
            }
            keypadStack.addArrangedSubview(row)
        }
        view.addSubview(keypadStack)
    }

    private func setupButtons() {
        forgotButton.setTitle(Localizer.text("lock.forget"), for: .normal)
        forgotButton.addTarget(self, action: #selector(onForgot), for: .touchUpInside)
        forgotButton.titleLabel?.font = style.bodyFont
        forgotButton.titleLabel?.adjustsFontForContentSizeCategory = true
        forgotButton.isAccessibilityElement = true
        forgotButton.accessibilityLabel = Localizer.text("lock.forget")
        forgotButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(forgotButton)

        biometricButton.setTitle(Localizer.text("lock.biometric"), for: .normal)
        biometricButton.addTarget(self, action: #selector(onBiometric), for: .touchUpInside)
        biometricButton.titleLabel?.font = style.bodyFont
        biometricButton.titleLabel?.adjustsFontForContentSizeCategory = true
        biometricButton.isAccessibilityElement = true
        biometricButton.accessibilityLabel = Localizer.text("lock.biometric")
        biometricButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(biometricButton)
    }

    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = []
        if headerImageView.superview != nil {
            constraints += [
                headerImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
                headerImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                headerImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
                headerImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 120)
            ]
        }
        let titleTopAnchor = headerImageView.superview != nil ? headerImageView.bottomAnchor : view.safeAreaLayoutGuide.topAnchor
        constraints += [
            titleLabel.topAnchor.constraint(equalTo: titleTopAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ]
        if subtitleLabel.superview != nil {
            constraints += [
                subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
                subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ]
        }
        let dotsTopAnchor = subtitleLabel.superview != nil ? subtitleLabel.bottomAnchor : titleLabel.bottomAnchor
        constraints += [
            dotsStack.topAnchor.constraint(equalTo: dotsTopAnchor, constant: style.spacing),
            dotsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            errorLabel.topAnchor.constraint(equalTo: dotsStack.bottomAnchor, constant: 12),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            keypadStack.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
            keypadStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            keypadStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            forgotButton.topAnchor.constraint(equalTo: keypadStack.bottomAnchor, constant: 16),
            forgotButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            biometricButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            biometricButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func makeDot() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 8
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.cgColor
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: style.dotSize.width),
            v.heightAnchor.constraint(equalToConstant: style.dotSize.height)
        ])
        return v
    }

    private func makeNumberButton(_ n: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("\(n)", for: .normal)
        btn.titleLabel?.font = style.bodyFont
        btn.titleLabel?.adjustsFontForContentSizeCategory = true
        btn.isAccessibilityElement = true
        btn.accessibilityLabel = "数字 \(n)"
        btn.addTarget(self, action: #selector(onDigit(_:)), for: .touchUpInside)
        btn.tag = n
        btn.backgroundColor = style.primaryTintColor.withAlphaComponent(0.08)
        btn.layer.cornerRadius = style.buttonCornerRadius
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(greaterThanOrEqualToConstant: style.controlMinHeight).isActive = true
        return btn
    }

    private func makeDeleteButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "delete.left"), for: .normal)
        btn.addTarget(self, action: #selector(onDelete), for: .touchUpInside)
        btn.isAccessibilityElement = true
        btn.accessibilityLabel = "删除"
        btn.backgroundColor = style.primaryTintColor.withAlphaComponent(0.08)
        btn.layer.cornerRadius = style.buttonCornerRadius
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(greaterThanOrEqualToConstant: style.controlMinHeight).isActive = true
        return btn
    }

    private func makeSubmitButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "checkmark"), for: .normal)
        btn.addTarget(self, action: #selector(onSubmit), for: .touchUpInside)
        btn.isAccessibilityElement = true
        btn.accessibilityLabel = "提交"
        btn.backgroundColor = style.primaryTintColor.withAlphaComponent(0.08)
        btn.layer.cornerRadius = style.buttonCornerRadius
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(greaterThanOrEqualToConstant: style.controlMinHeight).isActive = true
        return btn
    }

    @objc private func onDigit(_ sender: UIButton) {
        switch manager.currentState() {
        case .lockedOut: return
        default: break
        }
        if digits.count < 6 { digits.append(sender.tag) }
        UISelectionFeedbackGenerator().selectionChanged()
        refreshDots()
        if digits.count == 6 { submit() }
    }

    @objc private func onDelete() {
        if !digits.isEmpty { digits.removeLast() }
        refreshDots()
    }

    @objc private func onSubmit() { submit() }

    @objc private func onForgot() { delegate?.didRequestPINReset() }

    private func refreshDots() {
        for (idx, v) in dotsStack.arrangedSubviews.enumerated() {
            v.backgroundColor = idx < digits.count ? style.primaryTintColor : .clear
        }
        dotsStack.isAccessibilityElement = true
        dotsStack.accessibilityLabel = Localizer.text("lock.input.count")
    }

    private func submit() {
        guard digits.count == 6 else { return }
        let pin = digits.map(String.init).joined()
        if manager.attemptUnlockWithPIN(pin) {
            errorLabel.text = nil
            digits.removeAll()
            refreshDots()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            delegate?.didUnlockSuccess(method: .pin)
            dismiss(animated: true)
        } else {
            switch manager.currentState() {
            case .lockedOut(let until):
                let minutes = max(Int(until.timeIntervalSince(Date()) / 60), 1)
                errorLabel.text = String(format: Localizer.text("lock.error.many"), minutes)
            default:
                errorLabel.text = "密码不匹配，请重试"
                digits.removeAll()
                refreshDots()
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                let anim = CABasicAnimation(keyPath: "position.x")
                anim.byValue = 8
                anim.duration = 0.06
                anim.autoreverses = true
                anim.repeatCount = 2
                errorLabel.layer.add(anim, forKey: "shake")
                delegate?.didUnlockFailure(method: .pin)
            }
        }
    }

    private func selector(for item: KeypadItem) -> Selector {
        switch item {
        case .number: return #selector(onDigit(_:))
        case .delete: return #selector(onDelete)
        case .submit: return #selector(onSubmit)
        case .spacer: return #selector(onSubmit)
        }
    }

    private func updateLockoutIfNeeded() {
        switch manager.currentState() {
        case .lockedOut:
            errorLabel.text = Localizer.text("lock.error.locked")
        default:
            errorLabel.text = nil
        }
    }

    @objc private func onBiometric() {
        manager.attemptBiometricUnlock(reason: Localizer.text("lock.biometric")) { success in
            if success {
                self.errorLabel.text = nil
                self.dismiss(animated: true)
            } else {
                if self.manager.shouldSuggestPINAfterBiometricFailure() {
                    self.errorLabel.text = Localizer.text("lock.error.bioUsePin")
                    self.biometricButton.isHidden = true
                } else {
                    self.errorLabel.text = Localizer.text("lock.error.bioRetry")
                }
            }
        }
    }

    private func updateBiometricVisibility() {
        let enabled = manager.isBiometryEnabled()
        if let override = enableBiometricsOverride {
            biometricButton.isHidden = !(enabled && override)
        } else {
            biometricButton.isHidden = !enabled
        }
    }

    private func setupAccessibility() {
        view.accessibilityLabel = "应用锁验证界面"
        view.isAccessibilityElement = false
    }

    private func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(onBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        if #available(iOS 11.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(onCaptureChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(onScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        updateShield()
    }

    @objc private func onBackground() { digits.removeAll(); refreshDots() }

    @objc private func onCaptureChanged() { updateShield() }
    @objc private func onScreenshot() { showShield() }

    private func updateShield() {
        // 为什么：录屏时自动遮蔽界面，避免敏感信息泄露
        if #available(iOS 11.0, *) {
            UIScreen.main.isCaptured ? showShield() : hideShield()
        }
    }

    private func showShield() {
        guard shieldView == nil else { return }
        let blur = UIBlurEffect(style: .systemThinMaterial)
        let v = UIVisualEffectView(effect: blur)
        v.frame = view.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let label = UILabel()
        label.text = "当前界面已遮蔽以保护隐私"
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        v.contentView.addSubview(label)
        view.addSubview(v)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        shieldView = v
    }

    private func hideShield() {
        shieldView?.removeFromSuperview()
        shieldView = nil
    }
}
#endif
