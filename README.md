# AuthLocker

轻量级、可扩展的应用锁组件，提供 PIN、手势与生物识别解锁能力，支持 UIKit 与 SwiftUI 适配，具备风险策略、锁定策略与本地化支持。

## 特性
- PIN/手势/生物识别解锁流程
- 风险检测与锁定策略（错误计数、锁定窗口、版本变更触发）
- UIKit 现成 UI 组件与 SwiftUI 适配器
- 主题样式体系 `LockStyleProvider`（内置 `MinimalStyle`、`StrongBrandStyle`）
- 本地化 `Localizer`，提供中/英默认文案键
- 演示工程 `Examples/AuthLockerDemo`

## 环境要求
- iOS 13+
- Swift 5.5+

## 引入方式
### Swift Package Manager
在 `Package.swift` 中添加：

```
.dependencies: [
    .package(url: "https://github.com/fengmingdev/AuthLocker.git", branch: "main")
]
```

并在目标中引用：

```
.target(
    name: "YourApp",
    dependencies: ["AuthLockerCore", "AuthLockerUIKit"]
)
```

如使用 Xcode，可在项目设置的 Package Dependencies 中添加上述仓库并选择分支 `main`。

## 快速开始
### 1. 初始化与配置
```
import AuthLockerCore

let manager = AppLockManager.shared
manager.configure(AppLockManager.Configuration(
    enabled: true,
    defaultMethod: .pin,
    trustEnabled: false
))
```

### 2. 展示验证界面（自动选择默认方式）
```
import AuthLockerUIKit

LockUIFactory.present(
    mode: .validate,
    options: LockUIOptions(style: MinimalStyle()),
    over: presenterViewController
)
```

### 3. 设置 PIN 或手势
```
LockUIFactory.present(
    mode: .createPIN,
    options: LockUIOptions(style: MinimalStyle()),
    over: presenterViewController
)

LockUIFactory.present(
    mode: .createGesture,
    options: LockUIOptions(style: StrongBrandStyle()),
    over: presenterViewController
)
```

### 4. 自定义样式与文案
```
let options = LockUIOptions(
    title: "自定义标题",
    subtitle: "副标题",
    image: UIImage(systemName: "lock"),
    style: StrongBrandStyle(),
    enableBiometrics: true
)
LockUIFactory.present(mode: .validate, options: options, over: presenter)
```

## 主要模块
- `AuthLockerCore`：核心状态机与策略（PIN/手势存储验证、锁定、风险、日志、本地化）
- `AuthLockerUIKit`：UIKit 视图控制器与 UI 工厂
- `AuthLockerSwiftUIAdapter`：SwiftUI 适配器（基础桥接）
- `Examples/AuthLockerDemo`：示例 App（Xcode 工程）

## 样式系统
通过 `LockStyleProvider` 自定义主题：
- 颜色与字体：`backgroundColor`、`primaryTintColor`、`titleFont` 等
- 布局与尺寸：`spacing`、`gridSpacing`、`dotSize`、`gesturePointSize`
- 手势细节：`gesturePointCornerRadius`、`gestureHitRadius`

切换样式示例：
```
LockUIFactory.present(
    mode: .validate,
    options: LockUIOptions(style: StrongBrandStyle()),
    over: presenter
)
```

## 本地化
通过 `Localizer.text(key)` 获取文案，内置键包括：
- `lock.title`、`lock.forget`、`lock.biometric`、`lock.error.pin`、`lock.error.locked`、`lock.error.many`
- `gesture.set.title`、`gesture.repeat.title`、`gesture.error.min`、`gesture.error.mismatch`
- `pin.set.title`、`pin.repeat.title`、`pin.error.mismatch`、`verify.pin.title`、`verify.pin.error`
- `common.error.retry`、`common.cancel`

可在 `Sources/AuthLockerCore/Resources` 下添加自定义 `Localizable.strings` 覆盖。

## 质量保障
- `swiftlint.yml`：启用圈复杂度、函数/文件/类型长度、命名、行宽、嵌套与强制解包禁止等规则
- 代码结构：UIKit 控件的 `setupUI` 已拆分为若干子方法，提升可读性与可维护性

## 演示工程
- 路径：`Examples/AuthLockerDemo`
- 使用 Xcode 打开 `AuthLockerDemo.xcodeproj` 运行

## 安全提示
- 不记录敏感信息与密钥
- FaceID/TouchID 根据风险状态与时间漂移进行审慎处理

## 许可
- 本项目当前未设置开源许可证。如需二次分发，请先补充许可证声明。