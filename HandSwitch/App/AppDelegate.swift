//
//  AppDelegate.swift
//  HandSwitch
//
//  Configures the app as a menu-bar accessory and owns the status item.
//

import AppKit

/// The application delegate: sets the accessory activation policy, starts the
/// object graph, and creates the menu-bar status item.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let environment = AppEnvironment.shared
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar utility: no Dock icon, no main window.
        NSApp.setActivationPolicy(.accessory)

        environment.start()

        statusItemController = StatusItemController(
            controller: environment.controller,
            launchAtLogin: environment.launchAtLogin,
            settings: environment.settings,
            onOpenSettings: { SettingsWindowOpener.open() },
            onOpenAbout: { AboutWindowController.shared.show() }
        )

        Log.lifecycle.info("HandSwitch launched in accessory mode")
    }

    func applicationWillTerminate(_ notification: Notification) {
        environment.stop()
    }
}
