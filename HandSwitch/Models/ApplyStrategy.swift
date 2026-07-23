//
//  ApplyStrategy.swift
//  HandSwitch
//
//  How a handedness change is applied to the system.
//

import Foundation

/// The mechanism HandSwitch uses to apply a handedness change.
///
/// The two strategies are mutually exclusive by design — running both at once
/// would swap the buttons twice and cancel out. ``HandednessController``
/// guarantees only one is active at a time.
enum ApplyStrategy: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Write the real macOS system preference
    /// (`com.apple.mouse.swapLeftRightButtons`). Requires no special
    /// permission and persists system-wide across reboots. This is the
    /// canonical mechanism and the default.
    case systemSetting

    /// Swap the primary and secondary buttons live with a `CGEventTap` while
    /// HandSwitch is running. Requires Accessibility permission but applies
    /// instantly and reliably on every macOS version.
    case instant

    var id: String { rawValue }

    /// A short, localized name for use in Settings.
    var displayName: String {
        switch self {
        case .systemSetting: String(localized: "System setting", comment: "Name of the system-preference apply strategy")
        case .instant: String(localized: "Instant", comment: "Name of the instant event-tap apply strategy")
        }
    }

    /// A one-line, localized explanation of the trade-off, shown under the picker.
    var explanation: String {
        switch self {
        case .systemSetting:
            String(
                localized: "Flips the real macOS “Primary mouse button” setting. No extra permission needed.",
                comment: "Explanation of the system-setting apply strategy"
            )
        case .instant:
            String(
                localized: "Switches instantly while HandSwitch runs. Requires Accessibility permission.",
                comment: "Explanation of the instant apply strategy"
            )
        }
    }

    /// Whether this strategy requires Accessibility permission to function.
    var requiresAccessibility: Bool { self == .instant }
}
