//
//  NotificationSettingsView.swift
//  HandSwitch
//

import SwiftUI

/// Notification preferences.
struct NotificationSettingsView: View {
    @Bindable var model: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Notify me when the mode changes", isOn: $model.notificationsEnabled)
            } header: {
                Text("Notifications")
            } footer: {
                Text("Shows a brief macOS notification such as “Left-handed mode enabled” whenever you switch.")
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
    }
}
