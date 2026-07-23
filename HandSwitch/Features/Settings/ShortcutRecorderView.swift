//
//  ShortcutRecorderView.swift
//  HandSwitch
//
//  A native key-combo recorder backed by a small NSButton subclass.
//

import AppKit
import SwiftUI

/// A SwiftUI wrapper around a click-to-record keyboard-shortcut field.
struct ShortcutRecorderView: NSViewRepresentable {
    /// The combo currently shown.
    let combo: KeyCombo
    /// Called with a new, valid combo once the user records one.
    let onChange: (KeyCombo) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let view = ShortcutRecorderButton()
        view.combo = combo
        view.onCapture = onChange
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderButton, context: Context) {
        nsView.combo = combo
        nsView.onCapture = onChange
    }
}

/// An `NSButton` that records the next valid key combination the user types.
final class ShortcutRecorderButton: NSButton {
    /// The combo displayed on the button.
    var combo: KeyCombo = .defaultToggle {
        didSet { refreshTitle() }
    }

    /// Invoked when a new valid combo is captured.
    var onCapture: ((KeyCombo) -> Void)?

    private var isRecording = false {
        didSet { refreshTitle() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(beginRecording)
        refreshTitle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var acceptsFirstResponder: Bool { true }

    @objc private func beginRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // Escape cancels recording without changing the combo.
        if event.keyCode == 53 {
            isRecording = false
            return
        }

        let candidate = KeyCombo(
            keyCode: UInt32(event.keyCode),
            modifiers: KeyModifiers(event: event)
        )
        if candidate.isValid {
            combo = candidate
            onCapture?(candidate)
            isRecording = false
        }
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    private func refreshTitle() {
        title = isRecording
            ? String(localized: "Type shortcut…", comment: "Placeholder while recording a shortcut")
            : combo.displayString
    }
}

extension KeyModifiers {
    /// Builds the modifier set from an AppKit event's modifier flags.
    init(event: NSEvent) {
        var modifiers: KeyModifiers = []
        let flags = event.modifierFlags
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        self = modifiers
    }
}
