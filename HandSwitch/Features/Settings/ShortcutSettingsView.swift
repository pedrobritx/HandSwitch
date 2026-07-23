//
//  ShortcutSettingsView.swift
//  HandSwitch
//

import SwiftUI

/// Lets the user view and change the global toggle shortcut.
struct ShortcutSettingsView: View {
    let model: SettingsViewModel

    var body: some View {
        Form {
            Section {
                LabeledContent("Toggle handedness") {
                    ShortcutRecorderView(combo: model.toggleShortcut) { newCombo in
                        model.updateShortcut(newCombo)
                    }
                    .frame(width: 170, height: 24)
                    .accessibilityLabel(Text("Toggle handedness shortcut"))
                    .accessibilityValue(Text(model.toggleShortcut.displayString))
                }
                Button("Reset to Default (⌃⌥⌘M)") {
                    model.resetShortcut()
                }
            } header: {
                Text("Global Keyboard Shortcut")
            } footer: {
                Text("Press this shortcut from any app to switch modes. Click the field and type a new combination, or press Escape to cancel.")
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
    }
}
