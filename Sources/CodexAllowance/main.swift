import AppKit
import Darwin
import AllowanceCore
import UsageService

// A closed child-process pipe should produce an error, not terminate the app.
signal(SIGPIPE, SIG_IGN)

if CommandLine.arguments.contains("--check") {
    do {
        let snapshot = try UsageClient().fetch()
        print(UsageDisplay.title(snapshot: snapshot, showWeekly: true, countdown: false))
        exit(0)
    } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        print("--% · --:--")
        exit(1)
    }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
