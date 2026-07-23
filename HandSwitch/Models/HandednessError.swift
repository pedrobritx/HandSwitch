//
//  HandednessError.swift
//  HandSwitch
//
//  Typed, user-presentable errors for reading and applying handedness.
//

import Foundation

/// Errors that can occur while reading or applying a handedness change.
///
/// Every case carries enough context for the UI to explain the problem in
/// plain language and, where relevant, offer a concrete recovery action — the
/// app should *never* fail silently or leave the UI inconsistent.
enum HandednessError: LocalizedError, Equatable {
    /// The running macOS version does not expose a supported way to change the
    /// primary mouse button.
    case unsupportedOS(version: String)

    /// The instant (event-tap) strategy needs Accessibility permission, which
    /// has not been granted.
    case accessibilityPermissionDenied

    /// Writing the system preference failed outright.
    case preferenceWriteFailed

    /// The preference was written but a verifying read-back showed the value
    /// did not change — the OS refused or ignored the write.
    case verificationFailed

    /// The `CGEventTap` could not be created (for example, permission was
    /// revoked while the app was running).
    case eventTapCreationFailed

    var errorDescription: String? {
        switch self {
        case let .unsupportedOS(version):
            String(
                localized: "HandSwitch can’t change the mouse mode on macOS \(version).",
                comment: "Error when the OS version is unsupported"
            )
        case .accessibilityPermissionDenied:
            String(
                localized: "HandSwitch needs Accessibility permission to switch instantly.",
                comment: "Error when Accessibility permission is missing"
            )
        case .preferenceWriteFailed:
            String(
                localized: "HandSwitch couldn’t update the mouse setting.",
                comment: "Error when writing the preference fails"
            )
        case .verificationFailed:
            String(
                localized: "The mouse setting didn’t change as expected.",
                comment: "Error when the preference write can’t be verified"
            )
        case .eventTapCreationFailed:
            String(
                localized: "HandSwitch couldn’t start instant switching.",
                comment: "Error when the event tap can’t be created"
            )
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unsupportedOS:
            String(
                localized: "You can still change it manually in System Settings › Mouse.",
                comment: "Recovery suggestion for unsupported OS"
            )
        case .accessibilityPermissionDenied, .eventTapCreationFailed:
            String(
                localized: "Grant permission in System Settings › Privacy & Security › Accessibility, or switch to the System setting mode.",
                comment: "Recovery suggestion for missing Accessibility permission"
            )
        case .preferenceWriteFailed, .verificationFailed:
            String(
                localized: "Open System Settings › Mouse to change the primary button directly.",
                comment: "Recovery suggestion when writing the preference fails"
            )
        }
    }

    /// Whether the UI should surface an "Open System Settings" affordance for
    /// this error.
    var suggestsOpeningSystemSettings: Bool {
        switch self {
        case .unsupportedOS, .preferenceWriteFailed, .verificationFailed: true
        case .accessibilityPermissionDenied, .eventTapCreationFailed: false
        }
    }
}
