//
//  SettingsStoreTests.swift
//  HandSwitchTests
//

import Foundation
import Testing
@testable import HandSwitch

@MainActor
@Suite("SettingsStore")
struct SettingsStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "com.handswitch.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test("provides sensible defaults on first launch")
    func defaultValues() {
        let store = SettingsStore(defaults: makeDefaults())
        #expect(store.lastHandedness == .right)
        #expect(store.applyStrategy == .systemSetting)
        #expect(store.notificationsEnabled == true)
        #expect(store.toggleShortcut == .defaultToggle)
    }

    @Test("persists values across instances")
    func persistence() {
        let defaults = makeDefaults()
        let first = SettingsStore(defaults: defaults)
        first.lastHandedness = .left
        first.applyStrategy = .instant
        first.notificationsEnabled = false
        first.toggleShortcut = KeyCombo(keyCode: 15, modifiers: [.command, .shift])

        let second = SettingsStore(defaults: defaults)
        #expect(second.lastHandedness == .left)
        #expect(second.applyStrategy == .instant)
        #expect(second.notificationsEnabled == false)
        #expect(second.toggleShortcut == KeyCombo(keyCode: 15, modifiers: [.command, .shift]))
    }
}
