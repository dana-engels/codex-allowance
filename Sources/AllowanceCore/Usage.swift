import Foundation

public struct UsageWindow: Equatable {
    public let minutes: Int
    public let usedPercent: Double
    public let resetsAt: Date

    public init(minutes: Int, usedPercent: Double, resetsAt: Date) {
        self.minutes = minutes
        self.usedPercent = usedPercent
        self.resetsAt = resetsAt
    }

    public var remainingPercent: Int { Int((100 - usedPercent).rounded(.down)) }
    public func isCurrent(at date: Date) -> Bool { resetsAt > date }
}

public struct UsageSnapshot {
    public let accountID: String?
    public let fiveHour: UsageWindow?
    public let weekly: UsageWindow?
    public let fetchedAt: Date
}

public enum UsageError: Error, LocalizedError, Equatable {
    case cliMissing, launchFailed, timedOut, connectionClosed, invalidResponse, tooMuchData
    case requestFailed

    public var errorDescription: String? {
        switch self {
        case .cliMissing: return "Codex CLI not found. Check that ChatGPT or Codex is installed."
        case .launchFailed: return "Could not start the Codex CLI."
        case .timedOut: return "Codex did not reply within 20 seconds."
        case .connectionClosed: return "Codex closed the connection before replying."
        case .invalidResponse: return "The usage response has changed or is invalid."
        case .tooMuchData: return "Codex sent an unexpectedly large response."
        case .requestFailed: return "Usage is unavailable. Check that Codex is signed in."
        }
    }
}

public enum UsageDecoder {
    private struct Reply: Decodable { let result: ResultData? }
    private struct ResultData: Decodable {
        let accountId: String?
        let rateLimitsByLimitId: [String: Limits]?
        let rateLimits: Limits?
    }
    private struct Limits: Decodable {
        let limitId: String?
        let primary: Window?
        let secondary: Window?
    }
    private struct Window: Decodable {
        let usedPercent: Double?
        let windowDurationMins: Int?
        let resetsAt: Double?
    }

    public static func decode(_ data: Data, now: Date = Date()) throws -> UsageSnapshot {
        guard let reply = try? JSONDecoder().decode(Reply.self, from: data),
              let result = reply.result else { throw UsageError.invalidResponse }
        let limits: Limits?
        if let buckets = result.rateLimitsByLimitId {
            // A populated bucket map is authoritative; never select another product.
            limits = buckets["codex"]
        } else {
            limits = result.rateLimits
        }
        guard let limits, limits.limitId == nil || limits.limitId == "codex" else {
            throw UsageError.invalidResponse
        }
        var windows: [Int: UsageWindow] = [:]
        for record in [limits.primary, limits.secondary].compactMap({ $0 }) {
            guard let minutes = record.windowDurationMins, [300, 10080].contains(minutes),
                  let used = record.usedPercent, used.isFinite, (0...100).contains(used),
                  let timestamp = record.resetsAt, timestamp.isFinite else { continue }
            let reset = Date(timeIntervalSince1970: timestamp)
            guard reset > now else { continue }
            guard windows[minutes] == nil else { throw UsageError.invalidResponse }
            windows[minutes] = UsageWindow(minutes: minutes, usedPercent: used, resetsAt: reset)
        }
        guard !windows.isEmpty else { throw UsageError.invalidResponse }
        return UsageSnapshot(accountID: result.accountId, fiveHour: windows[300],
                             weekly: windows[10080], fetchedAt: now)
    }
}
