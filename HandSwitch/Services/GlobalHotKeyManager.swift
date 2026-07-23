//
//  GlobalHotKeyManager.swift
//  HandSwitch
//
//  A thin, native wrapper around Carbon's RegisterEventHotKey — the supported
//  API for system-wide keyboard shortcuts (SwiftUI exposes no public equivalent).
//

import Carbon.HIToolbox
import Foundation

/// The C event handler Carbon calls when the registered hotkey is pressed.
private func handSwitchHotKeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    // Carbon dispatches application hotkey events on the main thread.
    MainActor.assumeIsolated {
        manager.handleHotKeyPressed()
    }
    return noErr
}

/// Registers a single global keyboard shortcut and invokes a handler when it
/// fires. Re-registering replaces the previous binding; the app unregisters on
/// quit.
@MainActor
final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handler: (@MainActor () -> Void)?

    /// Four-char signature 'HSwt' identifying this app's hotkey.
    private let signature: OSType = 0x4853_7774
    private let hotKeyIdentifier: UInt32 = 1

    /// Registers `combo` as the global shortcut, replacing any existing binding.
    /// - Parameters:
    ///   - combo: The key combination to register.
    ///   - action: Invoked on the main thread each time the shortcut fires.
    func register(_ combo: KeyCombo, action: @escaping @MainActor () -> Void) {
        unregister()

        guard combo.isValid else {
            Log.hotkey.error("Refusing to register invalid combo \(combo.displayString, privacy: .public)")
            return
        }

        handler = action
        installEventHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: signature, id: hotKeyIdentifier)
        var reference: EventHotKeyRef?
        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &reference
        )

        if status == noErr {
            hotKeyRef = reference
            Log.hotkey.info("Registered global shortcut \(combo.displayString, privacy: .public)")
        } else {
            Log.hotkey.error("RegisterEventHotKey failed with status \(status)")
        }
    }

    /// Removes the current global shortcut and its event handler.
    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        handler = nil
    }

    /// Invoked by the C handler on the main thread.
    fileprivate func handleHotKeyPressed() {
        handler?()
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            handSwitchHotKeyHandler,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )
    }
}
