import Foundation

/// 安全事件模型（JSONL 持久化）
public struct SecurityEvent: Codable, Equatable {
    /// 事件类型枚举
    public enum Kind: String, Codable {
        case enabled
        case disabled
        case unlockSuccess
        case unlockFailure
        case pinReset
        case lockoutStarted
        case foregroundTrigger
        case appLaunchTrigger
        case deviceLock
        case deviceUnlock
        case versionChanged
        case riskDetected
    }
    /// 事件类型
    public var kind: Kind
    /// 事件时间戳（ISO8601 持久化）
    public var timestamp: Date
    /// 事件详情（可能含敏感信息，导出时可脱敏）
    public var details: String?
    public init(kind: Kind, timestamp: Date = Date(), details: String? = nil) {
        self.kind = kind
        self.timestamp = timestamp
        self.details = details
    }
}

/// 安全日志记录器：将事件以 JSONL 追加到应用支持目录
/// - 为什么：追加写入简单、易分页读取与清理；提供筛选、导出与保留期管理
public final class SecurityLogger {
    public static let shared = SecurityLogger()
    private let fm = FileManager.default
    private let fileName = "authlocker-security-log.jsonl"
    private let retentionKey = "authlocker.log.retentionDays"
    private let errorFileName = "authlocker-security-error.log"

    private init() {}

    private func logFileURL() -> URL? {
        do {
            let dir = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return dir.appendingPathComponent(fileName)
        } catch {
            return nil
        }
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    /// 记录事件并尝试按保留期清理旧条目
    public func record(_ event: SecurityEvent) {
        guard let url = logFileURL() else { return }
        guard let data = try? SecurityLogger.encoder.encode(event), var str = String(data: data, encoding: .utf8) else { recordError("encode_failed"); return }
        str.append("\n")
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { handle.closeFile() }
            handle.seekToEndOfFile()
            handle.write(Data(str.utf8))
        } else {
            do { try str.write(to: url, atomically: true, encoding: .utf8) } catch { recordError("write_failed") }
        }
        purgeOldEntries()
    }

    /// 最近 N 天事件聚合（便捷方法）
    public func recentEvents(days: Int = 30) -> [SecurityEvent] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        return streamEvents(kind: nil, since: cutoff, until: nil, offset: 0, limit: Int.max)
    }

    /// 查询接口：支持类型、时间范围、分页
    public func query(kind: SecurityEvent.Kind? = nil, limit: Int = 50, offset: Int = 0, since: Date? = nil, until: Date? = nil) -> [SecurityEvent] {
        return streamEvents(kind: kind, since: since, until: until, offset: offset, limit: limit)
    }

    /// 导出为 CSV 文本
    /// - 参数 sanitize：是否将 details 清空以脱敏
    public func exportCSV(kind: SecurityEvent.Kind? = nil, limit: Int = 1000, since: Date? = nil, until: Date? = nil, sanitize: Bool = true) -> String {
        let events = query(kind: kind, limit: limit, offset: 0, since: since, until: until)
        var lines: [String] = ["kind,timestamp,details"]
        let f = ISO8601DateFormatter()
        for e in events {
            let d = sanitize ? "" : (e.details ?? "")
            let t = f.string(from: e.timestamp)
            let k = e.kind.rawValue
            let escaped = d.replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\(k),\(t),\"\(escaped)\"")
        }
        return lines.joined(separator: "\n")
    }

    /// 根据保留期删除过期日志条目
    private func purgeOldEntries() {
        guard let url = logFileURL(), let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else { recordError("purge_read_failed"); return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let cutoff = Date().addingTimeInterval(-Double(getRetentionDays()) * 86400)
        let filtered = text.split(separator: "\n").compactMap { line -> String? in
            guard let data = String(line).data(using: .utf8), let event = try? decoder.decode(SecurityEvent.self, from: data) else { return nil }
            return event.timestamp >= cutoff ? String(line) : nil
        }
        let newText = filtered.joined(separator: "\n")
        do { try newText.write(to: url, atomically: true, encoding: .utf8) } catch { recordError("purge_write_failed") }
    }

    /// 设置日志保留天数（默认 30，最小 1）
    public func setRetentionDays(_ days: Int) {
        UserDefaults.standard.setValue(days, forKey: retentionKey)
        purgeOldEntries()
    }

    /// 获取当前保留天数
    public func getRetentionDays() -> Int {
        let v = UserDefaults.standard.object(forKey: retentionKey) as? Int
        return max(1, v ?? 30)
    }

    private func recordError(_ message: String) {
        guard let dir = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
        let url = dir.appendingPathComponent(errorFileName)
        let line = message + "\n"
        if let h = try? FileHandle(forWritingTo: url) {
            defer { h.closeFile() }
            h.seekToEndOfFile()
            h.write(Data(line.utf8))
        } else {
            do { try line.write(to: url, atomically: true, encoding: .utf8) } catch {}
        }
    }

    private func streamEvents(kind: SecurityEvent.Kind?, since: Date?, until: Date?, offset: Int, limit: Int) -> [SecurityEvent] {
        guard let url = logFileURL(), let h = try? FileHandle(forReadingFrom: url) else { return [] }
        defer { h.closeFile() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var buffer = Data()
        var events: [SecurityEvent] = []
        var skipped = 0
        let chunkSize = 64 * 1024
        while true {
            let d = h.readData(ofLength: chunkSize)
            if !d.isEmpty {
                buffer.append(d)
                while let range = buffer.firstRange(of: Data([10])) { // '\n'
                    let lineData = buffer.subdata(in: 0..<range.lowerBound)
                    buffer.removeSubrange(0..<(range.upperBound))
                    if let event = try? decoder.decode(SecurityEvent.self, from: lineData) {
                        if let k = kind, event.kind != k { continue }
                        if let s = since, event.timestamp < s { continue }
                        if let u = until, event.timestamp > u { continue }
                        if skipped < max(0, offset) { skipped += 1; continue }
                        events.append(event)
                        if events.count >= max(0, limit) { return events }
                    }
                }
            } else {
                break
            }
        }
        if !buffer.isEmpty {
            if let event = try? decoder.decode(SecurityEvent.self, from: buffer) {
                if let k = kind, event.kind != k { return events }
                if let s = since, event.timestamp < s { return events }
                if let u = until, event.timestamp > u { return events }
                if skipped < max(0, offset) { /* drop */ } else {
                    events.append(event)
                }
            }
        }
        return events
    }
}
