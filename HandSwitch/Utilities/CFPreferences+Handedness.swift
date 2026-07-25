//
//  CFPreferences+Handedness.swift
//  HandSwitch
//
//  A thin, typed wrapper around the Core Foundation preferences APIs for the
//  global, per-host domain that stores the mouse button-swap setting.
//

import Foundation

/// A minimal, typed wrapper over the Core Foundation preferences APIs for the
/// global (`kCFPreferencesAnyApplication`), current-user, current-host domain.
///
/// This is the exact domain System Settings uses to persist the
/// `com.apple.mouse.swapLeftRightButtons` value (it is a "ByHost" preference,
/// equivalent to `defaults -currentHost`).
enum GlobalHostPreference {
    /// The macOS key that records whether the primary and secondary mouse
    /// buttons are swapped (`true` = swapped = left-handed).
    ///
    /// Held as a `String` rather than a `CFString`: `CFString` is a
    /// non-`Sendable` class, so it cannot be stored in a shared static under
    /// strict concurrency. `String` is `Sendable`, and the toll-free bridge to
    /// `CFString` happens at each call site instead — no unsafe opt-out needed.
    static let swapButtonsKey = "com.apple.mouse.swapLeftRightButtons"

    /// Reads a boolean value from the current-host global domain.
    ///
    /// - Parameter key: The preference key to read.
    /// - Returns: The stored value, or `nil` if the key has never been set.
    static func bool(forKey key: String) -> Bool? {
        guard let value = CFPreferencesCopyValue(
            key as CFString,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesCurrentHost
        ) else {
            return nil
        }
        // The value bridges to `NSNumber` whether it was stored as a CFBoolean
        // or a CFNumber; read it defensively without a force cast.
        if let number = value as? NSNumber {
            return number.boolValue
        }
        return nil
    }

    /// Writes a boolean value to the current-host global domain and flushes it
    /// to disk.
    ///
    /// - Parameters:
    ///   - newValue: The value to store.
    ///   - key: The preference key to write.
    /// - Returns: `true` if the synchronize call reported success.
    @discardableResult
    static func setBool(_ newValue: Bool, forKey key: String) -> Bool {
        // `NSNumber(value:)` for a `Bool` bridges to the shared CFBoolean
        // instances, so the value is persisted as a proper boolean.
        CFPreferencesSetValue(
            key as CFString,
            NSNumber(value: newValue) as CFPropertyList,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesCurrentHost
        )
        return CFPreferencesSynchronize(
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesCurrentHost
        )
    }
}
