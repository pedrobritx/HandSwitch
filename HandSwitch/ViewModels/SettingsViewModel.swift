//
//  SettingsViewModel.swift
//  HandSwitch
//
//  Backs the Settings window, translating UI intents into service calls and
//  keeping mirrored state (launch-at-login, Accessibility) consistent.
//

import Foundation
import Observation

/// View model for the Settings window.
@MainActor
@Observable
final class SettingsViewModel {
    @ObservationIgnored let settings: SettingsStore
    @ObservationIgnored let controller: HandednessController
    @ObservationIgnored let accessibility: AccessibilityAuthorization
    @ObservationIgnored private let launchAtLogin: LaunchAtLoginService
    @ObservationIgnored private let onShortcutChanged: @MainActor (KeyCombo) -> Void

    /// A user-facing message if toggling launch-at-login failed.
    private(set) var launchAtLoginError: String?

    init(
        settings: SettingsStore,
        controller: HandednessController,
        accessibility: AccessibilityAuthorization,
        launchAtLogin: LaunchAtLoginService,
        onShortcutChanged: @escaping @MainActor (KeyCombo) -> Void
    ) {
        self.settings = settings
        self.controller = controller
        self.accessibility = accessibility
        self.launchAtLogin = launchAtLogin
        self.onShortcutChanged = onShortcutChanged
        // Reconcile the persisted mirror with the authoritative system state.
        settings.launchAtLoginEnabled = launchAtLogin.isEnabled
    }

    // MARK: - Launch at login

    var launchAtLoginEnabled: Bool {
        get { settings.launchAtLoginEnabled }
        set { setLaunchAtLogin(newValue) }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLogin.setEnabled(enabled)
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
            Log.settings.error("Launch-at-login change failed: \(error.localizedDescription, privacy: .public)")
        }
        // Always mirror the authoritative status back into the UI.
        settings.launchAtLoginEnabled = launchAtLogin.isEnabled
    }

    // MARK: - Notifications

    var notificationsEnabled: Bool {
        get { settings.notificationsEnabled }
        set { settings.notificationsEnabled = newValue }
    }

    // MARK: - Apply strategy

    var applyStrategy: ApplyStrategy {
        get { settings.applyStrategy }
        set { controller.setApplyStrategy(newValue) }
    }

    /// Whether the current strategy needs Accessibility permission that is not
    /// yet granted.
    var needsAccessibilityGrant: Bool {
        settings.applyStrategy.requiresAccessibility && !accessibility.isTrusted
    }

    func requestAccessibility() {
        accessibility.promptForAccess()
    }

    func openAccessibilitySettings() {
        accessibility.openSettings()
    }

    // MARK: - Handedness

    var handedness: Handedness {
        get { controller.current }
        set { controller.set(newValue) }
    }

    // MARK: - Shortcut

    var toggleShortcut: KeyCombo { settings.toggleShortcut }

    func updateShortcut(_ combo: KeyCombo) {
        guard combo.isValid else { return }
        settings.toggleShortcut = combo
        onShortcutChanged(combo)
    }

    func resetShortcut() {
        updateShortcut(.defaultToggle)
    }
}
