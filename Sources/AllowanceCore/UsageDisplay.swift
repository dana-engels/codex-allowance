import Foundation

public enum UsageDisplay {
    public static func countdown(to reset: Date, now: Date) -> String {
        let minutes = max(0, Int(ceil(reset.timeIntervalSince(now) / 60)))
        if minutes >= 60 { return "\(minutes / 60)h \(minutes % 60)m" }
        return "\(minutes)m"
    }

    public static func title(snapshot: UsageSnapshot?, showWeekly: Bool,
                             countdown: Bool, now: Date = Date()) -> String {
        let fiveHour = snapshot?.fiveHour.flatMap { $0.isCurrent(at: now) ? $0 : nil }
        var title = "--% · --:--"
        if let fiveHour {
            let reset: String
            if countdown {
                reset = "in " + self.countdown(to: fiveHour.resetsAt, now: now)
            } else {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                reset = formatter.string(from: fiveHour.resetsAt)
            }
            title = "\(fiveHour.remainingPercent)% · \(reset)"
        }
        if showWeekly {
            let weekly = snapshot?.weekly.flatMap { $0.isCurrent(at: now) ? $0 : nil }
            title += weekly.map { " · W \($0.remainingPercent)%" } ?? " · W --%"
        }
        return title
    }
}
