# Understanding the app

## Start with the path one refresh takes

1. `main.swift` starts the macOS application.
2. `AppDelegate` creates an `NSStatusItem`, the text item in the menu bar.
3. `refresh()` asks the usage client for a new reading on a background queue.
4. `UsageClient` starts Codex's bundled command-line executable as a child process.
5. The client writes an `initialize` JSON request, waits for the reply, then sends `initialized` and `account/rateLimits/read`.
6. `UsageDecoder` checks the returned data and creates a `UsageSnapshot`.
7. Back on the main thread, the app updates the menu and checks whether an alert is due.

The UI never has to know how pipes work. The client never has to know how menu items work. That boundary is the main architectural decision.

## Swift terms you will see

- A **struct** groups related data or behavior. `UsageWindow` represents a measured allowance window.
- A **class** can hold changing shared state. `AppDelegate` owns the menu, timers, and latest reading.
- A **protocol** describes an interface. `UsageFetching` says that a usage client must provide `fetch()`.
- An **optional**, written with `?`, means a value may be absent. Weekly allowance does not exist in every response.
- `guard` checks a requirement and exits early if it is not met.
- `throws` means a function can fail. `do`/`catch` lets its caller handle the failure.
- A **closure** is a block of behavior passed as a value, such as the action a timer performs.
- `Codable` converts supported Swift values to and from data such as JSON. `Decodable` handles reading only.

## Why Swift and AppKit?

The app is specifically for macOS, so AppKit gives it direct access to menu-bar controls. Swift compiles into a native executable. There is no Python environment to install or bundle, and the app can use Apple's notification and login-item frameworks directly.

SwiftUI could be used for a larger preferences window. This app's small menu does not need one.

## What does the CLI integration mean?

A CLI is a command-line interface. We use the executable already included with ChatGPT/Codex. A child process is another program started by our app.

A pipe carries bytes between the two processes. We send JSON messages through standard input and read replies through standard output. Each message ends with a newline. A reply can arrive in pieces, so the client accumulates bytes until a complete line exists.

`poll()` waits for available bytes with a deadline. It prevents a quiet or stalled server from blocking a refresh indefinitely. A size limit prevents unexpected output from growing memory without bound. The client closes its pipes and ends its child process when finished.

## How do we know which percentage to show?

The response reports a percentage **used**. The menu shows a percentage **remaining**:

```text
remaining = floor(100 - used)
```

We select windows by duration, not their order in the response. Five hours is 300 minutes; a week is 10,080 minutes. Weekly data must not become five-hour data just because it is the first window returned.

The server supplies the reset timestamp. We format it using the Mac's local time. We do not assume the reset is exactly five hours from when the app starts.

## How do notifications avoid repeating?

`AlertPolicy` decides whether a threshold is due. The notification manager reads saved history for the account and reset window. After macOS accepts the notification request, the manager records the covered thresholds.

For example:

```text
23% -> no alert
19% -> one 20% alert
18% -> no repeat
 9% -> one 10% alert
```

If the first reading is 9%, it sends only the lower alert and marks both thresholds covered. A new reset window makes thresholds eligible again. Reset timestamps can jitter slightly; the history tolerates a difference of up to one minute for the same account.

The notification manager cannot guarantee a visible banner: macOS permissions and Focus mode still control presentation.

## Why keep tests separate from the UI?

Quota selection, validation, and threshold decisions can be checked without clicking a menu or using a real account. Those are the most important places to catch a plausible-looking wrong result.

The client tests run a tiny fake command-line server to check behavior when replies arrive in pieces, never arrive, or return an error. UI permission prompts and login after reboot still require manual checks.

## Questions to practice answering

- Why did you choose a menu-bar app instead of a Shortcut?
- What does the app build itself, and what information comes from Codex?
- Why are requests performed on a background queue?
- What is the difference between a 20-second request timeout and a five-minute refresh interval?
- How do you prevent weekly usage being displayed as five-hour usage?
- Why show `--%` when data is unavailable instead of showing `100%`?
- What happens if the CLI changes after an update?
- Why does notification history include both the account and reset window?

A useful explanation is specific: describe one actual decision, its alternative, and the tradeoff. It is fine to look up syntax. Understanding the behavior and being able to change it matters more than memorizing every line.
