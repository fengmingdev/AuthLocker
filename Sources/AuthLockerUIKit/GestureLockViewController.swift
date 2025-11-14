#if canImport(UIKit)
import UIKit
import AuthLockerCore

/// 手势解锁界面（UIKit）
public final class GestureLockViewController: UIViewController {
    private let manager: AppLockManager
    private weak var delegate: LockUIEventDelegate?
    private let style: LockStyleProvider
    private let gridLayout: GestureGridLayoutProvider
    private var points: [UIView] = []
    private var selected: [Int] = []
    private let errorLabel = UILabel()
    private let switchButton = UIButton(type: .system)
    private let lineLayer = CAShapeLayer()
    private var fingerPoint: CGPoint?
    private let hitRadius: CGFloat

    public init(manager: AppLockManager = .shared, delegate: LockUIEventDelegate? = nil, style: LockStyleProvider = DefaultLockStyle(), gridLayout: GestureGridLayoutProvider? = nil) {
        self.manager = manager
        self.delegate = delegate
        self.style = style
        self.gridLayout = gridLayout ?? DefaultGestureGridLayoutProvider(style: style)
        self.hitRadius = style.gestureHitRadius
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { return nil }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = style.backgroundColor
        view.tintColor = style.primaryTintColor
        layoutGrid()
        lineLayer.strokeColor = style.primaryTintColor.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = style.lineWidth
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round
        view.layer.addSublayer(lineLayer)
        errorLabel.textColor = style.errorColor
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = style.captionFont
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.isAccessibilityElement = true
        errorLabel.accessibilityLabel = "错误提示"
        view.addSubview(errorLabel)
        switchButton.setTitle("切换至密码解锁", for: .normal)
        switchButton.addTarget(self, action: #selector(onSwitch), for: .touchUpInside)
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        switchButton.titleLabel?.adjustsFontForContentSizeCategory = true
        switchButton.isAccessibilityElement = true
        switchButton.accessibilityLabel = "切换到密码"
        view.addSubview(switchButton)
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            switchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            switchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        lineLayer.frame = view.bounds
        updatePath()
    }

    private func layoutGrid() {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = gridLayout.gridSpacing
        grid.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grid)
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
            grid.addArrangedSubview(row)
        }
        NSLayoutConstraint.activate([
            grid.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        if UIAccessibility.isVoiceOverRunning {
            grid.isHidden = true
            errorLabel.text = "当前为无障碍模式，请使用密码解锁"
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
            errorLabel.text = "请至少连接 4 个点"
            resetSelection()
            return
        }
        if manager.attemptUnlockWithGesture(selected) {
            errorLabel.text = nil
            dismiss(animated: true)
            delegate?.didUnlockSuccess(method: .gesture)
        } else {
            let attempts = manager.currentState()
            switch attempts {
            case .lockedOut:
                errorLabel.text = "当前处于锁定状态"
            default:
                errorLabel.text = "手势错误，请重试"
            }
            resetSelection()
            delegate?.didUnlockFailure(method: .gesture)
        }
    }

    private func resetSelection() {
        for v in points { v.backgroundColor = .clear }
        selected.removeAll()
        fingerPoint = nil
        lineLayer.path = nil
    }

    @objc private func onSwitch() { delegate?.didRequestSwitchToPIN() }

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
#endif
