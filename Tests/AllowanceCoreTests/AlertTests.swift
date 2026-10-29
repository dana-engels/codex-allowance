import XCTest
@testable import AllowanceCore

final class AlertTests: XCTestCase {
    func testNoAlertAboveThreshold() {
        XCTAssertNil(AlertPolicy.threshold(remaining: 21, alreadySent: []))
    }
    func testTwentyThenTenWithoutRepeats() {
        XCTAssertEqual(AlertPolicy.threshold(remaining: 20, alreadySent: []), 20)
        XCTAssertNil(AlertPolicy.threshold(remaining: 19, alreadySent: [20]))
        XCTAssertEqual(AlertPolicy.threshold(remaining: 10, alreadySent: [20]), 10)
        XCTAssertNil(AlertPolicy.threshold(remaining: 0, alreadySent: [20, 10]))
    }
    func testJumpBelowTenProducesOneAlert() {
        XCTAssertEqual(AlertPolicy.threshold(remaining: 8, alreadySent: []), 10)
        XCTAssertEqual(AlertPolicy.thresholdsCovered(by: 10), [20, 10])
    }
    func testHistorySurvivesRestartButNotAnotherWindowOrAccount() throws {
        let reset = Date(timeIntervalSince1970: 1_800_018_000)
        let original = AlertHistory(accountID: "test", reset: reset, sent: [20])
        let restored = try JSONDecoder().decode(AlertHistory.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(restored, original)
        XCTAssertTrue(restored.matches(accountID: "test", reset: reset.addingTimeInterval(1)))
        XCTAssertFalse(restored.matches(accountID: "other", reset: reset))
        XCTAssertFalse(restored.matches(accountID: "test", reset: reset.addingTimeInterval(18000)))
    }
}
