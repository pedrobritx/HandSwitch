//
//  HandednessController.swift
//  HandSwitch
//
//  The central business logic that coordinates mechanisms, persistence,
//  notifications, and cross-process sync. This is the single place that
//  applies a handedness change.
//

import Foundation
import Observation

/// Orchestrates reading and applying the mouse handedness.
///
/// It owns the two mechanisms (system preference and instant event tap),
/// enforces that only one is active at a time, keeps persisted state and the
/// UI in sync, posts notifications, and reflects changes made by other
/// processes (App Intents / Shortcuts). It is the *only* type that runs a
/// mechanism, which keeps side effects centralized and avoids double-swaps.
@MainActor
@Observable
final class HandednessController {
    /// The currently active mode, as reflected to the UI.
    private(set) var current: Handedness

    /// The most recent error, or `nil` if the last operation succeeded.
    private(set) var lastError: HandednessError?

    /// Whether a change is in flight (guards against reentrancy).
    private(set) var isBusy = false

    /// Invoked after `current` changes, so imperative UI (the menu-bar icon)
    /// can redraw. SwiftUI views observe `current` directly instead.
    @ObservationIgnored var onChange: (@MainActor () -> Void)?

    @ObservationIgnored private let systemMechanism: any HandednessMechanism
    @ObservationIgnored private let instantMechanism: any HandednessMechanism
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let announcer: any HandednessAnnouncing
    @ObservationIgnored private var syncToken: NSObjectProtocol?

    /// The active apply strategy (read-through to settings).
    var applyStrategy: ApplyStrategy { settings.applyStrategy }

    init(
        systemMechanism: any HandednessMechanism,
        instantMechanism: any HandednessMechanism,
        settings: SettingsStore,
        announcer: any HandednessAnnouncing
    ) {
        self.systemMechanism = systemMechanism
        self.instantMechanism = instantMechanism
        self.settings = settings
        self.announcer = announcer

        // Seed from the persisted cache for an instant UI, then reconcile with
        // the live system truth when the system-setting strategy is in use.
        var seed = settings.lastHandedness
        if settings.applyStrategy == .systemSetting {
            seed = systemMechanism.currentHandedness()
        }
        current = seed
        settings.lastHandedness = seed
    }

    // MARK: - Public actions

    /// Establishes the persisted mode using the active strategy. Call once at
    /// launch: it starts the event tap in instant mode, or confirms the system
    /// preference in system-setting mode.
    func activate() {
        apply(current, announce: false)
        startObservingRemoteChanges()
    }

    /// Switches to the opposite mode.
    func toggle() {
        apply(current.opposite, announce: true)
    }

    /// Sets a specific mode.
    func set(_ handedness: Handedness) {
        apply(handedness, announce: true)
    }

    /// Changes how handedness is applied and reconciles the mechanisms so the
    /// current mode is preserved under the new strategy.
    func setApplyStrategy(_ strategy: ApplyStrategy) {
        guard strategy != settings.applyStrategy else { return }
        settings.applyStrategy = strategy
        apply(current, announce: false)
    }

    /// Opens the most relevant System Settings pane for the current error.
    func openRelevantSystemSettings() {
        if lastError?.suggestsOpeningSystemSettings == true {
            SystemSettingsOpener.openMouseSettings()
        } else {
            SystemSettingsOpener.openAccessibility()
        }
    }

    /// Clears any surfaced error (e.g. after the user resolves it).
    func clearError() {
        lastError = nil
    }

    /// Stops the event tap and removes observers. Call on termination.
    func shutdown() {
        instantMechanism.deactivate()
        if let syncToken {
            DistributedNotificationCenter.default().removeObserver(syncToken)
            self.syncToken = nil
        }
    }

    // MARK: - Core

    private func apply(_ target: Handedness, announce: Bool) {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        lastError = nil

        do {
            switch settings.applyStrategy {
            case .systemSetting:
                // No live tap in this mode; make sure it isn't running.
                instantMechanism.deactivate()
                try systemMechanism.apply(target)
            case .instant:
                try applyInstant(target)
            }

            updateCurrent(target)
            HandednessSyncBus.post(target)
            if announce && settings.notificationsEnabled {
                announcer.announce(target)
            }
        } catch let error as HandednessError {
            lastError = error
            Log.handedness.error("Apply \(target.rawValue, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        } catch {
            lastError = .preferenceWriteFailed
            Log.handedness.error("Apply \(target.rawValue, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Applies `target` using the event tap, keeping the OS swap neutral so the
    /// two never double-swap. If the tap can't start (e.g. no Accessibility
    /// permission), the OS preference is restored so the actual state stays
    /// consistent with the UI, and the error is rethrown.
    private func applyInstant(_ target: Handedness) throws {
        let previousSystem = systemMechanism.currentHandedness()
        if previousSystem != .right {
            try? systemMechanism.apply(.right)
        }
        do {
            try instantMechanism.apply(target)
        } catch {
            if previousSystem != .right {
                try? systemMechanism.apply(previousSystem)
            }
            throw error
        }
    }

    private func updateCurrent(_ handedness: Handedness) {
        current = handedness
        settings.lastHandedness = handedness
        onChange?()
    }

    // MARK: - Cross-process sync

    private func startObservingRemoteChanges() {
        guard syncToken == nil else { return }
        syncToken = HandednessSyncBus.observe { [weak self] handedness in
            Task { @MainActor in
                self?.handleRemoteChange(handedness)
            }
        }
    }

    private func handleRemoteChange(_ handedness: Handedness) {
        guard handedness != current else { return }
        Log.handedness.info("Reflecting remote change to \(handedness.rawValue, privacy: .public)")
        // In instant mode, our tap must follow the externally reported mode.
        if settings.applyStrategy == .instant {
            try? instantMechanism.apply(handedness)
        }
        updateCurrent(handedness)
    }
}
