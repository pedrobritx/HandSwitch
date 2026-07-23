//
//  HandSwitchApp.swift
//  HandSwitch
//
//  The SwiftUI app entry point. The visible UI lives in the menu bar (created
//  by the app delegate); this scene provides the Settings window.
//

import SwiftUI

/// The HandSwitch application.
@main
struct HandSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(model: AppEnvironment.shared.settingsViewModel)
        }
    }
}
