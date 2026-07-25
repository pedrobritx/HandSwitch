<div align="center">

# HandSwitch

**Switch your mouse between right‑handed and left‑handed in a single click.**

A lightweight, native macOS menu‑bar utility for anyone who needs to alternate
their pointing hand — because of RSI, tendinitis, cubital tunnel, tennis elbow,
or a temporary injury. macOS already lets you swap the primary mouse button, but
the setting is buried deep in System Settings. HandSwitch turns it into one
click, one shortcut, one Siri command.

[**Download**](https://github.com/pedrobritx/HandSwitch/releases/latest) ·
[**Website**](https://pedrobritx.github.io/HandSwitch/) ·
[**Documentation**](Documentation/)

![macOS 26+](https://img.shields.io/badge/macOS-26%2B-0A84FF?style=flat-square)
![Swift 6](https://img.shields.io/badge/Swift-6-5E5CE6?style=flat-square)
![License: MIT](https://img.shields.io/badge/License-MIT-4db8c8?style=flat-square)

</div>

---

## Overview

HandSwitch lives in the menu bar and does exactly one thing, beautifully:

- **Left‑click** the icon → instantly toggles handedness.
- **Right‑click** the icon → opens the full menu.
- The icon shows the live mode: 🖱 **R** or 🖱 **L**.

Under the hood it flips the real macOS setting
(`com.apple.mouse.swapLeftRightButtons`) — the same value System Settings writes
— so the change is genuine and system‑wide. An optional **Instant** mode uses a
`CGEventTap` (with Accessibility permission) to switch the very next click on
every macOS version.

## Features

- **One‑click toggle** from the menu bar, a global keyboard shortcut, Shortcuts,
  Spotlight, Control Center, or Siri.
- **Live menu‑bar icon** that reflects the current mode and adapts to light,
  dark, and tinted menu bars.
- **Native notifications** — “Left‑handed mode enabled” / “Right‑handed mode
  enabled”.
- **Global keyboard shortcut**, default **⌃⌥⌘M**, fully customizable.
- **App Intents & Siri** — four actions (Toggle, Enable Left‑Handed, Enable
  Right‑Handed, Get Current Mode) available everywhere the moment you launch the
  app.
- **Launch at Login** via the modern `SMAppService` API — no login‑item hacks.
- **Two apply strategies**: the real system setting (default, no permissions) or
  an instant event‑tap mode.
- **Never fails silently** — if a macOS version blocks the change, HandSwitch
  explains why and offers to open the right System Settings pane.
- **Accessible** — VoiceOver labels, Dynamic Type, keyboard navigation, high
  contrast, and Reduce Motion support.

## Screenshots

> _Placeholders — capture on a Mac running the app._

| Menu bar | Menu | Settings | About |
| :------: | :--: | :------: | :---: |
| _`docs/screenshot-menubar.png`_ | _`docs/screenshot-menu.png`_ | _`docs/screenshot-settings.png`_ | _`docs/screenshot-about.png`_ |

## Installation

### Requirements

- **macOS 26 or later**
- **Xcode 26 or later** (Swift 6) — only if you're building from source

### Download (recommended)

1. Grab the latest `HandSwitch-x.y.z.dmg` from the
   [**Releases**](https://github.com/pedrobritx/HandSwitch/releases/latest) page.
2. Open the DMG and **drag HandSwitch into your Applications folder**.
3. Launch it. HandSwitch has no window — look for the 🖱 **R** / **L** icon in
   your menu bar.

#### First launch: "HandSwitch is damaged" / "cannot be opened"

Current builds are **not signed with an Apple Developer ID**, so macOS blocks
them on first launch. This is Gatekeeper doing its job, not a broken download.

To open it:

> **System Settings › Privacy & Security** → scroll down to the message about
> HandSwitch being blocked → click **Open Anyway** → confirm.

macOS 15 removed the old Control-click → Open shortcut for unsigned apps, so the
System Settings route above is the reliable one. If you'd rather use the
terminal, this does the same thing in one line:

```bash
xattr -dr com.apple.quarantine /Applications/HandSwitch.app
```

#### Known limitation of unsigned builds

macOS ties the **Accessibility** permission to an app's code signature. Unsigned
builds get a new signature every time they're rebuilt, so after installing an
update you may need to **re-grant Accessibility permission** for *Instant* mode —
sometimes by removing HandSwitch from the list in **System Settings › Privacy &
Security › Accessibility** and adding it back.

The default **System setting** mode is unaffected. Both issues disappear once the
app is signed and notarized with an Apple Developer ID.

### Build from source

```bash
git clone https://github.com/pedrobritx/HandSwitch.git
cd HandSwitch
open HandSwitch.xcodeproj      # then press ⌘R
```

Xcode may ask you to select a Development Team (Signing & Capabilities → Team).

### Building a DMG yourself

```bash
brew install create-dmg        # optional, but gives the styled install window
./Scripts/build-dmg.sh         # → dist/HandSwitch-1.0.dmg
```

To produce a signed, notarized DMG, set your identity and a stored
`notarytool` profile — the script handles the rest:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="handswitch-notary" \
./Scripts/build-dmg.sh
```

### Cutting a release

Pushing a `v*` tag builds the DMG on a macOS runner and publishes a GitHub
Release with it attached:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

### Regenerating the project (optional)

The project is also described declaratively in `project.yml`. If you ever need
to regenerate the Xcode project, use [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
```

### Regenerating artwork (optional)

```bash
pip install Pillow
python3 Tools/generate_appicon.py         # app icon → Assets.xcassets
python3 Tools/generate_dmg_background.py  # DMG installer backdrop → Resources/dmg
```

## Permissions

HandSwitch runs **outside the App Sandbox** (with the Hardened Runtime). Writing
the global mouse preference and installing a `CGEventTap` both require an
unsandboxed process. See [`Documentation/Permissions.md`](Documentation/Permissions.md)
for details.

- **No permission** is needed for the default **System setting** mode.
- **Accessibility** permission is required only for the optional **Instant**
  mode. HandSwitch requests it on demand and reflects the state live in
  Settings.
- **Notifications** permission is requested once so mode changes can be
  announced.

## Architecture

MVVM with a clean separation between UI, business logic, the system layer,
persistence, and the Shortcuts/App Intents surface. The single source of truth
is the macOS preference; a `DistributedNotificationCenter` bus keeps the app,
App Intents, and Shortcuts consistent. See
[`Documentation/Architecture.md`](Documentation/Architecture.md).

```
HandSwitch/
├── App/           App entry, delegate, composition root, windows
├── Models/        Handedness, ApplyStrategy, HandednessError
├── ViewModels/    HandednessController, SettingsViewModel
├── Services/      System‑preference & event‑tap mechanisms, hotkey,
│                  notifications, launch‑at‑login, accessibility, sync bus
├── Features/
│   ├── MenuBar/   NSStatusItem controller, live icon, menu
│   └── Settings/  SwiftUI settings, shortcut recorder, About
├── Shortcuts/     App Intents + AppShortcutsProvider
├── Persistence/   SettingsStore, KeyCombo
├── Accessibility/ Reduce‑motion & VoiceOver helpers
└── Resources/     Assets, Info.plist, entitlements, string catalog
```

## Shortcuts

Every action appears automatically in the **Shortcuts** app, Spotlight, Control
Center, and Siri — no setup required. Example Siri phrases:

- “Toggle HandSwitch.”
- “Enable left‑handed mode with HandSwitch.”
- “Switch my mouse with HandSwitch.”

Because the actions are App Intents, you can also assign them to a keyboard
shortcut, a Stream Deck, or an automation. See
[`Documentation/Shortcuts.md`](Documentation/Shortcuts.md).

## Accessibility

HandSwitch is built to be usable by everyone:

- **VoiceOver** labels on the menu‑bar item and every control.
- **Dynamic Type** via system text styles.
- **Keyboard navigable** settings.
- **High contrast** through system colors.
- **Reduce Motion** honored — animations become instant when the setting is on.

## License

HandSwitch is released under the **MIT License**. See [`LICENSE`](LICENSE).

## Contributing

Contributions are welcome! Please:

1. Keep the app minimal, native, and HIG‑compliant.
2. Match the strict SwiftLint configuration (`.swiftlint.yml`) — no force
   unwraps, no force casts.
3. Add or update unit tests for behavior changes.
4. Run the test suite (`⌘U`) before opening a pull request.
