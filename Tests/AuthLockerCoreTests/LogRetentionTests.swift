import XCTest
@testable import AuthLockerCore

final class LogRetentionTests: XCTestCase {
    func testRetentionPurgesOldEntries() {
        let logger = SecurityLogger.shared
        logger.setRetentionDays(90)
        let old = SecurityEvent(kind: .unlockFailure, timestamp: Date().addingTimeInterval(-2*86400), details: "old_event")
        logger.record(old)
        let recent = SecurityEvent(kind: .unlockSuccess, timestamp: Date(), details: "recent_event")
        logger.record(recent)
        logger.setRetentionDays(1)
        let since = recent.timestamp.addingTimeInterval(-1)
        let all = logger.query(limit: 50, offset: 0, since: since)
        XCTAssertFalse(all.contains(where: { $0.details == "old_event" }))
        XCTAssertTrue(all.contains(where: { $0.details == "recent_event" }))
    }
}
