# Architecture

HandSwitch follows MVVM with a strict separation of concerns and Swift 6 strict
concurrency throughout. Every layer is small, injectable, and testable.

## Layers

| Layer | Types | Responsibility |
| --- | --- | --- |
| **App** | `HandSwitchApp`, `AppDelegate`, `AppEnvironment` | Entry point, accessory activation, composition root |
| **Models** | `Handedness`, `ApplyStrategy`, `HandednessError` | Pure, `Sendable` domain values |
| **ViewModels** | `HandednessController`, `SettingsViewModel` | Business logic, `@Observable`, `@MainActor` |
| **Services** | mechanisms, hotkey, notifications, launch‑at‑login, accessibility, sync bus | The system layer |
| **Persistence** | `SettingsStore`, `KeyCombo` | `UserDefaults`-backed state |
| **Features** | `MenuBar/*`, `Settings/*` | UI (AppKit status item + SwiftUI settings) |
| **Shortcuts** | App Intents, `HandednessCoordinator` | Shortcuts / Siri surface |

## The single source of truth

The macOS preference `com.apple.mouse.swapLeftRightButtons` is authoritative.
`HandednessController` is the **only** type that runs a mechanism, which keeps
side effects (event‑tap reconciliation, notifications, cross‑process sync) in one
place and makes double‑swaps impossible.

```
User action ─┐
Global hotkey ┤→ HandednessController.apply(_:) ─┬→ SystemPreferenceMechanism (write + verify)
App Intent ──┘                                    ├→ EventTapMechanism (instant mode)
                                                  ├→ SettingsStore (persist)
                                                  ├→ NotificationService (announce)
                                                  └→ HandednessSyncBus (broadcast)
```

## Mechanisms

`HandednessMechanism` abstracts *how* a change is applied:

- **`SystemPreferenceMechanism`** writes the global, per‑host preference via
  `CFPreferences` and **verifies with a read‑back**. If the value doesn't take,
  it throws `HandednessError.verificationFailed` so the UI can explain and offer
  System Settings.
- **`EventTapMechanism`** installs a `CGEventTap` that swaps left/right button
  events live. It requires Accessibility permission and, while active, the
  controller keeps the OS preference neutral so the two never double‑swap. If the
  tap can't start, the controller **rolls back** the system preference so the UI
  never lies about the current state.

## Cross‑process consistency

For an always‑running menu‑bar app, the system routes App Intents into the live
process, so `HandednessCoordinator` delegates to the shared controller.
`HandednessSyncBus` (a `DistributedNotificationCenter` broadcast) is a
belt‑and‑suspenders layer that keeps any additional process and the menu‑bar
icon in sync, reflecting external changes without re‑running mechanisms (which
would loop).

## Concurrency

- UI and controllers are `@MainActor`.
- Models and value types are `Sendable`.
- The event‑tap and Carbon hotkey C callbacks are self‑contained; shared state
  crosses the boundary through an `OSAllocatedUnfairLock` box, and main‑actor
  work is reached with `MainActor.assumeIsolated` (both callbacks are delivered
  on the main thread).

## Why NSStatusItem instead of MenuBarExtra

The product requires "left‑click toggles, right‑click opens the menu", which
needs precise click routing that `MenuBarExtra` cannot express. `StatusItemController`
uses `NSStatusItem` directly (what `MenuBarExtra` wraps) and renders a live
template image so the icon always matches the menu‑bar appearance.
