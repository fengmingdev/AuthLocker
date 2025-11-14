import Foundation

/// PIN 重置服务协议
/// - 为什么：真实工程中应接入后端短信/风控服务；此协议便于替换实现与测试
public protocol LockResetService {
    /// 发送验证码至绑定手机号
    func requestVerificationCode(toPhone phone: String, completion: @escaping (Bool) -> Void)
    /// 校验验证码并允许设置新 PIN
    func verifyCode(_ code: String, completion: @escaping (Bool) -> Void)
}
