import AppKit
import ServiceManagement
import AllowanceCore
import UsageService

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let preferences = Preferences()
    private let client: UsageFetching = UsageClient()
    private let notifications = NotificationManager()
    private let login = LoginManager()
    private var item: NSStatusItem!
    private var refreshTimer: Timer?
    private var displayTimer: Timer?
    private var snapshot: UsageSnapshot?
    private var lastSuccess: Date?
    private var problem: String?
    private var inFlight = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Launch Services normally prevents duplicates, including login launches.
        let bundleID = Bundle.main.bundleIdentifier ?? "local.dana.codex-allowance"
        let anotherCopy = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .contains { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        if anotherCopy { NSApp.terminate(nil); return }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        item.autosaveName = "CodexAllowance"
        let menu = NSMenu(); menu.delegate = self; menu.autoenablesItems = false; item.menu = menu
        render()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in self?.refresh() }
        // Re-render countdowns and expire old data without another network call.
        displayTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in self?.render() }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(timeChanged), name: .NSSystemTimeZoneDidChange, object: nil)
        refresh()
    }

    @objc private func didWake() { render(); refresh() }
    @objc private func timeChanged() { render() }

    @objc private func refresh() {
        guard !inFlight else { return }
        inFlight = true
        render()
        DispatchQueue.global(qos: .utility).async { [self] in
            let result = Result { try client.fetch() }
            DispatchQueue.main.async { [self] in
                inFlight = false
                switch result {
                case .success(let value):
                    snapshot = value
                    lastSuccess = value.fetchedAt
                    problem = nil
                    notifications.check(value, enabled: preferences.alertsEnabled)
                case .failure(let error):
                    snapshot = nil
                    problem = error.localizedDescription
                }
                render()
            }
        }
    }

    private func currentSnapshot(at now: Date) -> UsageSnapshot? {
        guard let snapshot, now.timeIntervalSince(snapshot.fetchedAt) < 360,
              now >= snapshot.fetchedAt.addingTimeInterval(-60) else { return nil }
        return snapshot
    }

    private func render() {
        guard item != nil else { return }
        let now = Date()
        let value = currentSnapshot(at: now)
        item.button?.title = UsageDisplay.title(snapshot: value, showWeekly: preferences.showWeekly,
                                               countdown: preferences.showCountdown, now: now)
        item.button?.toolTip = problem ?? "Codex five-hour allowance remaining and reset time. Refreshes every five minutes."
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) { rebuildMenu() }

    private func rebuildMenu() {
        guard let menu = item.menu else { return }
        menu.removeAllItems()
        let now = Date()
        let value = currentSnapshot(at: now)
        addInfo("Codex Allowance")
        addWindow("Five-hour", window: value?.fiveHour, now: now)
        addWindow("Weekly", window: value?.weekly, now: now)
        if let lastSuccess {
            let time = DateFormatter(); time.timeStyle = .short
            addInfo("Last updated: \(time.string(from: lastSuccess))")
        }
        if let problem { addInfo(problem) }
        else if lastSuccess == nil { addInfo("Fetching allowance…") }
        else if value == nil { addInfo("Data expired; waiting for a fresh reading") }
        menu.addItem(.separator())
        addAction(inFlight ? "Refreshing…" : "Refresh Now", #selector(refresh), enabled: !inFlight)
        menu.addItem(.separator())
        addToggle("Show Weekly in Menu Bar", #selector(toggleWeekly), on: preferences.showWeekly)
        addToggle("Show Reset Countdown", #selector(toggleCountdown), on: preferences.showCountdown)
        addToggle("Low-Allowance Notifications", #selector(toggleAlerts), on: preferences.alertsEnabled)
        addInfo("Alerts at 20% and 10% remaining")
        let status = login.status
        addToggle("Launch at Login", #selector(toggleLogin), on: status == .enabled || status == .requiresApproval)
        if status == .requiresApproval {
            addAction("Approve Login Item in System Settings…", #selector(openLoginSettings))
        }
        menu.addItem(.separator())
        addAction("About Codex Allowance…", #selector(showAbout))
        addAction("Quit Codex Allowance", #selector(quit))
    }

    private func addInfo(_ title: String) {
        let row = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        row.isEnabled = false
        item.menu?.addItem(row)
    }
    private func addAction(_ title: String, _ action: Selector, enabled: Bool = true) {
        let row = NSMenuItem(title: title, action: action, keyEquivalent: "")
        row.target = self; row.isEnabled = enabled
        item.menu?.addItem(row)
    }
    private func addToggle(_ title: String, _ action: Selector, on: Bool) {
        addAction(title, action)
        item.menu?.items.last?.state = on ? .on : .off
    }
    private func addWindow(_ name: String, window: UsageWindow?, now: Date) {
        guard let window, window.isCurrent(at: now) else { addInfo("\(name): unavailable"); return }
        let time = DateFormatter(); time.dateStyle = .medium; time.timeStyle = .short
        addInfo("\(name): \(window.remainingPercent)% remaining")
        addInfo("Resets \(time.string(from: window.resetsAt))")
    }

    @objc private func toggleWeekly() { preferences.showWeekly.toggle(); render() }
    @objc private func toggleCountdown() { preferences.showCountdown.toggle(); render() }
    @objc private func toggleAlerts() {
        if preferences.alertsEnabled { preferences.alertsEnabled = false; render(); return }
        notifications.requestPermission { [weak self] allowed, error in
            guard let self else { return }
            self.preferences.alertsEnabled = allowed
            self.render()
            if allowed, let snapshot = self.currentSnapshot(at: Date()) {
                self.notifications.check(snapshot, enabled: true)
            } else if !allowed {
                self.showMessage("Notifications are off", error ?? "Enable Codex Allowance in System Settings → Notifications, then turn this option on again.")
            }
        }
    }
    @objc private func toggleLogin() {
        do {
            try login.setEnabled(!(login.status == .enabled || login.status == .requiresApproval))
            render()
        } catch {
            showMessage("Could not change login startup", "\(error.localizedDescription)\n\nYou can also add Codex Allowance manually in System Settings → General → Login Items.")
        }
    }
    @objc private func openLoginSettings() { login.openSettings() }
    @objc private func showAbout() {
        showMessage("Codex Allowance 2.0", "Your Codex allowance, at a glance.\n\nSwift + AppKit. Refreshes every five minutes and after wake. Uses the bundled Codex CLI; app updates or expired sign-in can interrupt readings.\n\nThis local build is not notarized. Notifications and login startup are optional.")
    }
    private func showMessage(_ title: String, _ body: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert(); alert.messageText = title; alert.informativeText = body
        alert.runModal()
    }
    @objc private func quit() { NSApp.terminate(nil) }
}
