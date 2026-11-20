import Foundation

/// Owns retry timing and prevents concurrent reads from timer, wake, and menu actions.
public struct RefreshPolicy {
    public private(set) var inFlight = false
    private var retryDelay: TimeInterval = 60

    public init() {}

    public mutating func begin() -> Bool {
        guard !inFlight else { return false }
        inFlight = true
        return true
    }

    public mutating func complete(succeeded: Bool) -> TimeInterval {
        inFlight = false
        if succeeded {
            retryDelay = 60
            return 60
        }
        let delay = retryDelay
        retryDelay = min(retryDelay * 2, 300)
        return delay
    }
}
