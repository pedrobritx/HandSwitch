//
//  EnableLeftHandedIntent.swift
//  HandSwitch
//

import AppIntents

/// Turns on left-handed mouse mode.
struct EnableLeftHandedIntent: AppIntent {
    static var title: LocalizedStringResource = "Enable Left-Handed Mode"
    static var description = IntentDescription(
        "Makes the right mouse button the primary click."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<HandednessAppEnum> & ProvidesDialog {
        let mode = HandednessCoordinator.set(.left)
        return .result(
            value: HandednessAppEnum(mode),
            dialog: IntentDialog(stringLiteral: mode.activationMessage)
        )
    }
}
