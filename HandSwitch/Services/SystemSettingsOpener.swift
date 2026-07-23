//
//  SystemSettingsOpener.swift
//  HandSwitch
//
//  Deep-links into the exact System Settings panes HandSwitch refers users to.
//

import AppKit
import Foundation

/// Opens specific System Settings panes so the app can offer a one-click
/// recovery path when it can't make a change itself.
@MainActor
enum SystemSettingsOpener {
    /// Opens System Settings › Mouse, where "Primary mouse button" lives.
    static func openMouseSettings() {
        open("x-apple.systempreferences:com.apple.Mouse-Settings.extension")
    }

    /// Opens System Settings › Privacy & Security › Accessibility.
    static func openAccessibility() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    private static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            Log.lifecycle.error("Invalid System Settings URL: \(urlString, privacy: .public)")
            return
        }
        NSWorkspace.shared.open(url)
    }
}
