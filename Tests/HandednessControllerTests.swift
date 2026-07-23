//
//  HandednessControllerTests.swift
//  HandSwitchTests
//

import Foundation
import Testing
@testable import HandSwitch

@MainActor
@Suite("HandednessController")
struct HandednessControllerTests {
    private struct Harness {
        let system = MockMechanism()
        let instant = MockMechanism()
        let announcer = MockAnnouncer()
        let settings: SettingsStore
        let controller: HandednessController

        init(strategy: ApplyStrategy = .systemSetting, systemCurrent: Handedness = .right) {
            settings = SettingsStore(defaults: TestFactory.makeDefaults())
            settings.applyStrategy = strategy
            system.currentValue = systemCurrent
            controller = HandednessController(
                systemMechanism: system,
                instantMechanism: instant,
                settings: settings,
                announcer: announcer
            )
        }
    }

    @Test("toggle switches to the opposite mode via the system mechanism")
    func toggle() {
        let harness = Harness(systemCurrent: .right)
        #expect(harness.controller.current == .right)

        harness.controller.toggle()

        #expect(harness.controller.current == .left)
        #expect(harness.system.applied.last == .left)
        #expect(harness.announcer.announced == [.left])
        #expect(harness.controller.lastError == nil)
    }

    @Test("system mode keeps the event tap deactivated")
    func systemModeDeactivatesTap() {
        let harness = Harness()
        harness.controller.set(.left)
        #expect(harness.instant.deactivateCount >= 1)
        #expect(harness.instant.applied.isEmpty)
    }

    @Test("a verification failure surfaces an error and preserves state")
    func verificationFailure() {
        let harness = Harness(systemCurrent: .right)
        harness.system.errorToThrow = .verificationFailed

        harness.controller.set(.left)

        #expect(harness.controller.current == .right)
        #expect(harness.controller.lastError == .verificationFailed)
        #expect(harness.announcer.announced.isEmpty)
    }

    @Test("instant mode neutralizes the system preference then enforces via the tap")
    func instantModeNeutralizes() {
        let harness = Harness(strategy: .instant, systemCurrent: .left)

        harness.controller.set(.left)

        // The tap enforces left; the system preference is pushed to right.
        #expect(harness.instant.applied.last == .left)
        #expect(harness.system.applied.contains(.right))
        #expect(harness.controller.current == .left)
    }

    @Test("instant mode rolls back the system preference if the tap fails")
    func instantModeRollback() {
        let harness = Harness(strategy: .instant, systemCurrent: .left)
        harness.instant.errorToThrow = .accessibilityPermissionDenied

        harness.controller.set(.left)

        #expect(harness.controller.lastError == .accessibilityPermissionDenied)
        // The system preference was neutralized then restored to its prior value.
        #expect(harness.system.currentValue == .left)
    }

    @Test("changing strategy reapplies the current mode without announcing")
    func strategyChangeIsSilent() {
        let harness = Harness(systemCurrent: .right)
        harness.controller.toggle() // now left, announced once
        let announcedCount = harness.announcer.announced.count

        harness.controller.setApplyStrategy(.instant)

        #expect(harness.settings.applyStrategy == .instant)
        #expect(harness.controller.current == .left)
        // No new announcement for a strategy change.
        #expect(harness.announcer.announced.count == announcedCount)
    }
}
