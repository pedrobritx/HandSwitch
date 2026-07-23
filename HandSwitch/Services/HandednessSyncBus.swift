//
//  HandednessSyncBus.swift
//  HandSwitch
//
//  A tiny cross-process broadcast used to keep the running app, App-Intent
//  processes, and Shortcuts in sync about the current handedness.
//

import Foundation

/// Broadcasts and observes handedness changes across processes using
/// `DistributedNotificationCenter`.
///
/// Because App Intents and Shortcuts may run in a separate instance of the
/// app, the process that makes a change posts here so the running menu-bar app
/// can update its icon, reconcile the event tap, and post the user
/// notification. The value travels in the notification's `object` (a string),
/// which is delivered reliably across processes.
enum HandednessSyncBus {
    /// The distributed notification name.
    static let notificationName = Notification.Name("com.handswitch.HandSwitch.handednessDidChange")

    /// Posts a handedness change to every listening process.
    static func post(_ handedness: Handedness) {
        DistributedNotificationCenter.default().postNotificationName(
            notificationName,
            object: handedness.rawValue,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    /// Observes handedness changes from other processes.
    ///
    /// The handler may be invoked on an arbitrary thread; callers that need
    /// main-actor work should hop themselves.
    /// - Returns: An opaque token; remove it with
    ///   `DistributedNotificationCenter.default().removeObserver(_:)`.
    static func observe(_ handler: @escaping @Sendable (Handedness) -> Void) -> NSObjectProtocol {
        DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: nil
        ) { notification in
            guard let raw = notification.object as? String,
                  let handedness = Handedness(rawValue: raw) else {
                return
            }
            handler(handedness)
        }
    }
}
