//
//  GetCurrentModeIntent.swift
//  HandSwitch
//

import AppIntents

/// Reports the current mouse mode without changing it.
struct GetCurrentModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Current Mode"
    static var description = IntentDescription(
        "Returns whether the mouse is in right-handed or left-handed mode."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<HandednessAppEnum> & ProvidesDialog {
        let mode = HandednessCoordinator.currentMode()
        let sentence = String(
            localized: "You’re using \(mode.displayName) mode.",
            comment: "Spoken/printed result of the Get Current Mode intent"
        )
        return .result(
            value: HandednessAppEnum(mode),
            dialog: IntentDialog(stringLiteral: sentence)
        )
    }
}
