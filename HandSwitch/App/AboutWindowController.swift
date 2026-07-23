//
//  AboutWindowController.swift
//  HandSwitch
//
//  Hosts the SwiftUI About view in a standalone AppKit window, opened from the
//  menu-bar menu.
//

import AppKit
import SwiftUI

/// Presents the About window on demand.
@MainActor
final class AboutWindowController {
    static let shared = AboutWindowController()

    private var window: NSWindow?

    private init() {}

    /// Shows (creating if needed) and focuses the About window.
    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: AboutView())
            let newWindow = NSWindow(contentViewController: hosting)
            newWindow.title = String(localized: "About HandSwitch", comment: "About window title")
            newWindow.styleMask = [.titled, .closable, .fullSizeContentView]
            newWindow.titlebarAppearsTransparent = true
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            window = newWindow
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
