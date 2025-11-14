import UIKit
import AuthLockerCore

public final class SetPINViewController: UIViewController {
    private let manager: AppLockManager
    private let style: LockStyleProvider
    private let keypadLayout: KeypadLayoutProvider
    private var digits: [Int] = []
    private var firstPIN: String?
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let headerImageView = UIImageView()
    private let dotsStack = UIStackView()
    private let errorLabel = UILabel()
    private let keypadStack = UIStackView()
    private let cancelButton = UIButton(type: .system)
    private let titleOverride: String?
    private let subtitleOverride: String?
    private let headerImage: UIImage?

    public init(manager: AppLockManager = .shared, style: LockStyleProvider = LockThemeManager.shared.currentStyle, keypadLayout: KeypadLayoutProvider? = nil, titleOverride: String? = nil, subtitleOverride: String? = nil, headerImage: UIImage? = nil) {
        self.manager = manager
        self.style = style
        self.keypadLayout = keypadLayout ?? DefaultKeypadLayoutProvider(style: style)
        self.titleOverride = titleOverride
        self.subtitleOverride = subtitleOverride
        self.headerImage = headerImage
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) { return nil }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = style.backgroundColor
        view.tintColor = style.primaryTintColor
        setupHeader()
        setupDots()
        setupError()
        setupKeypad()
        setupActions()
        setupConstraints()
        updateTitle()
    }

    private func setupHeader() {
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = style.titleFont
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
        errorLabel.numberOfLines = 0
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
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

    private func setupActions() {
        cancelButton.setTitle(Localizer.text("common.cancel"), for: .normal)
        cancelButton.titleLabel?.font = style.bodyFont
        cancelButton.titleLabel?.adjustsFontForContentSizeCategory = true
        cancelButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
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
            
            errorLabel.topAnchor.constraint(equalTo: dotsStack.bottomAnchor, constant: style.spacing),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            keypadStack.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: style.spacing),
            keypadStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            keypadStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            cancelButton.topAnchor.constraint(equalTo: keypadStack.bottomAnchor, constant: style.spacing),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        refreshDots()
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

    private func refreshDots() {
        for (idx, v) in dotsStack.arrangedSubviews.enumerated() {
            v.backgroundColor = idx < digits.count ? style.primaryTintColor : .clear
        }
    }

    private func updateTitle() {
        if let t = titleOverride {
            titleLabel.text = t
        } else {
            titleLabel.text = (firstPIN == nil ? Localizer.text("pin.set.title") : Localizer.text("pin.repeat.title"))
        }
    }

    @objc private func onDigit(_ sender: UIButton) {
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

    private func submit() {
        guard digits.count == 6 else { return }
        let pin = digits.map(String.init).joined()
        if let first = firstPIN {
            if first == pin {
                let ok = manager.setPIN(pin)
                if ok {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss(animated: true)
                } else {
                    errorLabel.text = Localizer.text("common.error.retry")
                    digits.removeAll(); refreshDots()
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            } else {
                errorLabel.text = Localizer.text("pin.error.mismatch")
                digits.removeAll(); refreshDots()
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        } else {
            firstPIN = pin
            digits.removeAll(); refreshDots(); updateTitle()
        }
    }

    @objc private func onCancel() { dismiss(animated: true) }

    private func selector(for item: KeypadItem) -> Selector {
        switch item {
        case .number: return #selector(onDigit(_:))
        case .delete: return #selector(onDelete)
        case .submit: return #selector(onSubmit)
        case .spacer: return #selector(onSubmit)
        }
    }
}