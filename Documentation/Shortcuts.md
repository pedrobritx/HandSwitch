# Shortcuts, Siri & Automation

HandSwitch exposes its actions as **App Intents**, so they appear automatically
across the system the first time you launch the app — no configuration needed.

## Actions

| Intent | What it does | Returns |
| --- | --- | --- |
| **Toggle HandSwitch** | Switches to the opposite mode | The new mode |
| **Enable Left‑Handed Mode** | Makes the right button primary | `Left-handed` |
| **Enable Right‑Handed Mode** | Makes the left button primary | `Right-handed` |
| **Get Current Mode** | Reads the current mode | `Right-handed` / `Left-handed` |

## Where they show up

- **Shortcuts app** — drag any action into a shortcut.
- **Spotlight** — search the action name and run it.
- **Control Center / menu bar** — via a Shortcut you pin.
- **Siri** — speak a phrase (below).
- **Automations** — time‑, focus‑, or trigger‑based.
- **Stream Deck** and similar — by binding a Shortcut.

## Siri phrases

Every phrase includes the app name, as Siri requires:

- “Toggle HandSwitch.”
- “Switch my mouse with HandSwitch.”
- “Enable left‑handed mode with HandSwitch.”
- “Enable right‑handed mode with HandSwitch.”
- “What mouse mode is HandSwitch using?”

## Global keyboard shortcut

Separately from Shortcuts, HandSwitch registers one **global hotkey**
(default **⌃⌥⌘M**) using Carbon's `RegisterEventHotKey`. Change it in
**Settings › Shortcut** — click the field and type a new combination, or press
**Escape** to cancel. The combination must include at least one of ⌃, ⌥, or ⌘.
