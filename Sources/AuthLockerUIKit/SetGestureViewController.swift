import UIKit
import AuthLockerCore

public final class SetGestureViewController: UIViewController {
    private let manager: AppLockManager
    private let style: LockStyleProvider
    private let gridLayout: GestureGridLayoutProvider
    private let titleOverride: String?
    private let subtitleOverride: String?
    private let headerImage: UIImage?
    private let gridStack = UIStackView()
    private var points: [UIView] = []
    private var selected: [Int] = []
    private var firstSeq: [Int]?
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let headerImageView = UIImageView()
    private let errorLabel = UILabel()
    private let switchToPINButton = UIButton(type: .system)
    private let lineLayer = CAShapeLayer()
    private var fingerPoint: CGPoint?
    private let hitRadius: CGFloat

    public init(manager: AppLockManager = .shared, style: LockStyleProvider = LockThemeManager.shared.currentStyle, gridLayout: GestureGridLayoutProvider? = nil, titleOverride: String? = nil, subtitleOverride: String? = nil, headerImage: UIImage? = nil) {
        self.manager = manager
        self.style = style
        self.gridLayout = gridLayout ?? DefaultGestureGridLayoutProvider(style: style)
        self.titleOverride = titleOverride
        self.subtitleOverride = subtitleOverride
        self.headerImage = headerImage
        self.hitRadius = style.gestureHitRadius
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) { return nil }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = style.backgroundColor
        view.tintColor = style.primaryTintColor
        setupHeader()
        setupGrid()
        setupErrorAndActions()
        setupLineLayer()
        setupConstraints()
        updateTitle()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        lineLayer.frame = view.bounds
        updatePath()
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

    private func setupGrid() {
        gridStack.axis = .vertical
        gridStack.spacing = gridLayout.gridSpacing
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridStack)
        for r in 0..<gridLayout.rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = gridLayout.gridSpacing
            row.translatesAutoresizingMaskIntoConstraints = false
            for c in 0..<gridLayout.columns {
                let idx = r * gridLayout.columns + c
                let v = UIView()
                v.translatesAutoresizingMaskIntoConstraints = false
                v.layer.cornerRadius = style.gesturePointCornerRadius
                v.layer.borderWidth = 1
                v.layer.borderColor = UIColor.separator.cgColor
                v.tag = idx
                v.isAccessibilityElement = true
                v.accessibilityLabel = "手势点 \(idx)"
                points.append(v)
                NSLayoutConstraint.activate([
                    v.widthAnchor.constraint(equalToConstant: gridLayout.pointSize.width),
                    v.heightAnchor.constraint(equalToConstant: gridLayout.pointSize.height)
                ])
                row.addArrangedSubview(v)
            }
            gridStack.addArrangedSubview(row)
        }
    }

    private func setupErrorAndActions() {
        errorLabel.textColor = style.errorColor
        errorLabel.font = style.captionFont
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.numberOfLines = 0
        view.addSubview(errorLabel)
        switchToPINButton.setTitle("改用密码设置", for: .normal)
        switchToPINButton.titleLabel?.font = style.bodyFont
        switchToPINButton.titleLabel?.adjustsFontForContentSizeCategory = true
        switchToPINButton.addTarget(self, action: #selector(onSwitchToPIN), for: .touchUpInside)
        switchToPINButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switchToPINButton)
    }

    private func setupLineLayer() {
        lineLayer.strokeColor = style.primaryTintColor.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = style.lineWidth
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round
        view.layer.addSublayer(lineLayer)
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
        constraints += [
            gridStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.topAnchor.constraint(equalTo: gridStack.bottomAnchor, constant: style.spacing),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            switchToPINButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            switchToPINButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func updateTitle() {
        if let override = titleOverride {
            titleLabel.text = override
            return
        }
        if firstSeq == nil {
            titleLabel.text = Localizer.text("gesture.set.title")
        } else {
            titleLabel.text = Localizer.text("gesture.repeat.title")
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, !UIAccessibility.isVoiceOverRunning else { return }
        let p = t.location(in: view)
        fingerPoint = p
        if let idx = nearestIndex(to: p), !selected.contains(idx) {
            selected.append(idx)
            updatePointAppearance()
            UISelectionFeedbackGenerator().selectionChanged()
        }
        updatePath()
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, !UIAccessibility.isVoiceOverRunning else { return }
        let p = t.location(in: view)
        fingerPoint = p
        if let idx = nearestIndex(to: p), !selected.contains(idx) {
            selected.append(idx)
            updatePointAppearance()
            UISelectionFeedbackGenerator().selectionChanged()
        }
        updatePath()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !UIAccessibility.isVoiceOverRunning { submit() }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetSelection()
    }

    private func submit() {
        if selected.count < 4 {
            errorLabel.text = String(format: Localizer.text("gesture.error.min"), 4)
            resetSelection()
            return
        }
        if let first = firstSeq {
            if first == selected {
                let ok = manager.setGesture(selected)
                if ok {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss(animated: true)
                } else {
                    errorLabel.text = Localizer.text("common.error.retry")
                    resetSelection()
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            } else {
                errorLabel.text = Localizer.text("gesture.error.mismatch")
                resetSelection()
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        } else {
            firstSeq = selected
            resetSelection()
            updateTitle()
        }
    }

    @objc private func onSwitchToPIN() {
        let vc = SetPINViewController(manager: manager, style: style)
        present(vc, animated: true)
    }

    private func resetSelection() {
        for v in points { v.backgroundColor = .clear }
        selected.removeAll()
        fingerPoint = nil
        lineLayer.path = nil
    }

    private func centers() -> [CGPoint] {
        points.map { v in
            let c = CGPoint(x: v.bounds.midX, y: v.bounds.midY)
            return v.convert(c, to: view)
        }
    }

    private func nearestIndex(to p: CGPoint) -> Int? {
        let cs = centers()
        var best: (idx: Int, dist: CGFloat)?
        for (i, c) in cs.enumerated() {
            let dx = c.x - p.x
            let dy = c.y - p.y
            let d = sqrt(dx*dx + dy*dy)
            if d <= hitRadius {
                if best == nil || d < best!.dist { best = (i, d) }
            }
        }
        return best?.idx
    }

    private func updatePointAppearance() {
        for v in points { v.backgroundColor = selected.contains(v.tag) ? style.primaryTintColor : .clear }
    }

    private func updatePath() {
        guard !selected.isEmpty else { lineLayer.path = nil; return }
        let cs = centers()
        let path = UIBezierPath()
        let first = cs[selected[0]]
        path.move(to: first)
        for idx in selected.dropFirst() { path.addLine(to: cs[idx]) }
        if let fp = fingerPoint { path.addLine(to: fp) }
        lineLayer.path = path.cgPath
    }
}