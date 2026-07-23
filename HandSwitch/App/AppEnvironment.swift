//
//  AppEnvironment.swift
//  HandSwitch
//
//  The composition root: constructs and wires every service, the controller,
//  and the settings view model. A shared instance lets App Intents reach the
//  live controller when the system routes them into the running process.
//

import Foundation

/// Owns the app's object graph and exposes it to the UI, the app delegate, and
/// App Intents.
@MainActor
final class AppEnvironment {
    /// The process-wide instance. App Intents rely on this to reach the live
    /// controller; the app delegate and SwiftUI scenes use it as the single
    /// composition root.
    static let shared = AppEnvironment()

    let settings: SettingsStore
    let accessibility: AccessibilityAuthorization
    let launchAtLogin: LaunchAtLoginService
    let notifications: NotificationService
    let systemMechanism: SystemPreferenceMechanism
    let instantMechanism: EventTapMechanism
    let controller: HandednessController
    let hotKeyManager: GlobalHotKeyManager

    private(set) lazy var settingsViewModel = SettingsViewModel(
        settings: settings,
        controller: controller,
        accessibility: accessibility,
        launchAtLogin: launchAtLogin,
        onShortcutChanged: { [weak self] combo in
            self?.registerGlobalShortcut(combo)
        }
    )

    private init() {
        settings = SettingsStore()
        accessibility = AccessibilityAuthorization()
        launchAtLogin = LaunchAtLoginService()
        notifications = NotificationService()
        systemMechanism = SystemPreferenceMechanism()
        instantMechanism = EventTapMechanism(authorization: accessibility)
        controller = HandednessController(
            systemMechanism: systemMechanism,
            instantMechanism: instantMechanism,
            settings: settings,
            announcer: notifications
        )
        hotKeyManager = GlobalHotKeyManager()
    }

    /// Starts runtime services: applies the persisted mode, registers the
    /// global shortcut, requests notification permission, and (for instant
    /// mode) begins watching for Accessibility permission.
    func start() {
        controller.activate()
        registerGlobalShortcut(settings.toggleShortcut)
        Task { await notifications.requestAuthorizationIfNeeded() }
        if settings.applyStrategy.requiresAccessibility {
            accessibility.beginMonitoring()
        }
    }

    /// (Re)registers the global toggle shortcut.
    func registerGlobalShortcut(_ combo: KeyCombo) {
        hotKeyManager.register(combo) { [controller] in
            controller.toggle()
        }
    }

    /// Tears down runtime services on termination.
    func stop() {
        controller.shutdown()
        hotKeyManager.unregister()
    }
}
