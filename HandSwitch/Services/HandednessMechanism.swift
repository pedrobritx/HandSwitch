//
//  HandednessMechanism.swift
//  HandSwitch
//
//  The abstraction that decouples business logic from the concrete way a
//  handedness change is applied to the system.
//

import Foundation

/// The availability of a mechanism at a given moment.
enum MechanismCapability: Equatable {
    /// Ready to apply changes right now.
    case available
    /// Functional, but Accessibility permission must be granted first.
    case needsAccessibilityPermission
    /// Not usable on this system; carries the reason to surface to the user.
    case unsupported(reason: HandednessError)

    /// Whether `apply(_:)` can be expected to succeed right now.
    var isReady: Bool { self == .available }
}

/// A strategy for reading and applying the mouse handedness.
///
/// Concrete implementations wrap a specific system facility — the global
/// preference or a live event tap. Keeping this behind a protocol lets the
/// controller swap strategies, degrade gracefully, and be unit-tested with
/// in-memory doubles.
@MainActor
protocol HandednessMechanism {
    /// The current availability of this mechanism.
    var capability: MechanismCapability { get }

    /// The handedness the system currently reflects through this mechanism.
    func currentHandedness() -> Handedness

    /// Applies the requested handedness.
    /// - Throws: A ``HandednessError`` describing why the change could not be made.
    func apply(_ handedness: Handedness) throws

    /// Stops any live enforcement. A no-op for stateless mechanisms.
    func deactivate()
}

extension HandednessMechanism {
    func deactivate() {}
}
