<div align="center">

# HandSwitch

**Switch your mouse between right‑handed and left‑handed in a single click.**

A lightweight, native macOS menu‑bar utility for anyone who needs to alternate
their pointing hand — because of RSI, tendinitis, cubital tunnel, tennis elbow,
or a temporary injury. macOS already lets you swap the primary mouse button, but
the setting is buried deep in System Settings. HandSwitch turns it into one
click, one shortcut, one Siri command.

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

- **macOS 27 or later**
- **Xcode 27 or later** (Swift 6)

### Build & run

The committed `HandSwitch.xcodeproj` opens and runs directly:

```bash
git clone https://github.com/pedrobritx/handswitch.git
cd handswitch
open HandSwitch.xcodeproj      # then press ⌘R
```

On first run Xcode may ask you to select a Development Team for signing
(Signing & Capabilities → Team).

### Regenerating the project (optional)

The project is also described declaratively in `project.yml`. If you ever need
to regenerate the Xcode project, use [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
```

### Regenerating the app icon (optional)

```bash
pip install Pillow
python3 Tools/generate_appicon.py
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
