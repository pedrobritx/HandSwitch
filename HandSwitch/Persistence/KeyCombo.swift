//
//  KeyCombo.swift
//  HandSwitch
//
//  A Codable representation of a global keyboard shortcut, with display and
//  Carbon-mapping helpers.
//

import Foundation

/// A set of modifier keys for a global shortcut.
///
/// The raw values deliberately match the Carbon modifier masks
/// (`cmdKey`, `shiftKey`, `optionKey`, `controlKey`) so a combo can be handed
/// straight to `RegisterEventHotKey` without translation.
struct KeyModifiers: OptionSet, Codable, Sendable, Hashable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    /// ⌘ — `cmdKey` (`1 << 8`).
    static let command = KeyModifiers(rawValue: 1 << 8)
    /// ⇧ — `shiftKey` (`1 << 9`).
    static let shift = KeyModifiers(rawValue: 1 << 9)
    /// ⌥ — `optionKey` (`1 << 11`).
    static let option = KeyModifiers(rawValue: 1 << 11)
    /// ⌃ — `controlKey` (`1 << 12`).
    static let control = KeyModifiers(rawValue: 1 << 12)

    /// The modifier symbols in Apple's canonical menu order (⌃⌥⇧⌘).
    var displaySymbols: String {
        var result = ""
        if contains(.control) { result += "⌃" }
        if contains(.option) { result += "⌥" }
        if contains(.shift) { result += "⇧" }
        if contains(.command) { result += "⌘" }
        return result
    }

    /// Whether at least one modifier that macOS requires for a global hotkey is
    /// present. (A bare key without modifiers is rejected.)
    var isSufficientForGlobalHotKey: Bool {
        contains(.command) || contains(.control) || contains(.option)
    }
}

/// A key + modifier combination that can be registered as a system-wide hotkey.
struct KeyCombo: Codable, Equatable, Sendable {
    /// The hardware-independent virtual key code (Carbon `kVK_*`).
    var keyCode: UInt32
    /// The modifiers held with the key.
    var modifiers: KeyModifiers

    init(keyCode: UInt32, modifiers: KeyModifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// The Carbon modifier mask for `RegisterEventHotKey`.
    var carbonModifiers: UInt32 { modifiers.rawValue }

    /// A human-readable representation such as `⌃⌥⌘M`.
    var displayString: String {
        modifiers.displaySymbols + (Self.keyDisplayNames[keyCode] ?? "?")
    }

    /// Whether the combo is valid to register (has a known key and at least one
    /// significant modifier).
    var isValid: Bool {
        modifiers.isSufficientForGlobalHotKey && Self.keyDisplayNames[keyCode] != nil
    }

    /// The suggested default toggle shortcut, ⌃⌥⌘M.
    static let defaultToggle = KeyCombo(
        keyCode: 46, // kVK_ANSI_M
        modifiers: [.control, .option, .command]
    )

    /// A display table mapping virtual key codes to their on-screen glyphs.
    ///
    /// Covers the ANSI letters, digits, common punctuation, whitespace, and
    /// navigation keys — everything a user is likely to bind to a global toggle.
    static let keyDisplayNames: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C",
        9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9",
        26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U", 33: "[",
        34: "I", 35: "P", 37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
        43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 50: "`",
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 71: "⌧",
        76: "⌤", 65: ".", 67: "*", 69: "+", 75: "/", 78: "-", 81: "=",
        82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5", 88: "6",
        89: "7", 91: "8", 92: "9",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        115: "↖", 116: "⇞", 117: "⌦", 119: "↘", 121: "⇟",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
    ]
}
