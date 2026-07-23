//
//  HandednessTests.swift
//  HandSwitchTests
//

import Testing
@testable import HandSwitch

@Suite("Handedness model")
struct HandednessTests {
    @Test("opposite flips the mode")
    func opposite() {
        #expect(Handedness.right.opposite == .left)
        #expect(Handedness.left.opposite == .right)
    }

    @Test("swapsButtons maps to the system preference semantics")
    func swapsButtons() {
        #expect(Handedness.right.swapsButtons == false)
        #expect(Handedness.left.swapsButtons == true)
    }

    @Test("init(buttonsSwapped:) round-trips with swapsButtons")
    func buttonsSwappedInit() {
        #expect(Handedness(buttonsSwapped: true) == .left)
        #expect(Handedness(buttonsSwapped: false) == .right)
        for mode in Handedness.allCases {
            #expect(Handedness(buttonsSwapped: mode.swapsButtons) == mode)
        }
    }

    @Test("badge is a single letter per mode")
    func badge() {
        #expect(Handedness.right.badge == "R")
        #expect(Handedness.left.badge == "L")
    }

    @Test("display name and activation message are non-empty")
    func localizedText() {
        for mode in Handedness.allCases {
            #expect(!mode.displayName.isEmpty)
            #expect(!mode.activationMessage.isEmpty)
        }
    }
}
