//
//  Mocks.swift
//  HandSwitchTests
//
//  In-memory test doubles for the controller's dependencies.
//

import Foundation
@testable import HandSwitch

/// A configurable in-memory mechanism that records what it was asked to do.
@MainActor
final class MockMechanism: HandednessMechanism {
    var capabilityValue: MechanismCapability = .available
    var currentValue: Handedness = .right
    var errorToThrow: HandednessError?

    private(set) var applied: [Handedness] = []
    private(set) var deactivateCount = 0

    var capability: MechanismCapability { capabilityValue }

    func currentHandedness() -> Handedness { currentValue }

    func apply(_ handedness: Handedness) throws {
        if let errorToThrow {
            throw errorToThrow
        }
        applied.append(handedness)
        currentValue = handedness
    }

    func deactivate() {
        deactivateCount += 1
    }
}

/// Records announced modes without posting real notifications.
@MainActor
final class MockAnnouncer: HandednessAnnouncing {
    private(set) var announced: [Handedness] = []

    func requestAuthorizationIfNeeded() async {}

    func announce(_ handedness: Handedness) {
        announced.append(handedness)
    }
}

@MainActor
enum TestFactory {
    static func makeDefaults() -> UserDefaults {
        let suite = "com.handswitch.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
