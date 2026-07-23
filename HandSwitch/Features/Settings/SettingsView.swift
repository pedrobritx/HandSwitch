//
//  SettingsView.swift
//  HandSwitch
//
//  The Settings window: a compact, native tabbed layout.
//

import SwiftUI

/// The root Settings view, hosting the General, Notifications, Shortcut, and
/// About tabs.
struct SettingsView: View {
    let model: SettingsViewModel

    var body: some View {
        TabView {
            GeneralSettingsView(model: model)
                .tabItem { Label("General", systemImage: "gearshape") }

            NotificationSettingsView(model: model)
                .tabItem { Label("Notifications", systemImage: "bell") }

            ShortcutSettingsView(model: model)
                .tabItem { Label("Shortcut", systemImage: "keyboard") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 460)
    }
}
