# Troubleshooting

## Nothing appears after opening the app

The app has no Dock icon or normal window. Look for the percentage near the other menu-bar items. A crowded menu bar, a display notch, a menu-bar organizer, or macOS auto-hide settings may obscure it. Check Activity Monitor for `CodexAllowance` before opening additional copies.

## The display shows `--% · --:--`

Open the menu and read the short error. Make sure ChatGPT or Codex is installed in `/Applications` or your user's `Applications` folder, and that its bundled CLI can access your sign-in. Click **Refresh Now**.

A missing five-hour window is left unavailable even if weekly data exists. The app also hides expired readings. It never converts unavailable data into `100%`.

If an application update moved the bundled CLI or changed the response schema, the integration may need an update in `Sources/UsageService/UsageClient.swift` or `Sources/AllowanceCore/Usage.swift`.

## The reading differs from the desktop app

The app refreshes every five minutes. Try a manual refresh and confirm the bundled CLI is using the same account as the desktop app. The app uses the server's reset timestamp and the Mac's local time. It does not infer a reset five hours from launch.

## Notifications do not appear

Enable **Low-Allowance Notifications** in the app's menu and allow notifications when macOS asks. Then check System Settings → Notifications and Focus settings.

Alerts apply to the five-hour window and are evaluated only after successful readings. A threshold is recorded after macOS accepts the notification request. macOS still decides whether to show a banner. The app must be running, and already-recorded thresholds do not alert again for the same account/window.

## Launch at Login needs approval or fails

Use the app's menu toggle. If it says approval is required, use **Approve Login Item in System Settings…**. For local ad-hoc-signed builds, manual addition under System Settings → General → Login Items may be necessary.

Keep the app at a stable location before registering it. If you move or replace it, check the login item again. Disable startup before deleting the app.

## Build fails

Confirm Apple's developer tools are installed and `swift --version` reports Swift 5.9 or newer. Run the scripts from a writable checkout on macOS. If build caches are damaged, use a fresh build directory:

```bash
BUILD_DIR="$PWD/.build-clean" ./scripts/test.sh
BUILD_DIR="$PWD/.build-clean" ./scripts/build.sh
```

No third-party Swift packages are required.

## Report a problem

Include the macOS version, whether you built from source, the app version, steps to reproduce, and the short menu error. Redact any account information from images. Never upload credentials, tokens, school or personal browser data, or complete account logs.
