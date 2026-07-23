//
//  SystemPreferenceMechanism.swift
//  HandSwitch
//
//  The canonical mechanism: writes the real macOS "Primary mouse button"
//  preference, exactly as System Settings does.
//

import Foundation

/// Applies handedness by writing the global, per-host preference
/// `com.apple.mouse.swapLeftRightButtons` — the same value System Settings
/// writes for "Primary mouse button".
///
/// The change persists system-wide across reboots and needs no special
/// permission. Every write is verified with a read-back so the app can report
/// honestly if the system refuses the change.
@MainActor
final class SystemPreferenceMechanism: HandednessMechanism {
    var capability: MechanismCapability { .available }

    func currentHandedness() -> Handedness {
        // An unset key means the macOS default: right-handed.
        let swapped = GlobalHostPreference.bool(forKey: GlobalHostPreference.swapButtonsKey) ?? false
        return Handedness(buttonsSwapped: swapped)
    }

    func apply(_ handedness: Handedness) throws {
        let synchronized = GlobalHostPreference.setBool(
            handedness.swapsButtons,
            forKey: GlobalHostPreference.swapButtonsKey
        )
        guard synchronized else {
            Log.handedness.error("CFPreferences synchronize failed writing swapLeftRightButtons")
            throw HandednessError.preferenceWriteFailed
        }

        // Verify the write actually took effect — never fail silently.
        let readBack = GlobalHostPreference.bool(forKey: GlobalHostPreference.swapButtonsKey)
        guard readBack == handedness.swapsButtons else {
            Log.handedness.error("Verification failed: expected \(handedness.swapsButtons), read \(String(describing: readBack))")
            throw HandednessError.verificationFailed
        }
        Log.handedness.info("System preference set to \(handedness.rawValue, privacy: .public)")
    }
}
