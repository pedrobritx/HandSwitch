//
//  HandednessCoordinator.swift
//  HandSwitch
//
//  A thin facade the App Intents call. For an always-running menu-bar app the
//  system routes intents into the live process, so this delegates to the shared
//  controller — keeping every side effect (tap reconciliation, notification,
//  cross-process sync) in one place.
//

import Foundation

/// Entry point used by App Intents to read and change the handedness.
@MainActor
enum HandednessCoordinator {
    /// Toggles the mode and returns the new value.
    @discardableResult
    static func toggle() -> Handedness {
        let controller = AppEnvironment.shared.controller
        controller.toggle()
        return controller.current
    }

    /// Sets a specific mode and returns the resulting value.
    @discardableResult
    static func set(_ handedness: Handedness) -> Handedness {
        let controller = AppEnvironment.shared.controller
        controller.set(handedness)
        return controller.current
    }

    /// The current mode.
    static func currentMode() -> Handedness {
        AppEnvironment.shared.controller.current
    }
}
