import XCTest
@testable import AllowanceCore

final class UsageTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func response(primary: String = "null", secondary: String = "null", bucket: String = "codex") -> Data {
        Data("""
        {"id":2,"result":{"accountId":"test-account","rateLimitsByLimitId":{
        "\(bucket)":{"limitId":"\(bucket)","primary":\(primary),"secondary":\(secondary)}}}}
        """.utf8)
    }
    func window(_ minutes: Int, _ used: Double, reset: Double = 1_800_018_000) -> String {
        "{\"windowDurationMins\":\(minutes),\"usedPercent\":\(used),\"resetsAt\":\(reset)}"
    }

    func testFindsWindowsByDurationRatherThanPosition() throws {
        let snapshot = try UsageDecoder.decode(response(primary: window(10080, 5), secondary: window(300, 21)), now: now)
        XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 79)
        XCTAssertEqual(snapshot.weekly?.remainingPercent, 95)
    }
    func testWeeklyOnlyDoesNotMasqueradeAsFiveHour() throws {
        let snapshot = try UsageDecoder.decode(response(primary: window(10080, 5)), now: now)
        XCTAssertNil(snapshot.fiveHour)
        XCTAssertEqual(UsageDisplay.title(snapshot: snapshot, showWeekly: true, countdown: false, now: now), "--% · --:-- · W 95%")
    }
    func testRejectsOtherProductBucket() {
        XCTAssertThrowsError(try UsageDecoder.decode(response(primary: window(300, 20), bucket: "other"), now: now))
    }
    func testRejectsExpiredAndOutOfRangeWindows() {
        for record in [window(300, 20, reset: now.timeIntervalSince1970), window(300, -1), window(300, 101), window(60, 20)] {
            XCTAssertThrowsError(try UsageDecoder.decode(response(primary: record), now: now))
        }
    }
    func testRejectsMalformedAndNullValues() {
        for data in [Data("not json".utf8), Data("{\"result\":null}".utf8), response(primary: "{\"usedPercent\":null}")] {
            XCTAssertThrowsError(try UsageDecoder.decode(data, now: now))
        }
    }
    func testRejectsBooleanInsteadOfNumber() {
        let record = "{\"windowDurationMins\":300,\"usedPercent\":true,\"resetsAt\":1800018000}"
        XCTAssertThrowsError(try UsageDecoder.decode(response(primary: record), now: now))
    }
    func testInvalidFiveHourDoesNotHideValidWeekly() throws {
        let snapshot = try UsageDecoder.decode(response(primary: window(300, 101), secondary: window(10080, 5)), now: now)
        XCTAssertNil(snapshot.fiveHour)
        XCTAssertNotNil(snapshot.weekly)
    }
    func testSupportsLegacyResponse() throws {
        let data = Data("{\"result\":{\"rateLimits\":{\"limitId\":\"codex\",\"primary\":\(window(300, 21))}}}".utf8)
        XCTAssertEqual(try UsageDecoder.decode(data, now: now).fiveHour?.remainingPercent, 79)
    }
    func testRejectsDuplicateDurations() {
        XCTAssertThrowsError(try UsageDecoder.decode(response(primary: window(300, 21), secondary: window(300, 22)), now: now))
    }
    func testFloorsFractionalRemainingPercentage() throws {
        let snapshot = try UsageDecoder.decode(response(primary: window(300, 21.2)), now: now)
        XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 78)
    }
    func testExpiredDataDoesNotRemainVisible() throws {
        let snapshot = try UsageDecoder.decode(response(primary: window(300, 21)), now: now)
        XCTAssertEqual(UsageDisplay.title(snapshot: snapshot, showWeekly: false, countdown: true, now: now.addingTimeInterval(18000)), "--% · --:--")
    }
    func testCountdownRoundsUpAndNeverGoesNegative() {
        XCTAssertEqual(UsageDisplay.countdown(to: now.addingTimeInterval(3661), now: now), "1h 2m")
        XCTAssertEqual(UsageDisplay.countdown(to: now.addingTimeInterval(1), now: now), "1m")
        XCTAssertEqual(UsageDisplay.countdown(to: now.addingTimeInterval(-1), now: now), "0m")
    }
}
