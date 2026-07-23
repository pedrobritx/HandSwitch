//
//  GeneralSettingsView.swift
//  HandSwitch
//

import SwiftUI

/// General settings: mode, how changes are applied, and launch at login.
struct GeneralSettingsView: View {
    @Bindable var model: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Picker(selection: $model.handedness) {
                    Text(Handedness.right.displayName).tag(Handedness.right)
                    Text(Handedness.left.displayName).tag(Handedness.left)
                } label: {
                    Text("Mouse mode")
                }
                .pickerStyle(.segmented)
                .accessibilityHint(Text("Switches the primary mouse button."))
            } header: {
                Text("Mode")
            }

            Section {
                Picker("Apply changes using", selection: $model.applyStrategy) {
                    ForEach(ApplyStrategy.allCases) { strategy in
                        Text(strategy.displayName).tag(strategy)
                    }
                }
                Text(model.applyStrategy.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if model.needsAccessibilityGrant {
                    AccessibilityGrantRow(
                        onGrant: { model.requestAccessibility() },
                        onOpenSettings: { model.openAccessibilitySettings() }
                    )
                }
            } header: {
                Text("How it applies")
            }

            Section {
                Toggle("Launch HandSwitch at login", isOn: $model.launchAtLoginEnabled)
                if let error = model.launchAtLoginError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
        .motionAwareAnimation(model.needsAccessibilityGrant)
    }
}

/// A warning row prompting the user to grant Accessibility permission.
private struct AccessibilityGrantRow: View {
    let onGrant: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.orange)
                .imageScale(.large)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text("Instant mode needs Accessibility permission to switch buttons live.")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Grant Permission…", action: onGrant)
                        .buttonStyle(.borderedProminent)
                    Button("Open Settings", action: onOpenSettings)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
