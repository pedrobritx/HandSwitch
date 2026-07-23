//
//  Handedness.swift
//  HandSwitch
//
//  The core domain model: the two mouse-handedness modes the app toggles between.
//

import Foundation

/// The two mouse-handedness modes HandSwitch can switch between.
///
/// `right` is the macOS default, where the primary (main) click is the left
/// physical button. `left` swaps the primary and secondary buttons so the
/// right physical button becomes the primary click — the ergonomic setup many
/// left-handed users and people recovering from an injury prefer.
///
/// The mode maps one-to-one onto the macOS global preference
/// `com.apple.mouse.swapLeftRightButtons`: `left` corresponds to `true`
/// (buttons swapped) and `right` to `false`.
enum Handedness: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Right-handed mode — the macOS default; primary click on the left button.
    case right
    /// Left-handed mode — primary and secondary buttons swapped.
    case left

    var id: String { rawValue }

    /// The opposite mode. Used by the one-tap toggle action.
    var opposite: Handedness {
        switch self {
        case .right: .left
        case .left: .right
        }
    }

    /// Whether the primary and secondary mouse buttons are swapped in this mode.
    ///
    /// Maps directly to `com.apple.mouse.swapLeftRightButtons`:
    /// `true` for left-handed, `false` for right-handed.
    var swapsButtons: Bool { self == .left }

    /// Builds a mode from the raw swap flag stored in the system preference.
    init(buttonsSwapped: Bool) {
        self = buttonsSwapped ? .left : .right
    }

    /// A short, localized display name, e.g. "Right-handed".
    var displayName: String {
        switch self {
        case .right: String(localized: "Right-handed", comment: "Name of the right-handed mouse mode")
        case .left: String(localized: "Left-handed", comment: "Name of the left-handed mouse mode")
        }
    }

    /// The single-letter badge drawn in the menu-bar icon ("R" or "L").
    var badge: String {
        switch self {
        case .right: String(localized: "R", comment: "Single-letter badge for right-handed mode")
        case .left: String(localized: "L", comment: "Single-letter badge for left-handed mode")
        }
    }

    /// A localized sentence announced (as a notification and to VoiceOver) when
    /// this mode becomes active.
    var activationMessage: String {
        switch self {
        case .right: String(localized: "Right-handed mode enabled", comment: "Notification shown when right-handed mode is turned on")
        case .left: String(localized: "Left-handed mode enabled", comment: "Notification shown when left-handed mode is turned on")
        }
    }

    /// The SF Symbol used to represent the mode in settings and the About window.
    static let symbolName = "computermouse.fill"
}
