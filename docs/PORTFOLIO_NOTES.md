# Portfolio project summary

## Short description

Codex Allowance is a native macOS menu-bar utility written in Swift and AppKit. It shows the user's five-hour usage remaining and reset time without switching windows, with weekly usage, saved display preferences, optional threshold notifications, and optional launch at login.

## Problem

Checking an allowance through an account menu interrupts the current task. The goal was to keep a compact, useful reading visible while working.

## Decisions worth explaining

- Use a native status item for a persistent display; a pinned Shortcut does not provide a dynamic status label.
- Replace an assumed log path with structured account-usage data from the bundled CLI.
- Keep CLI integration separate from data validation, UI, preferences, and notification policy.
- Fail visibly when data is unavailable rather than implying a full allowance.
- Select windows by duration and validate the product bucket.
- Test the difficult failure cases using synthetic responses and a fake CLI.

## Limits to disclose

This uses the bundled Codex CLI interface, which can change, rather than a guaranteed public quota API. It is a local ad-hoc-signed app; public distribution needs proper signing, notarization, and broader compatibility tests. Notification banners and login behavior depend on macOS permissions and settings.

## Demo outline

1. Show the five-hour percentage and reset time in the menu bar.
2. Open the menu to show weekly usage and the last update.
3. Toggle weekly display and countdown, then restore the preferred view.
4. Explain alerts at 20% and 10%; demonstrate the automated threshold tests rather than exhausting a real account.
5. Show the source map and one failure-handling test.

## Skills demonstrated

Native macOS development, Swift data modeling, inter-process communication, defensive parsing, background execution, local preferences, notification policy, and automated testing.

## Evidence

The local application was built, installed, and checked against live account data. Twenty synthetic tests cover core validation, alert decisions, and CLI failure handling. See [the testing notes](TESTING.md) for the full scope and remaining manual checks.

## Suggested portfolio title

**Codex Allowance — Native macOS Developer Utility**
