# Changelog

## 2.0 — 2026-10-28

- Split the single-file prototype into usage models, a CLI client, UI coordination, preferences, notifications, and login management.
- Added weekly usage in the dropdown and optional menu-bar text.
- Added an optional reset countdown and saved display preferences.
- Added optional low-allowance notifications at 20% and 10%, with persisted alert history.
- Added a native Launch at Login control.
- Added last-update information, readable errors, stale-reading expiration, and duplicate-instance protection.
- Reworked CLI transport with bounded reads and child-process cleanup.
- Added 20 automated tests, reproducible build/test scripts, and project documentation.

## 1.0 — 2026-10-28

- Built and installed the first local Swift/AppKit menu-bar app.
- Displayed five-hour allowance remaining and local reset time.
- Used structured Codex CLI usage data instead of the initially assumed log file.
- Added periodic refresh, wake refresh, and an unavailable-data placeholder.
