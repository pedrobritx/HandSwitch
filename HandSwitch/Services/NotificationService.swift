//
//  NotificationService.swift
//  HandSwitch
//
//  Posts a native macOS notification whenever the handedness changes.
//

import Foundation
import UserNotifications

/// Announces handedness changes to the user.
@MainActor
protocol HandednessAnnouncing: AnyObject {
    /// Requests notification authorization if it has not yet been determined.
    func requestAuthorizationIfNeeded() async
    /// Posts a notification describing the newly active mode.
    func announce(_ handedness: Handedness)
}

/// Concrete `HandednessAnnouncing` built on `UNUserNotificationCenter`.
@MainActor
final class NotificationService: HandednessAnnouncing {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async {
        // `requestAuthorization` is idempotent: after the first determination it
        // returns the existing decision without prompting again, so it is safe
        // to call on every launch (and avoids passing non-Sendable settings
        // across the actor boundary).
        do {
            _ = try await center.requestAuthorization(options: [.alert])
        } catch {
            Log.lifecycle.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func announce(_ handedness: Handedness) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "HandSwitch", comment: "App name used as the notification title")
        content.body = handedness.activationMessage
        content.interruptionLevel = .active

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request) { error in
            if let error {
                Log.lifecycle.error("Failed to post notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
