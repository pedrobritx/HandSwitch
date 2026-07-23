//
//  HandSwitchShortcuts.swift
//  HandSwitch
//
//  Exposes the app's intents to Shortcuts, Spotlight, Control Center, and Siri
//  with ready-made phrases — no configuration required from the user.
//

import AppIntents

/// Registers HandSwitch's App Shortcuts and their Siri phrases.
///
/// Every phrase includes the `\(.applicationName)` token, as required by Siri.
struct HandSwitchShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleHandednessIntent(),
            phrases: [
                "Toggle \(.applicationName)",
                "Switch my mouse with \(.applicationName)",
                "Switch handedness in \(.applicationName)"
            ],
            shortTitle: "Toggle Mouse Mode",
            systemImageName: "arrow.left.arrow.right"
        )
        AppShortcut(
            intent: EnableLeftHandedIntent(),
            phrases: [
                "Enable left-handed mode with \(.applicationName)",
                "Turn on left-handed mode in \(.applicationName)"
            ],
            shortTitle: "Left-Handed Mode",
            systemImageName: "hand.point.left.fill"
        )
        AppShortcut(
            intent: EnableRightHandedIntent(),
            phrases: [
                "Enable right-handed mode with \(.applicationName)",
                "Turn on right-handed mode in \(.applicationName)"
            ],
            shortTitle: "Right-Handed Mode",
            systemImageName: "hand.point.right.fill"
        )
        AppShortcut(
            intent: GetCurrentModeIntent(),
            phrases: [
                "What mouse mode is \(.applicationName) using",
                "Get my mouse mode from \(.applicationName)"
            ],
            shortTitle: "Current Mouse Mode",
            systemImageName: "questionmark.circle"
        )
    }
}
