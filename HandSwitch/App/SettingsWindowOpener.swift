//
//  SettingsWindowOpener.swift
//  HandSwitch
//
//  Opens the SwiftUI Settings scene from AppKit (the menu-bar menu).
//

import AppKit

/// Opens the app's Settings window, activating the app first so it comes
/// forward for a menu-bar (accessory) app.
@MainActor
enum SettingsWindowOpener {
    static func open() {
        NSApp.activate(ignoringOtherApps: true)
        // macOS 14+ uses `showSettingsWindow:`; fall back for safety.
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
