# Permissions & Sandboxing

## Why HandSwitch is not sandboxed

HandSwitch ships **without the App Sandbox** and **with the Hardened Runtime**.
Two capabilities require an unsandboxed process:

1. **Writing the global mouse preference.** HandSwitch writes
   `com.apple.mouse.swapLeftRightButtons` into the global, per‑host preferences
   domain (`kCFPreferencesAnyApplication`, current host) — the same value System
   Settings writes. The App Sandbox blocks writes to that domain.
2. **The instant event tap.** The optional Instant mode installs a
   `CGEventTap`, which a sandboxed app cannot create.

This is standard for a system utility distributed outside the Mac App Store. The
Hardened Runtime is enabled so the app can still be notarized.

## Accessibility

Accessibility permission (`AXIsProcessTrusted`) is required **only** for the
optional **Instant** apply mode. The default **System setting** mode needs no
permission at all.

- HandSwitch requests Accessibility on demand from Settings, and via
  `AXIsProcessTrustedWithOptions` it shows the system prompt.
- After you grant it in **System Settings › Privacy & Security › Accessibility**,
  HandSwitch detects the change automatically (it polls briefly) and updates the
  UI without needing a relaunch.

## Notifications

HandSwitch requests notification authorization once, so it can post
“Left‑handed mode enabled” / “Right‑handed mode enabled”. Denying it simply
means no banners are shown; the toggle still works.

## Never a silent failure

If macOS refuses a change (an unsupported version, a failed write, or a
verification mismatch), HandSwitch surfaces a clear message and offers to open
the exact System Settings pane:

- **Mouse:** `x-apple.systempreferences:com.apple.Mouse-Settings.extension`
- **Accessibility:** `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
