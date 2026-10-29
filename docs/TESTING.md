# Testing and verification

## Run automated checks

```bash
./scripts/test.sh
./scripts/build.sh
```

The 20 XCTest tests use synthetic JSON and a temporary fake CLI executable. They do not require sign-in or access a real usage account.

| Area | Tests | Checks |
| --- | ---: | --- |
| Decoder and display | 12 | Window selection, weekly-only responses, wrong product, expired/invalid values, malformed JSON, nulls, booleans, duplicate durations, legacy responses, rounding, countdowns |
| Alert policy and history | 4 | Thresholds, no repeats, jumping below 10%, saved history, reset jitter, account/window changes |
| CLI transport | 4 | Initialization, split replies, timeout, early exit, safe RPC errors |

Local result: **20 passed, 0 failed** during version 2.0 verification. The GitHub Actions workflow runs the synthetic test suite and packages the app on a macOS runner; its actual check status is shown in GitHub, separately from this local result.

## Manual acceptance checklist

These are checks to perform, not a claim they have all been completed.

- [ ] Build and launch the packaged app; confirm no main window or Dock icon appears.
- [ ] Compare the five-hour percentage and reset time with the matching signed-in account.
- [ ] Open the menu and confirm both weekly usage and the last-update time.
- [ ] Toggle weekly text and countdown; quit/relaunch and confirm choices persist.
- [ ] Refresh manually and verify the interface stays responsive.
- [ ] Sleep/wake the Mac and confirm a new reading is requested.
- [ ] Enable notifications and handle the macOS permission prompt.
- [ ] Confirm banner behavior with the user's Focus/notification settings. Avoid deliberately exhausting a real allowance just to test a threshold; threshold logic has synthetic tests.
- [ ] Enable Launch at Login, approve it if requested, and check after logging out and back in.
- [ ] Disable Launch at Login and verify its state in System Settings.
- [ ] Temporarily test an unavailable account/CLI in a controlled environment and confirm `--% · --:--`.

## Live-data check

```bash
"dist/Codex Allowance.app/Contents/MacOS/CodexAllowance" --check
```

Unlike the unit tests, this invokes the installed bundled CLI using its normal account configuration. Success prints the current display text and returns zero. Failure prints the placeholder, reports a short error to stderr, and returns nonzero.

Do not paste raw authentication files, account responses, conversation text, or full application logs into an issue. The app's short error message and a description of the visible behavior are usually enough to start.

## Coverage boundaries

The tests do not prove compatibility with every CLI release, guarantee macOS permission approval, measure energy use, or verify actual notification banners. The app has not been validated across all supported macOS versions or Intel Macs. CI uses simulated responses and cannot validate personal account integration.
