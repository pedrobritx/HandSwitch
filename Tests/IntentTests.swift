//
//  IntentTests.swift
//  HandSwitchTests
//
//  Verifies the Shortcuts-facing enum bridges losslessly to the domain model.
//  (The intents themselves route through the live app process, so their end to
//  end behavior is exercised via the controller tests.)
//

import Testing
@testable import HandSwitch

@Suite("App Intents bridging")
struct IntentTests {
    @Test("HandednessAppEnum bridges to and from Handedness")
    func bridging() {
        #expect(HandednessAppEnum(.left) == .left)
        #expect(HandednessAppEnum(.right) == .right)
        #expect(HandednessAppEnum.left.handedness == .left)
        #expect(HandednessAppEnum.right.handedness == .right)
    }

    @Test("round-trips through the app enum for every mode")
    func roundTrip() {
        for mode in Handedness.allCases {
            #expect(HandednessAppEnum(mode).handedness == mode)
        }
    }
}
