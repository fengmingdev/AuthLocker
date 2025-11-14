import Foundation

public struct Localizer {
    public static func text(_ key: String) -> String {
        let localized = NSLocalizedString(key, bundle: Bundle.module, value: key, comment: "")
        if localized != key { return localized }
        let lang = Locale.current.languageCode ?? "zh"
        let zh: [String: String] = [
            "lock.title": "应用锁验证",
            "lock.forget": "忘记密码？",
            "lock.biometric": "用指纹/面容解锁",
            "lock.error.pin": "密码不匹配，请重试",
            "lock.error.locked": "当前处于锁定状态，请稍后再试",
            "lock.error.bioRetry": "生物识别失败，请重试",
            "lock.error.bioUsePin": "生物识别失败，请使用密码解锁",
            "lock.error.many": "密码错误次数过多，%d 分钟后可重试",
            "lock.input.count": "已输入若干位数字",
            "pin.set.title": "设置应用锁密码",
            "pin.repeat.title": "重复应用锁密码",
            "pin.error.mismatch": "两次密码不一致",
            "verify.pin.title": "请输入旧密码",
            "verify.pin.error": "旧密码不正确",
            "common.cancel": "取消",
            "gesture.set.title": "设置手势应用锁",
            "gesture.repeat.title": "重复手势应用锁",
            "gesture.error.min": "请至少连接 %d 个点",
            "gesture.error.mismatch": "两次手势不一致",
            "common.error.retry": "设置失败，请重试",
            "settings.title": "应用锁设置",
            "settings.enabled": "开启应用锁",
            "settings.method": "默认解锁方式",
            "settings.interval": "后台触发时长",
            "settings.reset": "重置应用锁",
            "settings.logs": "查看安全日志",
            "settings.trustEnabled": "信任本设备",
            "settings.trustDays": "信任天数",
            "settings.trustActive": "信任已生效",
            "settings.trustInactive": "未设置信任",
            "settings.logsRetention": "日志保留天数",
            "logs.title": "安全日志"
        ]
        let en: [String: String] = [
            "lock.title": "App Lock",
            "lock.forget": "Forgot PIN?",
            "lock.biometric": "Use Touch/Face ID",
            "lock.error.pin": "PIN mismatch, please try again",
            "lock.error.locked": "Locked. Please try later",
            "lock.error.bioRetry": "Biometric failed, please retry",
            "lock.error.bioUsePin": "Biometric failed, use PIN",
            "lock.error.many": "Too many attempts, retry in %d minutes",
            "lock.input.count": "Digits entered",
            "pin.set.title": "Set App Lock PIN",
            "pin.repeat.title": "Repeat App Lock PIN",
            "pin.error.mismatch": "PINs do not match",
            "verify.pin.title": "Enter current PIN",
            "verify.pin.error": "Incorrect current PIN",
            "common.cancel": "Cancel",
            "gesture.set.title": "Set Gesture Lock",
            "gesture.repeat.title": "Repeat Gesture Lock",
            "gesture.error.min": "Please connect at least %d points",
            "gesture.error.mismatch": "Gestures do not match",
            "common.error.retry": "Failed to set, please retry",
            "settings.title": "App Lock Settings",
            "settings.enabled": "Enable App Lock",
            "settings.method": "Default Unlock Method",
            "settings.interval": "Background Trigger Interval",
            "settings.reset": "Reset App Lock",
            "settings.logs": "View Security Logs",
            "settings.trustEnabled": "Trust This Device",
            "settings.trustDays": "Trust Period",
            "settings.trustActive": "Trust active",
            "settings.trustInactive": "Trust not set",
            "settings.logsRetention": "Log Retention Days",
            "logs.title": "Security Logs"
        ]
        let dict = (lang.hasPrefix("zh")) ? zh : en
        return dict[key] ?? key
    }
}
