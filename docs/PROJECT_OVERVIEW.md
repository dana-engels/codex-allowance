# Project overview

## At a glance

| Field | Detail |
| --- | --- |
| Project | Codex Allowance |
| Author | Dana Engels |
| Category | Native macOS utility / developer tool |
| Stack | Swift, AppKit, Foundation, ServiceManagement, UserNotifications |
| Build system | Swift Package Manager plus a Bash packaging script |
| Current local version | 2.0 |
| Minimum deployment target | macOS 13 |
| External Swift dependencies | None |
| Usage source | Bundled Codex CLI app-server interface |
| Refresh cadence | Five minutes, manual refresh, and wake from sleep |
| Test coverage | 20 automated tests; see TESTING.md for scope |
| Distribution status | Source available; local builds are ad-hoc signed |

## Problem

The account menu provides a useful allowance reading, but it takes several clicks to check while working in another window. The project makes the five-hour percentage and reset time visible in the macOS menu bar.

The utility focuses on quick awareness. It does not predict usage, replace the account dashboard, or enforce a budget.

## Scope

The app displays the five-hour allowance by default. Weekly information appears in the dropdown and can optionally appear in the menu-bar text. Users can switch between a reset clock time and a countdown, enable low-allowance notifications, and register the app to launch at login.

Only a local preferences file and alert history are saved by this utility. There is no custom web service or database to deploy.

## Implementation decisions

### A native status item

AppKit's `NSStatusItem` provides a persistent menu-bar control without a Dock icon or main window. A Shortcut can trigger an action, but does not supply a dynamic text label in the menu bar.

### Structured usage data rather than log scraping

The initial design assumed usage counters existed in a local log. That path was not available. The working implementation asks the bundled Codex CLI for structured account-usage data through `account/rateLimits/read`.

This resolves the missing-log problem, but introduces a maintenance dependency: the bundled CLI path and protocol can change. Keeping that communication in its own module limits the code affected by such changes.

### Validate before displaying

The decoder selects the Codex bucket and identifies usage windows by duration. It rejects invalid percentages and expired windows. Weekly data is not substituted for a missing five-hour window.

If the request fails, the app clears the displayed reading rather than presenting stale data as current. Successful readings also expire locally after six minutes.

### Keep the interface responsive

Requests run on a background queue. Menu updates happen on the main thread. A single-flight guard prevents simultaneous refresh requests. Transport reads have a deadline and an output-size limit, and the child process is cleaned up when a request ends.

### Make alerts useful rather than repetitive

Notifications use saved history scoped to the account and reset window. If a reading jumps from above 20% to below 10%, the app sends one lower-threshold alert instead of two. Small reset-time variations do not immediately reset alert history.

## Result and evidence

The local app was installed and launched on the development Mac. Live CLI responses were verified against the account's usage display during development. All 20 automated tests passed locally.

Notification presentation and login after reboot remain manual checks. The menu-bar-only app could not be inspected through the available UI automation tool. There are no claimed download counts, user studies, cross-device results, or performance benchmarks.

## Next improvements

- Developer ID signing and notarization for simpler public installation.
- Testing on additional macOS versions, Intel hardware, and account configurations.
- A small preferences window if the menu grows beyond its current scope.
- Support for a documented usage API if one becomes available.

## Portfolio summary

Built a native macOS menu-bar utility in Swift and AppKit that displays Codex allowance and reset times. Separated CLI communication from validation, display, preferences, and notifications, with background refreshes and automated tests for failure cases.
