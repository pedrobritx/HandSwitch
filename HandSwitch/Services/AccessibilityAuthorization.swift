//
//  AccessibilityAuthorization.swift
//  HandSwitch
//
//  Wraps the Accessibility (AX) trust check used by the instant, event-tap
//  apply mode.
//

import ApplicationServices
import Foundation
import Observation

/// Reports and requests the Accessibility permission that the instant
/// (event-tap) mode requires.
@MainActor
protocol AccessibilityAuthorizing: AnyObject {
    /// Whether this process is currently trusted for Accessibility.
    var isTrusted: Bool { get }
    /// Prompts the user, presenting the system permission dialog once.
    func promptForAccess()
    /// Re-reads the current trust state.
    func refresh()
    /// Opens the Accessibility pane in System Settings.
    func openSettings()
}

/// Concrete `AccessibilityAuthorizing` backed by the `AXIsProcessTrusted` APIs.
///
/// The class also offers lightweight polling so the UI updates the moment the
/// user grants permission in System Settings — the system provides no callback
/// for that transition.
@MainActor
@Observable
final class AccessibilityAuthorization: AccessibilityAuthorizing {
    /// Whether this process is trusted for Accessibility right now.
    private(set) var isTrusted: Bool

    @ObservationIgnored private var monitorTask: Task<Void, Never>?

    init() {
        isTrusted = AXIsProcessTrusted()
    }

    func promptForAccess() {
        // The literal key is the stable string value of `kAXTrustedCheckOptionPrompt`;
        // using it avoids the constant's Unmanaged<CFString>/CFString import ambiguity.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        isTrusted = AXIsProcessTrustedWithOptions(options)
        beginMonitoring()
    }

    func refresh() {
        let trusted = AXIsProcessTrusted()
        if trusted != isTrusted { isTrusted = trusted }
    }

    func openSettings() {
        SystemSettingsOpener.openAccessibility()
        beginMonitoring()
    }

    /// Polls the trust state once per second until it becomes granted, so the
    /// UI reflects a grant made in System Settings without requiring a relaunch.
    func beginMonitoring() {
        guard monitorTask == nil else { return }
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                let trusted = AXIsProcessTrusted()
                if trusted != self.isTrusted { self.isTrusted = trusted }
                if trusted {
                    self.stopMonitoring()
                    return
                }
            }
        }
    }

    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
    }
}
