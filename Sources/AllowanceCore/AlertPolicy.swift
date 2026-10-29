import Foundation

public struct AlertHistory: Codable, Equatable {
    public let accountID: String
    public let reset: Date
    public var sent: Set<Int>

    public init(accountID: String, reset: Date, sent: Set<Int> = []) {
        self.accountID = accountID; self.reset = reset; self.sent = sent
    }

    public func matches(accountID: String, reset: Date) -> Bool {
        // The server can adjust the same reset timestamp by a second or two.
        self.accountID == accountID && abs(self.reset.timeIntervalSince(reset)) <= 60
    }
}

// Pure decision-making code: no notifications or preference writes happen here.
public enum AlertPolicy {
    public static func threshold(remaining: Int, alreadySent: Set<Int>) -> Int? {
        // A first reading below 10% produces one alert, rather than two.
        let crossed = [20, 10].filter { remaining <= $0 }
        guard let lowest = crossed.min(), !alreadySent.contains(lowest) else { return nil }
        return lowest
    }

    public static func thresholdsCovered(by threshold: Int) -> Set<Int> {
        Set([20, 10].filter { $0 >= threshold })
    }
}
