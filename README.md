# WiFi Location Switcher

<p align="center">
  <img src="App/AppIcon-1024.png" width="160" alt="WiFi Location Switcher icon">
</p>

A small macOS menu bar app that automatically switches Network Locations based
on the connected Wi-Fi name (SSID).

## What it does

- Add any number of Wi-Fi → Network Location rules.
- Choose an optional fallback location for unmatched Wi-Fi networks.
- Shows the current Wi-Fi and active Network Location.
- Starts automatically after login when enabled.
- Stores all rules locally on the Mac.
- Waits for a stable Wi-Fi connection before switching, preventing loops during
  the brief disconnect caused by applying a Network Location.

Requires macOS 13 or later.

## Install a release

1. Download the ZIP from the GitHub Releases page.
2. Move **WiFi Location Switcher.app** to `/Applications`.
3. Open it and click the router icon in the menu bar.
4. Grant Location Services access. macOS requires this permission before an app
   can read the current Wi-Fi name; the app does not request your physical
   location or send any data anywhere.
5. Add rules and optionally enable **Launch after login**.

Unsigned community builds may require right-clicking the app and choosing
**Open** the first time. A Developer ID signed and notarized release opens
normally.

## Build locally

The project uses Swift Package Manager and does not require an Xcode project.
Apple Command Line Tools or Xcode with Swift 5.9 or later is required.

```bash
swift run SwitcherCoreSelfTest
chmod +x scripts/*.sh
scripts/build_app.sh
scripts/install_local.sh
```

The app and ZIP archive are written to `dist/`.
The build script creates one universal app for both Apple silicon and Intel Macs.

## Signed release

For normal public distribution, use an Apple Developer ID certificate and
notarize the result:

```bash
CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
APP_VERSION=1.0.0 scripts/build_app.sh

NOTARY_PROFILE="your-notarytool-profile" \
APP_VERSION=1.0.0 scripts/notarize_app.sh
```

Without an Apple Developer account, GitHub Actions still creates an ad-hoc
signed ZIP. macOS will show an unverified-developer warning on first launch.

## GitHub releases

Pushes and pull requests run the test/build workflow. Pushing a version tag
creates a GitHub Release automatically:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Privacy

The app reads only the current Wi-Fi name and the Mac's Network Location names.
Rules are saved locally in UserDefaults. There is no analytics, network request,
or external server.

## License

MIT
