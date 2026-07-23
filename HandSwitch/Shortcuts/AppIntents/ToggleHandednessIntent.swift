//
//  ToggleHandednessIntent.swift
//  HandSwitch
//

import AppIntents

/// Switches the mouse between right-handed and left-handed mode.
struct ToggleHandednessIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle HandSwitch"
    static var description = IntentDescription(
        "Switches the mouse between right-handed and left-handed mode."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<HandednessAppEnum> & ProvidesDialog {
        let mode = HandednessCoordinator.toggle()
        return .result(
            value: HandednessAppEnum(mode),
            dialog: IntentDialog(stringLiteral: mode.activationMessage)
        )
    }
}
