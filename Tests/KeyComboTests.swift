//
//  KeyComboTests.swift
//  HandSwitchTests
//

import Foundation
import Testing
@testable import HandSwitch

@Suite("KeyCombo")
struct KeyComboTests {
    @Test("default toggle is ⌃⌥⌘M")
    func defaultToggle() {
        #expect(KeyCombo.defaultToggle.displayString == "⌃⌥⌘M")
        #expect(KeyCombo.defaultToggle.keyCode == 46)
        #expect(KeyCombo.defaultToggle.isValid)
    }

    @Test("carbon modifiers equal the raw modifier mask")
    func carbonModifiers() {
        let combo = KeyCombo(keyCode: 46, modifiers: [.control, .option, .command])
        #expect(combo.carbonModifiers == combo.modifiers.rawValue)
    }

    @Test("modifier symbols follow the canonical ⌃⌥⇧⌘ order")
    func modifierOrder() {
        let all: KeyModifiers = [.command, .shift, .option, .control]
        #expect(all.displaySymbols == "⌃⌥⇧⌘")
    }

    @Test("a combo without significant modifiers is invalid")
    func requiresModifier() {
        let bare = KeyCombo(keyCode: 46, modifiers: [])
        #expect(bare.isValid == false)
        let shiftOnly = KeyCombo(keyCode: 46, modifiers: [.shift])
        #expect(shiftOnly.isValid == false)
    }

    @Test("an unknown key code is invalid")
    func unknownKey() {
        let combo = KeyCombo(keyCode: 9999, modifiers: [.command])
        #expect(combo.isValid == false)
    }

    @Test("combo encodes and decodes losslessly")
    func codableRoundTrip() throws {
        let original = KeyCombo(keyCode: 15, modifiers: [.command, .shift])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyCombo.self, from: data)
        #expect(decoded == original)
    }
}
