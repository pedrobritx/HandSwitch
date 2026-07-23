//
//  SettingsStore.swift
//  HandSwitch
//
//  Observable, UserDefaults-backed persistence for user preferences.
//

import Foundation
import Observation

/// The single source of persisted user preferences.
///
/// Backed by `UserDefaults` and injected wherever settings are read or written,
/// so tests can supply an isolated defaults suite. Every property persists on
/// assignment, and observers update automatically through `@Observable`.
@MainActor
@Observable
final class SettingsStore {
    /// The last handedness the user chose. This is a *cache* for fast UI
    /// startup — the authoritative value is always read live from the system.
    var lastHandedness: Handedness {
        didSet { defaults.set(lastHandedness.rawValue, forKey: Keys.lastHandedness) }
    }

    /// How handedness changes are applied.
    var applyStrategy: ApplyStrategy {
        didSet { defaults.set(applyStrategy.rawValue, forKey: Keys.applyStrategy) }
    }

    /// Whether a system notification is posted on each change.
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    /// The user's most recent launch-at-login choice. The authoritative status
    /// lives in `SMAppService`; this mirrors it for the UI.
    var launchAtLoginEnabled: Bool {
        didSet { defaults.set(launchAtLoginEnabled, forKey: Keys.launchAtLogin) }
    }

    /// The global keyboard shortcut that toggles handedness.
    var toggleShortcut: KeyCombo {
        didSet { persistCodable(toggleShortcut, forKey: Keys.toggleShortcut) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    /// Creates a store backed by the given defaults.
    /// - Parameter defaults: The backing store (injected in tests).
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedHandedness = defaults.string(forKey: Keys.lastHandedness)
            .flatMap(Handedness.init(rawValue:))
        lastHandedness = storedHandedness ?? .right

        let storedStrategy = defaults.string(forKey: Keys.applyStrategy)
            .flatMap(ApplyStrategy.init(rawValue:))
        applyStrategy = storedStrategy ?? .systemSetting

        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        launchAtLoginEnabled = defaults.bool(forKey: Keys.launchAtLogin)

        let storedShortcut = (defaults.data(forKey: Keys.toggleShortcut))
            .flatMap { try? JSONDecoder().decode(KeyCombo.self, from: $0) }
        toggleShortcut = storedShortcut ?? .defaultToggle
    }

    private func persistCodable(_ value: some Encodable, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            Log.settings.error("Failed to encode value for key \(key, privacy: .public)")
            return
        }
        defaults.set(data, forKey: key)
    }

    /// UserDefaults key constants.
    private enum Keys {
        static let lastHandedness = "handedness.last"
        static let applyStrategy = "handedness.applyStrategy"
        static let notificationsEnabled = "notifications.enabled"
        static let launchAtLogin = "launchAtLogin.enabled"
        static let toggleShortcut = "shortcut.toggle"
    }
}
