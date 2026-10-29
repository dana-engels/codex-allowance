import Foundation

final class Preferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["showWeekly": false, "showCountdown": false, "alertsEnabled": false])
    }

    var showWeekly: Bool {
        get { defaults.bool(forKey: "showWeekly") }
        set { defaults.set(newValue, forKey: "showWeekly") }
    }
    var showCountdown: Bool {
        get { defaults.bool(forKey: "showCountdown") }
        set { defaults.set(newValue, forKey: "showCountdown") }
    }
    var alertsEnabled: Bool {
        get { defaults.bool(forKey: "alertsEnabled") }
        set { defaults.set(newValue, forKey: "alertsEnabled") }
    }
}
