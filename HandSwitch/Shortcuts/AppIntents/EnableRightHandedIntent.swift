//
//  EnableRightHandedIntent.swift
//  HandSwitch
//

import AppIntents

/// Turns on right-handed mouse mode (the macOS default).
struct EnableRightHandedIntent: AppIntent {
    static var title: LocalizedStringResource = "Enable Right-Handed Mode"
    static var description = IntentDescription(
        "Makes the left mouse button the primary click."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<HandednessAppEnum> & ProvidesDialog {
        let mode = HandednessCoordinator.set(.right)
        return .result(
            value: HandednessAppEnum(mode),
            dialog: IntentDialog(stringLiteral: mode.activationMessage)
        )
    }
}
