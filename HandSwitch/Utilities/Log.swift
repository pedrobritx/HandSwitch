//
//  Log.swift
//  HandSwitch
//
//  Centralized, privacy-preserving logging built on the unified logging system.
//

import Foundation
import os

/// Namespaced `Logger` instances for HandSwitch.
///
/// Using a single subsystem with per-area categories keeps Console.app filtered
/// output tidy and makes it easy to enable debugging for one subsystem at a time.
enum Log {
    private static let subsystem = "com.handswitch.HandSwitch"

    /// Reading and applying handedness changes.
    static let handedness = Logger(subsystem: subsystem, category: "handedness")
    /// The instant-mode `CGEventTap`.
    static let eventTap = Logger(subsystem: subsystem, category: "eventTap")
    /// App Intents / Shortcuts execution.
    static let intents = Logger(subsystem: subsystem, category: "intents")
    /// The global keyboard shortcut.
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
    /// App lifecycle and the menu-bar status item.
    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    /// Persistence and settings.
    static let settings = Logger(subsystem: subsystem, category: "settings")
}
