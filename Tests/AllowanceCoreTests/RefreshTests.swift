import XCTest
import AllowanceCore

final class RefreshTests: XCTestCase {
    func testRepeatedFailuresBackOffAndSuccessRestoresMinuteCadence() {
        var policy = RefreshPolicy()
        for expected: TimeInterval in [60, 120, 240, 300, 300] {
            XCTAssertTrue(policy.begin())
            XCTAssertEqual(policy.complete(succeeded: false), expected)
        }
        XCTAssertTrue(policy.begin())
        XCTAssertEqual(policy.complete(succeeded: true), 60)
        XCTAssertTrue(policy.begin())
        XCTAssertEqual(policy.complete(succeeded: false), 60)
    }

    func testWakeAndManualActionsCannotOverlapAnActiveRead() {
        var policy = RefreshPolicy()
        XCTAssertTrue(policy.begin())
        XCTAssertFalse(policy.begin())
        XCTAssertFalse(policy.begin())
        XCTAssertTrue(policy.inFlight)
        _ = policy.complete(succeeded: true)
        XCTAssertFalse(policy.inFlight)
        XCTAssertTrue(policy.begin())
    }
}
