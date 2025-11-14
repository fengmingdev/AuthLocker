#if canImport(UIKit)
import UIKit
import AuthLockerCore

public final class ResetPINViewController: UIViewController {
    private let manager: AppLockManager
    private let service: LockResetService

    private let phoneField = UITextField()
    private let codeField = UITextField()
    private let pinField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let errorLabel = UILabel()

    public init(manager: AppLockManager = .shared, service: LockResetService = SimpleLockResetService()) {
        self.manager = manager
        self.service = service
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
        title = "重置应用锁"
    }

    required init?(coder: NSCoder) { return nil }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        phoneField.placeholder = "手机号"
        phoneField.keyboardType = .phonePad
        phoneField.borderStyle = .roundedRect
        phoneField.font = UIFont.preferredFont(forTextStyle: .body)
        phoneField.adjustsFontForContentSizeCategory = true

        codeField.placeholder = "验证码"
        codeField.keyboardType = .numberPad
        codeField.borderStyle = .roundedRect
        codeField.font = UIFont.preferredFont(forTextStyle: .body)
        codeField.adjustsFontForContentSizeCategory = true

        pinField.placeholder = "新 6 位密码"
        pinField.keyboardType = .numberPad
        pinField.borderStyle = .roundedRect
        pinField.font = UIFont.preferredFont(forTextStyle: .body)
        pinField.adjustsFontForContentSizeCategory = true

        sendButton.setTitle("发送验证码", for: .normal)
        sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)
        sendButton.titleLabel?.adjustsFontForContentSizeCategory = true

        confirmButton.setTitle("确认重置", for: .normal)
        confirmButton.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        confirmButton.titleLabel?.adjustsFontForContentSizeCategory = true

        errorLabel.textColor = .systemRed
        errorLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.numberOfLines = 0

        stack.addArrangedSubview(phoneField)
        stack.addArrangedSubview(sendButton)
        stack.addArrangedSubview(codeField)
        stack.addArrangedSubview(pinField)
        stack.addArrangedSubview(confirmButton)
        stack.addArrangedSubview(errorLabel)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    @objc private func onSend() {
        guard let phone = phoneField.text, !phone.isEmpty else {
            errorLabel.text = "请输入手机号"
            return
        }
        service.requestVerificationCode(toPhone: phone) { ok in
            self.errorLabel.text = ok ? "验证码已发送" : "验证码发送失败"
        }
    }

    @objc private func onConfirm() {
        guard let code = codeField.text, !code.isEmpty else {
            errorLabel.text = "请输入验证码"
            return
        }
        guard let pin = pinField.text, pin.count == 6, pin.allSatisfy({ $0.isNumber }) else {
            errorLabel.text = "请输入 6 位数字密码"
            return
        }
        manager.completePINReset(code: code, newPIN: pin) { ok in
            if ok {
                self.errorLabel.text = nil
                self.dismiss(animated: true)
            } else {
                self.errorLabel.text = "重置失败，请检查验证码"
            }
        }
    }
}
#endif
