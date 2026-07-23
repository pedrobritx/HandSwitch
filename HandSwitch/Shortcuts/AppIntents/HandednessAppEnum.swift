//
//  HandednessAppEnum.swift
//  HandSwitch
//
//  Exposes the Handedness model to the App Intents / Shortcuts type system.
//

import AppIntents

/// The Shortcuts-facing representation of ``Handedness``.
enum HandednessAppEnum: String, AppEnum {
    case right
    case left

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Mouse Mode")
    }

    static var caseDisplayRepresentations: [HandednessAppEnum: DisplayRepresentation] {
        [
            .right: DisplayRepresentation(title: "Right-handed"),
            .left: DisplayRepresentation(title: "Left-handed")
        ]
    }

    /// Bridges from the domain model.
    init(_ handedness: Handedness) {
        self = handedness == .left ? .left : .right
    }

    /// Bridges back to the domain model.
    var handedness: Handedness {
        self == .left ? .left : .right
    }
}
